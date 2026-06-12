package storage

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/storage/azblob"
	"github.com/davidh-machine-id/azure-exp/app/internal/config"
	"github.com/davidh-machine-id/azure-exp/app/pkg/authn"
)

// Service wraps the Azure Blob client and config.
type Service struct {
	client *azblob.Client
	Cfg    *config.Config
}

// BlobInfo holds metadata about a blob for API responses.
type BlobInfo struct {
	Name         string    `json:"name"`
	Size         int64     `json:"size"`
	LastModified time.Time `json:"lastModified"`
}

// New creates a Service, wiring up the SPIFFE SVID credential.
func New(cfg *config.Config) (*Service, error) {
	getSVIDAssertion := func(ctx context.Context) (string, error) {
		log.Println("[INFO] Fetching JWT SVID from workload API...")
		svid, err := authn.FetchJWTSVID(ctx, authn.AzureJWTAudience, fmt.Sprintf("unix://%s", cfg.SWAAgentSocketPath))
		if err != nil {
			return "", fmt.Errorf("failed to fetch SVID: %w", err)
		}
		log.Println("[INFO] Successfully fetched JWT SVID")
		svidString := svid.Marshal()
		jwtPretty, jwtPrettyErr := PrettyPrintJWT(svidString)
		if jwtPrettyErr != nil {
			log.Printf("[DEBUG] SVID error: %s\n[DEBUG] SVID raw: %s", jwtPrettyErr, svidString)
		} else {
			log.Printf("[DEBUG] SVID: %s", jwtPretty)
		}
		return svidString, nil
	}

	log.Printf("[DEBUG] TenantID: %s\n", cfg.AzureTenantID)
	log.Printf("[DEBUG] ClientID: %s\n", cfg.AzureClientID)
	log.Printf("[DEBUG] StorageAccount: %s\n", cfg.StorageAccount)

	log.Println("[INFO] Creating Azure client assertion credential with SPIFFE SVID...")
	credential, err := azidentity.NewClientAssertionCredential(cfg.AzureTenantID, cfg.AzureClientID, getSVIDAssertion, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create Azure credential: %w", err)
	}

	log.Printf("[INFO] Connecting to storage account: %s", cfg.StorageAccount)
	client, err := azblob.NewClient(
		fmt.Sprintf("https://%s.blob.core.windows.net/", cfg.StorageAccount),
		credential,
		nil,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create blob service client: %w", err)
	}
	log.Printf("[INFO] Connected to storage account: %s", cfg.StorageAccount)

	return &Service{client: client, Cfg: cfg}, nil
}

// ListBlobs lists all blobs in a container.
func (s *Service) ListBlobs(ctx context.Context, containerName string) error {
	pager := s.client.NewListBlobsFlatPager(containerName, nil)

	blobCount := 0
	for pager.More() {
		resp, err := pager.NextPage(ctx)
		if err != nil {
			return fmt.Errorf("failed to list blobs: %w", err)
		}
		for _, blob := range resp.Segment.BlobItems {
			blobCount++
			log.Printf("  - %s (size: %d bytes)", *blob.Name, *blob.Properties.ContentLength)
		}
	}

	if blobCount == 0 {
		log.Println("  (no blobs in container)")
	}
	return nil
}

// UploadBlob uploads data to a blob.
func (s *Service) UploadBlob(ctx context.Context, containerName, blobName string, data []byte) error {
	_, err := s.client.UploadBuffer(ctx, containerName, blobName, data, nil)
	if err != nil {
		return fmt.Errorf("failed to upload blob: %w", err)
	}
	log.Printf("✓ Uploaded blob '%s' (%d bytes)", blobName, len(data))
	return nil
}

// DownloadBlob downloads a blob and returns its contents.
func (s *Service) DownloadBlob(ctx context.Context, containerName, blobName string) ([]byte, error) {
	resp, err := s.client.DownloadStream(ctx, containerName, blobName, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to download blob: %w", err)
	}
	defer resp.Body.Close()

	buf := new(bytes.Buffer)
	if _, err = buf.ReadFrom(resp.Body); err != nil {
		return nil, fmt.Errorf("failed to read blob body: %w", err)
	}

	log.Printf("✓ Downloaded blob '%s'", blobName)
	log.Printf("  Content: %s", buf.String())
	return buf.Bytes(), nil
}

func PrettyString(str []byte) (string, error) {
	var prettyJSON bytes.Buffer
	if err := json.Indent(&prettyJSON, str, "", "  "); err != nil {
		return "", err
	}
	return prettyJSON.String(), nil
}

func PrettyPrintJWT(jwt string) (string, error) {
	prettyJWT := ""

	segments := strings.Split(jwt, ".")
	for i, segment := range segments {
		if i == 2 {
			break
		}

		bytes, err := base64.RawURLEncoding.DecodeString(segment)
		if err != nil {
			fmt.Printf("Error decoding string: %s ", err.Error())
			return "", fmt.Errorf("failed to decode string: %s", err.Error())
		}

		pretty, err := PrettyString(bytes)
		if err != nil {
			return "", err
		}
		prettyJWT = fmt.Sprintf("%s\n", pretty)
		if i == 0 {
			// give us a generic object to interact with
			decoded := make(map[string](interface{}))
			err = json.Unmarshal([]byte(bytes), &decoded)
			if err != nil {
				return "", err
			}
			// don't decode further if this is an encrypted JWT (JWE)
			if _, ok := decoded["enc"]; ok {
				break
			}
		}
	}
	return prettyJWT, nil
}

// ListBlobsResult lists all blobs in a container and returns structured metadata.
func (s *Service) ListBlobsResult(ctx context.Context, containerName string) ([]BlobInfo, error) {
	pager := s.client.NewListBlobsFlatPager(containerName, nil)
	var blobs []BlobInfo

	for pager.More() {
		resp, err := pager.NextPage(ctx)
		if err != nil {
			return nil, fmt.Errorf("failed to list blobs: %w", err)
		}
		for _, blob := range resp.Segment.BlobItems {
			blobs = append(blobs, BlobInfo{
				Name:         *blob.Name,
				Size:         *blob.Properties.ContentLength,
				LastModified: *blob.Properties.LastModified,
			})
		}
	}

	return blobs, nil
}

// GetBlobContent downloads a blob and returns its content as a string.
func (s *Service) GetBlobContent(ctx context.Context, containerName, blobName string) (string, error) {
	resp, err := s.client.DownloadStream(ctx, containerName, blobName, nil)
	if err != nil {
		return "", fmt.Errorf("failed to download blob: %w", err)
	}
	defer resp.Body.Close()

	buf := new(bytes.Buffer)
	if _, err = buf.ReadFrom(resp.Body); err != nil {
		return "", fmt.Errorf("failed to read blob body: %w", err)
	}

	return buf.String(), nil
}

// NewClientForID creates a new Azure Blob client using a provided JWT SVID and different clientID.
// Used to demonstrate authorization failures when a different SPIFFE identity tries to access resources.
func NewClientForID(ctx context.Context, cfg *config.Config, clientID string) (*azblob.Client, error) {
	getSVIDAssertion := func(ctxInner context.Context) (string, error) {
		log.Printf("[INFO] Fetching JWT SVID for client ID %s", clientID)
		svid, err := authn.FetchJWTSVID(ctxInner, authn.AzureJWTAudience, fmt.Sprintf("unix://%s", cfg.SWAAgentSocketPath))
		if err != nil {
			return "", fmt.Errorf("failed to fetch SVID: %w", err)
		}
		return svid.Marshal(), nil
	}

	log.Printf("[INFO] Creating Azure client assertion credential with SPIFFE SVID for client ID: %s", clientID)
	credential, err := azidentity.NewClientAssertionCredential(cfg.AzureTenantID, clientID, getSVIDAssertion, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create Azure credential: %w", err)
	}

	client, err := azblob.NewClient(
		fmt.Sprintf("https://%s.blob.core.windows.net/", cfg.StorageAccount),
		credential,
		nil,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create blob service client: %w", err)
	}

	return client, nil
}

// ListBlobsWithClient lists blobs using a provided client (used for testing rogue identity).
func ListBlobsWithClient(ctx context.Context, client *azblob.Client, containerName string) ([]BlobInfo, error) {
	pager := client.NewListBlobsFlatPager(containerName, nil)
	var blobs []BlobInfo

	for pager.More() {
		resp, err := pager.NextPage(ctx)
		if err != nil {
			// Check if this is an Azure auth error
			return nil, fmt.Errorf("failed to list blobs: %w", err)
		}
		for _, blob := range resp.Segment.BlobItems {
			blobs = append(blobs, BlobInfo{
				Name:         *blob.Name,
				Size:         *blob.Properties.ContentLength,
				LastModified: *blob.Properties.LastModified,
			})
		}
	}

	return blobs, nil
}

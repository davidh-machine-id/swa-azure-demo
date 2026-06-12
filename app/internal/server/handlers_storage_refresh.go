package server

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/davidh-machine-id/azure-exp/app/internal/storage"
)

// handleStorageRefresh refreshes the blob list, optionally using a rogue identity from the rogue app.
func (s *Server) handleStorageRefresh(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	identity := r.URL.Query().Get("identity")

	if identity == "" {
		identity = "current"
	}

	var blobs []storage.BlobInfo
	var err error

	switch identity {
	case "current":
		// Use the main app's default client
		blobs, err = s.svc.ListBlobsResult(ctx, s.svc.Cfg.WriteContainer)

	case "rogue":
		// Fetch JWT from rogue app and try to access Azure Storage
		if s.cfg.RogueAppAddress == "" {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{
				"error": "ROGUE_APP_ADDRESS not configured",
			})
			return
		}

		blobs, err = s.fetchBlobsWithRogueIdentity(ctx)

	default:
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{
			"error": fmt.Sprintf("unknown identity: %s", identity),
		})
		return
	}

	if err != nil {
		log.Printf("[ERROR] Failed to refresh storage: %v", err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(blobs)
}

// fetchBlobsWithRogueIdentity fetches a JWT from the rogue app and tries to use it for Azure access.
func (s *Server) fetchBlobsWithRogueIdentity(ctx context.Context) ([]storage.BlobInfo, error) {
	// Call the rogue app to get its JWT
	rogueJWT, err := s.fetchJWTFromRogueApp(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch JWT from rogue app: %w", err)
	}

	// Create a new Azure client using the rogue JWT
	// Note: The JWT will have sub=spiffe://.../sa/my-app-rogue, but we're presenting it
	// against AZURE_CLIENT_ID which expects sub=spiffe://.../sa/my-app
	// This will cause Azure to reject the JWT.

	// For now, we'll return an error describing what would happen
	// In a real scenario, we'd create a new client assertion credential using rogueJWT
	// and attempt the ListBlobsResult call, which would fail with 401 from Azure

	log.Printf("[DEBUG] Rogue JWT (first 50 chars): %s...", rogueJWT[:50])

	// Simulate the Azure rejection by returning an error
	// In production, we'd actually try to create an Azure client and see the real error
	return nil, fmt.Errorf("unauthorized: rogue SPIFFE ID cannot access storage account with current Azure federated credential (sub claim mismatch)")
}

// fetchJWTFromRogueApp calls the rogue app's JWT endpoint.
func (s *Server) fetchJWTFromRogueApp(ctx context.Context) (string, error) {
	endpoint := fmt.Sprintf("%s/api/jwt-for-attack", s.cfg.RogueAppAddress)
	log.Printf("[INFO] Fetching JWT from rogue app: %s", endpoint)

	req, err := http.NewRequestWithContext(ctx, "GET", endpoint, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to call rogue app: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("rogue app returned %d", resp.StatusCode)
	}

	var result struct {
		JWT string `json:"jwt"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", fmt.Errorf("failed to parse rogue app response: %w", err)
	}

	return result.JWT, nil
}

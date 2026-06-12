package authn

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/spiffe/go-spiffe/v2/svid/jwtsvid"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
)

// FetchJWTSVID fetches a JWT-SVID from the SPIFFE Workload API.
func FetchJWTSVID(ctx context.Context, audience, socketAddr string) (*jwtsvid.SVID, error) {
	ctxWithTimeout, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	workloadOptions := workloadapi.WithClientOptions(workloadapi.WithAddr(socketAddr))
	jwtSource, err := workloadapi.NewJWTSource(ctxWithTimeout, workloadOptions)
	if err != nil {
		return nil, fmt.Errorf("failed to create JWT source (socket: %s): %w", socketAddr, err)
	}
	defer jwtSource.Close()

	jwtParams := jwtsvid.Params{
		Audience: audience,
	}
	svid, err := jwtSource.FetchJWTSVID(ctxWithTimeout, jwtParams)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch JWT SVID (audience: %s): %w", audience, err)
	}

	return svid, nil
}

// SVIDInfo holds decoded JWT information for API responses.
type SVIDInfo struct {
	SpiffeID string                 `json:"spiffeId"`
	Header   map[string]interface{} `json:"header"`
	Payload  map[string]interface{} `json:"payload"`
	Raw      string                 `json:"raw"`
}

// FetchJWTSVIDInfo fetches a JWT-SVID and returns decoded header/payload info.
func FetchJWTSVIDInfo(ctx context.Context, audience, socketAddr string) (*SVIDInfo, error) {
	ctxWithTimeout, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	workloadOptions := workloadapi.WithClientOptions(workloadapi.WithAddr(socketAddr))
	jwtSource, err := workloadapi.NewJWTSource(ctxWithTimeout, workloadOptions)
	if err != nil {
		return nil, fmt.Errorf("failed to create JWT source (socket: %s): %w", socketAddr, err)
	}
	defer jwtSource.Close()

	jwtParams := jwtsvid.Params{
		Audience: audience,
	}
	svid, err := jwtSource.FetchJWTSVID(ctxWithTimeout, jwtParams)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch JWT SVID (audience: %s): %w", audience, err)
	}

	tokenStr := svid.Marshal()
	segments := strings.Split(tokenStr, ".")
	if len(segments) < 2 {
		return nil, fmt.Errorf("invalid JWT format")
	}

	// Decode header
	headerBytes, err := base64.RawURLEncoding.DecodeString(segments[0])
	if err != nil {
		return nil, fmt.Errorf("failed to decode JWT header: %w", err)
	}
	var header map[string]interface{}
	if err := json.Unmarshal(headerBytes, &header); err != nil {
		return nil, fmt.Errorf("failed to parse JWT header: %w", err)
	}

	// Decode payload
	payloadBytes, err := base64.RawURLEncoding.DecodeString(segments[1])
	if err != nil {
		return nil, fmt.Errorf("failed to decode JWT payload: %w", err)
	}
	var payload map[string]interface{}
	if err := json.Unmarshal(payloadBytes, &payload); err != nil {
		return nil, fmt.Errorf("failed to parse JWT payload: %w", err)
	}

	// Extract SPIFFE ID from sub claim
	spiffeID := ""
	if sub, ok := payload["sub"]; ok {
		spiffeID = sub.(string)
	}

	return &SVIDInfo{
		SpiffeID: spiffeID,
		Header:   header,
		Payload:  payload,
		Raw:      tokenStr,
	}, nil
}

// DecodeJWT decodes a raw JWT string into an SVIDInfo without fetching from the workload API.
func DecodeJWT(tokenStr string) (*SVIDInfo, error) {
	segments := strings.Split(tokenStr, ".")
	if len(segments) < 2 {
		return nil, fmt.Errorf("invalid JWT format")
	}

	headerBytes, err := base64.RawURLEncoding.DecodeString(segments[0])
	if err != nil {
		return nil, fmt.Errorf("failed to decode JWT header: %w", err)
	}
	var header map[string]interface{}
	if err := json.Unmarshal(headerBytes, &header); err != nil {
		return nil, fmt.Errorf("failed to parse JWT header: %w", err)
	}

	payloadBytes, err := base64.RawURLEncoding.DecodeString(segments[1])
	if err != nil {
		return nil, fmt.Errorf("failed to decode JWT payload: %w", err)
	}
	var payload map[string]interface{}
	if err := json.Unmarshal(payloadBytes, &payload); err != nil {
		return nil, fmt.Errorf("failed to parse JWT payload: %w", err)
	}

	spiffeID := ""
	if sub, ok := payload["sub"]; ok {
		spiffeID, _ = sub.(string)
	}

	return &SVIDInfo{
		SpiffeID: spiffeID,
		Header:   header,
		Payload:  payload,
		Raw:      tokenStr,
	}, nil
}

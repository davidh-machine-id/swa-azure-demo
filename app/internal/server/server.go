package server

import (
	"context"
	"embed"
	"encoding/json"
	"io/fs"
	"log"
	"net/http"

	"github.com/davidh-machine-id/azure-exp/app/internal/config"
	"github.com/davidh-machine-id/azure-exp/app/internal/storage"
)

// Server holds the HTTP server and its dependencies.
type Server struct {
	svc   *storage.Service
	cfg   *config.Config
	mux   *http.ServeMux
	webFS embed.FS
}

// New creates a Server wired to the given StorageService.
func New(svc *storage.Service) *Server {
	return NewWithConfig(svc, nil, embed.FS{})
}

// NewWithConfig creates a Server with full config and embedded web FS access.
func NewWithConfig(svc *storage.Service, cfg *config.Config, webFS embed.FS) *Server {
	s := &Server{svc: svc, cfg: cfg, mux: http.NewServeMux(), webFS: webFS}
	s.routes()
	return s
}

// ServeHTTP implements http.Handler.
func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	s.mux.ServeHTTP(w, r)
}

func (s *Server) routes() {
	// Serve embedded web UI
	webSubFS, err := fs.Sub(s.webFS, "web")
	if err == nil {
		s.mux.Handle("GET /", http.FileServer(http.FS(webSubFS)))
	} else {
		log.Printf("[WARN] Failed to serve web files: %v; falling back to healthz", err)
		s.mux.HandleFunc("GET /", s.handleHealthz)
	}

	s.mux.HandleFunc("GET /healthz", s.handleHealthz)

	// API routes
	s.mux.HandleFunc("GET /api/blobs", s.handleListBlobs)
	s.mux.HandleFunc("GET /api/blobs/{name}", s.handleGetBlob)
	s.mux.HandleFunc("POST /api/blobs", s.handleUploadBlob)
	s.mux.HandleFunc("GET /api/spiffe/ids", s.handleSPIFFEIDs)
	s.mux.HandleFunc("GET /api/spiffe/jwt", s.handleSPIFFEJWT)
	s.mux.HandleFunc("POST /api/storage/refresh", s.handleStorageRefresh)
}

func (s *Server) handleHealthz(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

// RunDemoOps executes the blob list/upload/download demonstration.
// Intended to be called in a goroutine after the HTTP server is started.
func (s *Server) RunDemoOps(ctx context.Context, writeContainer string) {
	log.Printf("[INFO] === Listing blobs (1) in '%s' ===", writeContainer)
	if err := s.svc.ListBlobs(ctx, writeContainer); err != nil {
		log.Printf("[ERROR] %v", err)
		return
	}

	log.Printf("[INFO] === Uploading blob to '%s' ===", writeContainer)
	if err := s.svc.UploadBlob(ctx, writeContainer, "test-blob", []byte("Hello from Go! This is a test blob.")); err != nil {
		log.Printf("[ERROR] %v", err)
		return
	}

	log.Printf("[INFO] === Listing blobs (2) in '%s' ===", writeContainer)
	if err := s.svc.ListBlobs(ctx, writeContainer); err != nil {
		log.Printf("[ERROR] %v", err)
		return
	}

	log.Printf("[INFO] === Downloading blob from '%s' ===", writeContainer)
	if _, err := s.svc.DownloadBlob(ctx, writeContainer, "test-blob"); err != nil {
		log.Printf("[ERROR] %v", err)
		return
	}

	log.Println("[INFO] All operations completed successfully!")
}

package server

import (
	"encoding/json"
	"log"
	"net/http"
)

// handleListBlobs returns a list of blobs in the write container.
func (s *Server) handleListBlobs(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	blobs, err := s.svc.ListBlobsResult(ctx, s.svc.Cfg.WriteContainer)
	if err != nil {
		log.Printf("[ERROR] Failed to list blobs: %v", err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(blobs)
}

// handleGetBlob returns the content of a specific blob.
func (s *Server) handleGetBlob(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	blobName := r.PathValue("name")

	content, err := s.svc.GetBlobContent(ctx, s.svc.Cfg.WriteContainer, blobName)
	if err != nil {
		log.Printf("[ERROR] Failed to get blob %s: %v", blobName, err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"name":    blobName,
		"content": content,
	})
}

// handleUploadBlob uploads a new blob to the write container.
func (s *Server) handleUploadBlob(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req struct {
		Name    string `json:"name"`
		Content string `json:"content"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("[ERROR] Failed to parse upload request: %v", err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "invalid request body"})
		return
	}

	if err := s.svc.UploadBlob(ctx, s.svc.Cfg.WriteContainer, req.Name, []byte(req.Content)); err != nil {
		log.Printf("[ERROR] Failed to upload blob: %v", err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{"name": req.Name})
}

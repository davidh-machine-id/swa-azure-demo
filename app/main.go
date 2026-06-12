package main

import (
	"context"
	"embed"
	"log"
	"net/http"

	"github.com/davidh-machine-id/azure-exp/app/internal/config"
	"github.com/davidh-machine-id/azure-exp/app/internal/server"
	"github.com/davidh-machine-id/azure-exp/app/internal/storage"
)

//go:embed web
var webFS embed.FS

func main() {
	ctx := context.Background()

	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("[ERROR] %v", err)
	}

	svc, err := storage.New(cfg)
	if err != nil {
		log.Fatalf("[ERROR] %v", err)
	}

	srv := server.NewWithConfig(svc, cfg, webFS)

	go srv.RunDemoOps(ctx, cfg.WriteContainer)

	log.Println("[INFO] Starting HTTP server on :8080")
	if err := http.ListenAndServe(":8080", srv); err != nil {
		log.Fatalf("[ERROR] HTTP server failed: %v", err)
	}
}

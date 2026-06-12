package config

import (
	"fmt"
	"os"
)

// Config holds all configuration sourced from environment variables.
type Config struct {
	StorageAccount     string
	WriteContainer     string
	SWAAgentSocketPath string
	AzureTenantID      string
	AzureClientID      string
	RogueAppAddress    string
}

// Load reads and validates required environment variables.
func Load() (*Config, error) {
	cfg := &Config{
		StorageAccount:     os.Getenv("STORAGE_ACCOUNT_NAME"),
		WriteContainer:     os.Getenv("WRITE_CONTAINER_NAME"),
		SWAAgentSocketPath: os.Getenv("SWA_AGENT_SOCKET_PATH"),
		AzureTenantID:      os.Getenv("AZURE_TENANT_ID"),
		AzureClientID:      os.Getenv("AZURE_CLIENT_ID"),
		RogueAppAddress:    os.Getenv("ROGUE_APP_ADDRESS"),
	}

	required := map[string]string{
		"STORAGE_ACCOUNT_NAME":  cfg.StorageAccount,
		"WRITE_CONTAINER_NAME":  cfg.WriteContainer,
		"SWA_AGENT_SOCKET_PATH": cfg.SWAAgentSocketPath,
		"AZURE_TENANT_ID":       cfg.AzureTenantID,
		"AZURE_CLIENT_ID":       cfg.AzureClientID,
	}

	for name, val := range required {
		if val == "" {
			return nil, fmt.Errorf("required environment variable %s is not set", name)
		}
	}

	return cfg, nil
}

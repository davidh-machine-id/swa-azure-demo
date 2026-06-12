# ============================================================
# Azure Module - Storage Account & SWA Integration
# ============================================================

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

locals {
  subscription_id = data.azurerm_subscription.current.subscription_id

  # Resource names
  storage_account_name = "${substr(replace(lower(var.prefix), "/[^a-z0-9]/", ""), 0, 20)}sgan"

  managed_identity_name     = "${var.prefix}-mi"
  federated_credential_name = "${var.prefix}-credential"
  container_write_name      = "${var.prefix}-stg-write"
}

# ============================================================
# Resource Group
# ============================================================

resource "azurerm_resource_group" "swa" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    ManagedBy = "terraform"
  }
}

# ============================================================
# Storage Account (Standard, LRS, StorageV2)
# ============================================================

resource "azurerm_storage_account" "swa" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.swa.name
  location                 = azurerm_resource_group.swa.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = {
    ManagedBy = "terraform"
  }
}

# ============================================================
# Blob Containers
# ============================================================

resource "azurerm_storage_container" "write" {
  name                  = local.container_write_name
  storage_account_name  = azurerm_storage_account.swa.name
  container_access_type = "private"
}

# ============================================================
# User-Assigned Managed Identity
# ============================================================

resource "azurerm_user_assigned_identity" "swa" {
  name                = local.managed_identity_name
  resource_group_name = azurerm_resource_group.swa.name
  location            = azurerm_resource_group.swa.location

  tags = {
    ManagedBy = "terraform"
  }
}

# Wait a bit after MI creation for propagation
resource "time_sleep" "wait_for_mi" {
  depends_on      = [azurerm_user_assigned_identity.swa]
  create_duration = "10s"
}

# ============================================================
# Federated Identity Credential (when both URL and subject provided)
# ============================================================

resource "azurerm_federated_identity_credential" "swa" {
  count               = var.swa_oidc_issuer_url != "" && var.spiffe_subject != "" ? 1 : 0
  name                = local.federated_credential_name
  resource_group_name = azurerm_resource_group.swa.name
  parent_id           = azurerm_user_assigned_identity.swa.id
  audience            = [var.azure_jwt_audience]
  issuer              = var.swa_oidc_issuer_url
  subject             = var.spiffe_subject

  depends_on = [time_sleep.wait_for_mi]
}

# ============================================================
# Role Assignments - Scoped to Storage Account
# ============================================================

resource "azurerm_role_assignment" "blob_contributor" {
  scope                = azurerm_storage_account.swa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.swa.principal_id
  principal_type       = "ServicePrincipal"
}

# Current user contributor for seeding blobs
resource "azurerm_role_assignment" "blob_contributor_user" {
  scope                = azurerm_storage_account.swa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}

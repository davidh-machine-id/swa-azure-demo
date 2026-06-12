# ============================================================
# Environment Outputs
# ============================================================

output "resource_group_name" {
  description = "Resource group name"
  value       = module.azure_swa.resource_group_name
}

output "resource_group_id" {
  description = "Resource group resource ID"
  value       = module.azure_swa.resource_group_id
}

output "storage_account_name" {
  description = "Azure Storage Account name"
  value       = module.azure_swa.azure_storage_account
}

output "storage_account_id" {
  description = "Azure Storage Account resource ID"
  value       = module.azure_swa.azure_storage_account_id
}

output "storage_account_endpoint" {
  description = "Azure Storage Account primary blob endpoint"
  value       = module.azure_swa.azure_storage_account_primary_endpoint
}

output "managed_identity_client_id" {
  description = "Managed Identity client ID"
  value       = module.azure_swa.managed_identity_client_id
}

output "managed_identity_tenant_id" {
  description = "Managed Identity tenant ID"
  value       = module.azure_swa.managed_identity_tenant_id
}

output "managed_identity_principal_id" {
  description = "Managed Identity principal ID"
  value       = module.azure_swa.managed_identity_principal_id
}

output "write_container" {
  description = "Write container name"
  value       = module.azure_swa.azure_container_write
}

output "subscription_id" {
  description = "Azure subscription ID"
  value       = module.azure_swa.azure_subscription_id
}

output "federated_credential_name" {
  description = "Federated identity credential name"
  value       = module.azure_swa.azurerm_federated_identity_credential_name
}

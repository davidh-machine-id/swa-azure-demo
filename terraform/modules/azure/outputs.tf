# ============================================================
# Azure Module - Outputs
# ============================================================

output "azure_subscription_id" {
  description = "Azure subscription ID"
  value       = local.subscription_id
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.swa.name
}

output "resource_group_id" {
  description = "Resource group resource ID"
  value       = azurerm_resource_group.swa.id
}

output "azure_storage_account" {
  description = "Storage account name"
  value       = azurerm_storage_account.swa.name
}

output "azure_storage_account_id" {
  description = "Storage account resource ID"
  value       = azurerm_storage_account.swa.id
}

output "azure_storage_account_primary_endpoint" {
  description = "Storage account primary blob endpoint"
  value       = azurerm_storage_account.swa.primary_blob_endpoint
}

output "azurerm_federated_identity_credential_name" {
  description = "Azurerm Federated Identity Crednetial"
  value       = length(azurerm_federated_identity_credential.swa) > 0 ? azurerm_federated_identity_credential.swa[0].name : null
}

output "managed_identity_client_id" {
  description = "Managed Identity client ID"
  value       = azurerm_user_assigned_identity.swa.client_id
}

output "managed_identity_tenant_id" {
  description = "Managed Identity tenant ID"
  value       = azurerm_user_assigned_identity.swa.tenant_id
}

output "managed_identity_principal_id" {
  description = "Managed Identity principal ID"
  value       = azurerm_user_assigned_identity.swa.principal_id
}

output "managed_identity_id" {
  description = "Managed Identity resource ID"
  value       = azurerm_user_assigned_identity.swa.id
}

output "azure_container_write" {
  description = "Blob container name for writing"
  value       = azurerm_storage_container.write.name
}

output "azure_jwt_audience" {
  description = "JWT audience for federated credentials"
  value       = var.azure_jwt_audience
}

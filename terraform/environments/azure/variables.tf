# ============================================================
# Environment Variables
# ============================================================

variable "location" {
  type        = string
  description = "Azure region"
  default     = "centralus"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "demo"
}

variable "swa_oidc_issuer_url" {
  type        = string
  description = "SWA OIDC issuer URL"
  default     = ""
  sensitive   = false
}

variable "spiffe_subject" {
  type        = string
  description = "SPIFFE subject for federated credentials"
  default     = ""
  sensitive   = false
}

variable "azure_jwt_audience" {
  type        = string
  description = "JWT audience for Azure"
  default     = "api://AzureADTokenExchange"
}

variable "prefix" {
  type        = string
  description = "Project prefix"
}

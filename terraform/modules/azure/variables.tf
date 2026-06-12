# ============================================================
# Azure Module - Input Variables
# ============================================================

variable "location" {
  type        = string
  description = "Azure region for resources"
  default     = "centralus"
}

variable "prefix" {
  type        = string
  description = "Project prefix used to compute resource names"
}

variable "swa_oidc_issuer_url" {
  type        = string
  description = "SWA OIDC issuer URL"
}

variable "spiffe_subject" {
  type        = string
  description = "SPIFFE subject for federated credentials (e.g., spiffe://trust-domain/k8s-nodegroup/ns/namespace/sa/serviceaccount)"
}

variable "azure_jwt_audience" {
  type        = string
  description = "JWT audience for Azure federated credentials"
  default     = "api://AzureADTokenExchange"
}
variable "resource_group_name" {
  type        = string
  description = "Azure resource group name"
}

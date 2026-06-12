# variables.tf

variable "trust_domain_name" {
  description = "Trust domain name for SWA (e.g., example.org)"
  type        = string

  validation {
    condition     = length(trimspace(var.trust_domain_name)) > 0
    error_message = "trust_domain_name must be a non-empty string"
  }
}
variable "prefix" {
  description = "Prefix for resource names to ensure uniqueness"
  type        = string
  default     = "swa"
}

variable "cluster_name" {
  description = "Kubernetes cluster name used as the key under node_attestation.k8s_psat.clusters"
  type        = string

  validation {
    condition     = length(trimspace(var.cluster_name)) > 0
    error_message = "cluster_name must be a non-empty string"
  }
}

variable "workload_namespace" {
  description = "App namespace to be attested as a workload"
  type        = string
}

# variable "jwks_uri" {
#   description = "JWKS URI for JWT authentication"
#   # Managed cluster style examples:
#   # GKE: "https://container.googleapis.com/v1/projects/<project>/locations/<region>/clusters/<cluster>/jwks"
#   # EKS: "https://oidc.eks.<region>.amazonaws.com/id/<oidc-id>/keys"
#   # AKS: "https://<region>.oic.prod-aks.azure.com/<tenant>/<guid>/openid/v1/jwks"
#   # Example (self-managed k8s API server OIDC issuer)
#   # jwt_issuer = "https://kubernetes.default.svc.cluster.local"
#   type = string
# }

variable "public_keys" {
  description = "Public Keys for JWT authentication"
  type        = string
}

variable "jwt_issuer" {
  description = "JWT issuer URL for SWA server authentication"
  # Managed cluster style examples:
  # GKE: "https://container.googleapis.com/v1/projects/<project>/locations/<region>/clusters/<cluster>"
  # EKS: "https://oidc.eks.<region>.amazonaws.com/id/<oidc-id>"
  # AKS: "https://<region>.oic.prod-aks.azure.com/<tenant>/<guid>/"
  # Example (self-managed k8s API server OIDC issuer)
  # jwks_uri = "https://kubernetes.default.svc.cluster.local/openid/v1/jwks"
  type = string
}

variable "jwt_audience" {
  description = "JWT audience expected by SWA server authentication"
  type        = string
  default     = "conjur"
}

variable "jwt_subject" {
  description = "JWT subject for SWA server authentication"
  type        = string
  default     = "system:serviceaccount:swa-system:swa-server"
}

variable "server_group_name" {
  type = string
}
variable "node_group_name" {
  type = string
}
variable "server_name" {
  type = string
}

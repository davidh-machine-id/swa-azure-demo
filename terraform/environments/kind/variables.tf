variable "prefix" {
  description = "Prefix for resource names to ensure uniqueness"
  type        = string
}

variable "cluster_name" {
  description = "Kubernetes cluster name used as the key under node_attestation.k8s_psat.clusters"
  type        = string

  validation {
    condition     = length(trimspace(var.cluster_name)) > 0
    error_message = "cluster_name must be a non-empty string"
  }
}

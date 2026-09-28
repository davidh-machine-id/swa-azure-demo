#outputs.tf

output "trust_domain_name" {
  value = conjur_swa_trust_domain.prod.name
}

output "server_group_name" {
  value = conjur_swa_server_group.k8s.name
}

output "server_name" {
  value = conjur_swa_server.k8s.name
}

output "authn_id" {
  # Base64 encoded authn_id (aka login_url)
  value = conjur_swa_server.k8s.authn_id
}

output "node_group_name" {
  value = conjur_swa_node_group.kubernetes.name
}

# TODO: add these after they are added to the conjur tf provider
# output "oidc_issuer_url" {
#   value = conjur_swa_trust_domain.prod.jwt.discovery_endpoints.oidc_discovery_url
# }

# output "jwks_uri" {
#   value = conjur_swa_trust_domain.prod.jwt.discovery_endpoints.jwks_uri
# }

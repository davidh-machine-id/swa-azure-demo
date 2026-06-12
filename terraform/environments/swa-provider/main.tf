# main.tf

# The URLs preceding the resource stanzas contain curl calls.
# Properties are mapped from the curl request body into the tf resource

# https://docs.cyberark.com/early-release/swa/en/content/conjurcloud/ccl-swa-getstarted-k8.htm#SetupSecureWorkloadAccess
resource "swa_trust_domain" "prod" {
  name = var.trust_domain_name

  jwt = {
    signature_algorithm = "RS512"
    signing_key_type    = "RSA_4096"
    signing_key_ttl     = 86400
    token_ttl           = 300
  }

  x509 = {
    workload_ttl = 3600
  }
}

# https://docs.cyberark.com/early-release/swa/en/content/conjurcloud/apis/ccl-api-swa-create-server-group.htm
resource "swa_server_group" "k8s" {
  name              = var.server_group_name
  description       = "SWA Server running on k8s"
  trust_domain_name = swa_trust_domain.prod.name

  node_attestation = {
    k8s_psat = {
      clusters = {
        (var.cluster_name) = {
          service_account_allow_list = [
            "swa-system:swa-agent"
          ],
          audience = ["swa-server"],
          "allowed_node_label_keys" : null,
          "allowed_pod_label_keys" : [
            "swa_nodegroup"
          ],
        }
      }
    }
  }
}

# https://docs.cyberark.com/early-release/swa/en/content/conjurcloud/apis/ccl-api-swa-create-node-group.htm
resource "swa_node_group" "kubernetes" {
  name              = var.node_group_name
  trust_domain_name = swa_trust_domain.prod.name
  server_group_name = swa_server_group.k8s.name
  workload_type     = "kubernetes"
  description       = "Kubernetes workload node group"

  workload_configuration = {
    spiffe_id_template = "spiffe://{{ .trustdomain }}/{{ .nodegroup }}/ns/{{ .k8s.ns }}/sa/{{ .k8s.sa }}"
    workload_registration_policies = [
      "k8s.ns in ['default', '${var.workload_namespace}']"
    ]
  }
}

# https://docs.cyberark.com/early-release/swa/en/content/conjurcloud/apis/ccl-api-swa-register-server.htm
resource "swa_server" "k8s" {
  name            = var.server_name
  server_group_id = swa_server_group.k8s.id

  auth = {
    type        = "JWT"
    subject     = var.jwt_subject
    public_keys = var.public_keys
    audience    = var.jwt_audience
    issuer      = var.jwt_issuer
  }
}


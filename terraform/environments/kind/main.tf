resource "kind_cluster" "default" {
  name           = var.cluster_name
  node_image     = "kindest/node:v1.35.0"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    # One control plane node
    node {
      role = "control-plane"
    }

    # One worker node
    node {
      role = "worker"
    }
  }
}

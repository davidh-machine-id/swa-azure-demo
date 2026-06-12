# outputs.tf

resource "local_file" "kubeconfig" {
  content  = kind_cluster.default.kubeconfig
  filename = "${path.module}/kubeconfig"
}

output "kubeconfig" {
  value = kind_cluster.default.kubeconfig
}

output "cluster_name" {
  value = "kind-${kind_cluster.default.name}"
}
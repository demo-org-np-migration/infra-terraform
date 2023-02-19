resource "kubernetes_namespace" "this" {
  metadata {
    name   = var.env
    labels = local.common_labels
  }
}

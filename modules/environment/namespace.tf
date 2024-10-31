resource "kubernetes_namespace" "this" {
  metadata {
    name   = var.env
    labels = merge(local.common_labels, { "app.kubernetes.io/name" = var.env })
  }
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = var.env
    labels = {
      "cauri.io/env" = var.env
    }
  }
}

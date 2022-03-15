resource "kubernetes_namespace" "platform" {
  metadata {
    name = "platform"
    labels = {
      "cauri.io/env" = "platform"
    }
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "cauri.io/env" = "monitoring"
    }
  }
}

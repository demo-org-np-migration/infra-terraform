resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "redis" }
    }

    template {
      metadata {
        labels = { app = "redis" }
      }

      spec {
        container {
          name  = "redis"
          image = "redis:7-alpine"

          port {
            name           = "redis"
            container_port = 6379
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    selector = { app = "redis" }

    port {
      name        = "redis"
      port        = 6379
      target_port = 6379
    }
  }
}

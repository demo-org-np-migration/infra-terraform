# Kong dbless (declarativo), un solo deployment ruteando por host a staging y a
# prod. kong.yaml vive versionado acá al lado, no en un CRD ni en un configmap
# generado -- así el diff de una ruta nueva se ve en el PR.

resource "kubernetes_config_map" "kong_declarative_config" {
  metadata {
    name      = "kong-declarative-config"
    namespace = kubernetes_namespace.platform.metadata[0].name
  }

  data = {
    "kong.yaml" = file("${path.module}/kong/kong.yaml")
  }
}

resource "kubernetes_deployment" "kong" {
  metadata {
    name      = "kong"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "kong"
      "app.kubernetes.io/part-of" = "cauri"
      "cauri.io/team"             = "platform"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "kong" }
    }

    template {
      metadata {
        labels = { app = "kong" }
      }

      spec {
        container {
          name  = "kong"
          image = "kong:3.7"

          port {
            name           = "proxy"
            container_port = 8000
          }

          env {
            name  = "KONG_DATABASE"
            value = "off"
          }
          env {
            name  = "KONG_DECLARATIVE_CONFIG"
            value = "/kong/kong.yaml"
          }
          env {
            name  = "KONG_PROXY_LISTEN"
            value = "0.0.0.0:8000"
          }

          volume_mount {
            name       = "kong-config"
            mount_path = "/kong"
          }
        }

        volume {
          name = "kong-config"
          config_map {
            name = kubernetes_config_map.kong_declarative_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "kong" {
  metadata {
    name      = "kong"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "kong"
      "app.kubernetes.io/part-of" = "cauri"
      "cauri.io/team"             = "platform"
    }
  }

  spec {
    type     = "LoadBalancer"
    selector = { app = "kong" }

    port {
      name        = "proxy"
      port        = 8000
      target_port = 8000
    }
  }
}

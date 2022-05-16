# Deuda conocida: Keycloak en modo dev (start-dev), no apto para producción real.
# Alcanza para el lab. Los dos realms se importan al arrancar desde el ConfigMap
# montado en /opt/keycloak/data/import (--import-realm los levanta a los dos).

resource "kubernetes_config_map" "keycloak_realms" {
  metadata {
    name      = "keycloak-realms"
    namespace = kubernetes_namespace.platform.metadata[0].name
  }

  data = {
    "cauri-staging-realm.json" = file("${path.module}/keycloak/realm-cauri-staging.json")
    "cauri-prod-realm.json"    = file("${path.module}/keycloak/realm-cauri-prod.json")
  }
}

resource "kubernetes_deployment" "keycloak" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "keycloak"
      "app.kubernetes.io/part-of" = "cauri"
      "cauri.io/team"             = "platform"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "keycloak" }
    }

    template {
      metadata {
        labels = { app = "keycloak" }
      }

      spec {
        container {
          name  = "keycloak"
          image = "quay.io/keycloak/keycloak:25.0"
          args  = ["start-dev", "--import-realm"]

          port {
            name           = "http"
            container_port = 8080
          }

          env {
            name  = "KC_HOSTNAME"
            value = "keycloak.platform.svc"
          }
          env {
            name  = "KC_HOSTNAME_PORT"
            value = "8080"
          }
          env {
            name  = "KC_HTTP_ENABLED"
            value = "true"
          }
          env {
            name  = "KC_HOSTNAME_STRICT"
            value = "false"
          }
          env {
            name  = "KC_HOSTNAME_STRICT_HTTPS"
            value = "false"
          }
          env {
            name  = "KEYCLOAK_ADMIN"
            value = "admin"
          }
          env {
            name  = "KEYCLOAK_ADMIN_PASSWORD"
            value = "cauri123"
          }

          volume_mount {
            name       = "realms"
            mount_path = "/opt/keycloak/data/import"
          }
        }

        volume {
          name = "realms"
          config_map {
            name = kubernetes_config_map.keycloak_realms.metadata[0].name
          }
        }
      }
    }
  }
}

# LoadBalancer en 8080; k3d lo mapea al 8180 de la laptop (config del cluster).
# El issuer de los tokens es siempre el interno con :8080, nunca el de la laptop.
resource "kubernetes_service" "keycloak" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "keycloak"
      "app.kubernetes.io/part-of" = "cauri"
      "cauri.io/team"             = "platform"
    }
  }

  spec {
    type     = "LoadBalancer"
    selector = { app = "keycloak" }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
    }
  }
}

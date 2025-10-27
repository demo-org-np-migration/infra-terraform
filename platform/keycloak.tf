# Deuda conocida: Keycloak en modo dev (start-dev), no apto para producción real.
# Alcanza para el lab. Los dos realms se importan al arrancar desde el ConfigMap
# montado en /opt/keycloak/data/import (--import-realm los levanta a los dos).

# start-dev guarda la base (H2) en el filesystem del contenedor. Sin PVC, cada
# reinicio del pod la pierde -> Keycloak regenera las claves RSA del realm al
# arrancar de cero, y todo servicio que ya cacheó el JWKS viejo empieza a
# rechazar tokens válidos con invalid_token hasta que se reinicia también.
# Persistimos /opt/keycloak/data/h2 (ahí vive la base en dev mode) para que
# sobreviva a un restart del pod. local-path es WaitForFirstConsumer, mismo
# caso que el PVC de postgres.
resource "kubernetes_persistent_volume_claim" "keycloak_data" {
  metadata {
    name      = "keycloak-data"
    namespace = kubernetes_namespace.platform.metadata[0].name
  }

  wait_until_bound = false

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-path"
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

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

    # Con el PVC de por medio, dos pods a la vez pelean por el mismo volumen
    # ReadWriteOnce -- Recreate mata el viejo antes de levantar el nuevo.
    strategy {
      type = "Recreate"
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

          # Keycloak 25 usa hostname v2: KC_HOSTNAME_PORT y KC_HOSTNAME_STRICT_HTTPS
          # solo existen bajo el feature hostname:v1 (deprecado). Con v2, si le pasás
          # una URL completa a KC_HOSTNAME el issuer queda fijo a esa URL sin importar
          # el puerto/host por el que entró el request -- si le dejás solo el host
          # (como antes), el issuer arrastra el puerto de la conexión entrante y desde
          # la laptop (8180) salía un issuer distinto al que validan los servicios.
          env {
            name  = "KC_HOSTNAME"
            value = "http://keycloak.platform.svc:8080"
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
          volume_mount {
            name       = "data"
            mount_path = "/opt/keycloak/data/h2"
          }
        }

        volume {
          name = "realms"
          config_map {
            name = kubernetes_config_map.keycloak_realms.metadata[0].name
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.keycloak_data.metadata[0].name
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

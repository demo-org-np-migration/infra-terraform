# Postgres en Deployment con PVC, sin operador. Decisión pragmática: no
# necesitamos HA para el lab y un StatefulSet no suma nada acá porque es
# réplica única. Si esto escala de verdad, esto es lo primero que cambia
# (ver README, Deuda conocida).

resource "kubernetes_config_map" "postgres_initdb" {
  metadata {
    name      = "postgres-initdb"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    "01-create-databases.sh" = <<-EOT
      #!/bin/bash
      set -e
      for db in ledger payments cards rates warehouse notifications; do
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
          SELECT 'CREATE DATABASE $db'
          WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db')\gexec
      EOSQL
      done
    EOT
  }
}

resource "kubernetes_secret" "postgres_credentials" {
  metadata {
    name      = "postgres-credentials"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    username = "cauri"
    password = "cauri-${var.env}-pg"
  }
}

resource "kubernetes_persistent_volume_claim" "postgres" {
  metadata {
    name      = "postgres-data"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "2Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "postgres" }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = { app = "postgres" }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:16-alpine"

          port {
            name           = "postgres"
            container_port = 5432
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "username"
              }
            }
          }
          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "password"
              }
            }
          }
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }
          volume_mount {
            name       = "initdb"
            mount_path = "/docker-entrypoint-initdb.d"
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres.metadata[0].name
          }
        }
        volume {
          name = "initdb"
          config_map {
            name         = kubernetes_config_map.postgres_initdb.metadata[0].name
            default_mode = "0755"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    selector = { app = "postgres" }

    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
    }
  }
}

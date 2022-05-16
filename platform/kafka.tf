# Un solo broker KRaft (sin zookeeper) para ambos entornos. Los topics llevan
# prefijo de entorno (staging./prod.) así que comparten el broker sin pisarse.
# Deuda conocida: single node, sin réplicas. Ver README.

resource "kubernetes_deployment" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "kafka"
      "app.kubernetes.io/part-of" = "cauri"
      "cauri.io/team"             = "platform"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "kafka" }
    }

    template {
      metadata {
        labels = { app = "kafka" }
      }

      spec {
        container {
          name  = "kafka"
          image = "apache/kafka:3.8.0"

          port {
            name           = "broker"
            container_port = 9092
          }

          env {
            name  = "KAFKA_NODE_ID"
            value = "1"
          }
          env {
            name  = "KAFKA_PROCESS_ROLES"
            value = "broker,controller"
          }
          env {
            name  = "KAFKA_LISTENERS"
            value = "PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093"
          }
          env {
            name  = "KAFKA_ADVERTISED_LISTENERS"
            value = "PLAINTEXT://kafka.platform.svc:9092"
          }
          env {
            name  = "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP"
            value = "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT"
          }
          env {
            name  = "KAFKA_CONTROLLER_LISTENER_NAMES"
            value = "CONTROLLER"
          }
          env {
            name  = "KAFKA_CONTROLLER_QUORUM_VOTERS"
            value = "1@localhost:9093"
          }
          env {
            name  = "KAFKA_AUTO_CREATE_TOPICS_ENABLE"
            value = "true"
          }
          env {
            name  = "CLUSTER_ID"
            value = "cauri-kafka-kraft-1"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "kafka"
      "app.kubernetes.io/part-of" = "cauri"
      "cauri.io/team"             = "platform"
    }
  }

  spec {
    selector = { app = "kafka" }

    port {
      name        = "broker"
      port        = 9092
      target_port = 9092
    }
  }
}

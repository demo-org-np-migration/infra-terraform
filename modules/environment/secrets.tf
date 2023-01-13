locals {
  # Clients confidenciales de las convenciones internas de API que llaman a otros servicios.
  service_clients = [
    "mobile-bff",
    "merchant-portal-bff",
    "backoffice-api",
    "payments-api",
    "cards-api",
    "kyc-service",
    "payments-worker",
    "notifications",
  ]
}

resource "kubernetes_secret" "aws_credentials" {
  metadata {
    name      = "aws-credentials"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    AWS_ACCESS_KEY_ID     = "test"
    AWS_SECRET_ACCESS_KEY = "test"
  }
}

resource "kubernetes_secret" "keycloak_client" {
  for_each = toset(local.service_clients)

  metadata {
    name      = "keycloak-client-${each.key}"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    client_secret = "${each.key}-secret-${var.env}"
  }
}

resource "kubernetes_secret" "cards_api_secrets" {
  metadata {
    name      = "cards-api-secrets"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    cardnet_api_key = "dummy-cardnet-api-key-${var.env}"
  }
}

resource "kubernetes_secret" "fraud_scoring_secrets" {
  metadata {
    name      = "fraud-scoring-secrets"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    sentinel_api_key = "dummy-sentinel-api-key-${var.env}"
  }
}

resource "kubernetes_secret" "kyc_service_secrets" {
  metadata {
    name      = "kyc-service-secrets"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    veridoc_api_key = "dummy-veridoc-api-key-${var.env}"
  }
}

resource "kubernetes_secret" "notifications_secrets" {
  metadata {
    name      = "notifications-secrets"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  data = {
    mailgunner_api_key = "dummy-mailgunner-api-key-${var.env}"
    pushly_api_key     = "dummy-pushly-api-key-${var.env}"
  }
}

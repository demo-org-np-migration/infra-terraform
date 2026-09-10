# Las imágenes que publican los pipelines en ghcr.io quedan privadas por default en la org.
# Si hay token, se cuelga un pull secret del ServiceAccount default del namespace: ninguna app
# declara ServiceAccount propio, así que todas lo heredan sin tocar sus manifests.
resource "kubernetes_secret" "ghcr_pull" {
  count = var.ghcr_pull_token != "" ? 1 : 0
  metadata {
    name      = "ghcr-pull"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.common_labels
  }
  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          username = "cauri-pull"
          password = var.ghcr_pull_token
          auth     = base64encode("cauri-pull:${var.ghcr_pull_token}")
        }
      }
    })
  }
}

resource "kubernetes_default_service_account" "this" {
  count = var.ghcr_pull_token != "" ? 1 : 0
  metadata {
    namespace = kubernetes_namespace.this.metadata[0].name
  }
  image_pull_secret {
    name = kubernetes_secret.ghcr_pull[0].metadata[0].name
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.8.2"
  namespace  = kubernetes_namespace.platform.metadata[0].name

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  # k3d mapea el 443 del Service al 8443 de la laptop (config del cluster, no de acá).
  set {
    name  = "server.service.servicePortHttps"
    value = "443"
  }

  # Server sigue exigiendo TLS/redirect puertas adentro; no es "insecure" hacia afuera,
  # solo evita el loop de redirects atrás del LB local.
  set {
    name  = "configs.params.server\\.insecure"
    value = "false"
  }
}

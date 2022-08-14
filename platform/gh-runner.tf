# Runner self-hosted, registrado a nivel org con label cauri-k8s. Necesita
# permisos de "edit" en staging y prod para poder aplicar los manifests de los
# repos estilo A (Actions + YAML pelado) y hacer los helm upgrade de estilo B.
# Además un ClusterRole propio para servicemonitors porque "edit" no los toca
# (son un CRD de kube-prometheus-stack, no un recurso core).

resource "kubernetes_service_account" "gh_runner" {
  metadata {
    name      = "gh-runner"
    namespace = kubernetes_namespace.platform.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "gh_runner_servicemonitors" {
  metadata {
    name = "gh-runner-servicemonitors"
  }

  rule {
    api_groups = ["monitoring.coreos.com"]
    resources  = ["servicemonitors"]
    verbs      = ["get", "list", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_role_binding" "gh_runner_edit_staging" {
  metadata {
    name      = "gh-runner-edit"
    namespace = "staging"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "edit"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.gh_runner.metadata[0].name
    namespace = kubernetes_namespace.platform.metadata[0].name
  }
}

resource "kubernetes_role_binding" "gh_runner_edit_prod" {
  metadata {
    name      = "gh-runner-edit"
    namespace = "prod"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "edit"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.gh_runner.metadata[0].name
    namespace = kubernetes_namespace.platform.metadata[0].name
  }
}

resource "kubernetes_role_binding" "gh_runner_servicemonitors_staging" {
  metadata {
    name      = "gh-runner-servicemonitors"
    namespace = "staging"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.gh_runner_servicemonitors.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.gh_runner.metadata[0].name
    namespace = kubernetes_namespace.platform.metadata[0].name
  }
}

resource "kubernetes_role_binding" "gh_runner_servicemonitors_prod" {
  metadata {
    name      = "gh-runner-servicemonitors"
    namespace = "prod"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.gh_runner_servicemonitors.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.gh_runner.metadata[0].name
    namespace = kubernetes_namespace.platform.metadata[0].name
  }
}

# Si github_runner_pat viene vacío (no seteado por TF_VAR_github_runner_pat),
# el Deployment se crea igual. El runner queda en CrashLoopBackOff hasta que
# haya un token real -- lo dejamos así a propósito, no vale la pena bloquear
# todo el apply por esto en el lab.
resource "kubernetes_secret" "gh_runner_token" {
  metadata {
    name      = "gh-runner-token"
    namespace = kubernetes_namespace.platform.metadata[0].name
  }

  data = {
    ACCESS_TOKEN = var.github_runner_pat
  }
}

resource "kubernetes_deployment" "gh_runner" {
  metadata {
    name      = "gh-runner"
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "gh-runner"
      "app.kubernetes.io/part-of" = "cauri"
      "cauri.io/team"             = "platform"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "gh-runner" }
    }

    template {
      metadata {
        labels = { app = "gh-runner" }
      }

      spec {
        service_account_name = kubernetes_service_account.gh_runner.metadata[0].name

        container {
          name  = "gh-runner"
          image = "ghcr.io/demo-org-np-migration/gh-runner:${var.gh_runner_tag}"

          env {
            name  = "ORG_NAME"
            value = var.github_org
          }
          env {
            name  = "RUNNER_SCOPE"
            value = "org"
          }
          env {
            name  = "LABELS"
            value = "cauri-k8s"
          }
          env {
            name  = "RUNNER_NAME_PREFIX"
            value = "cauri"
          }
          env {
            name = "ACCESS_TOKEN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.gh_runner_token.metadata[0].name
                key  = "ACCESS_TOKEN"
              }
            }
          }
          env {
            name  = "RUNNER_WORKDIR"
            value = "/tmp/runner"
          }
          env {
            name  = "EPHEMERAL"
            value = "false"
          }
        }
      }
    }
  }
}

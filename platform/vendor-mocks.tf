# Un Deployment + Service por (vendor, modo). Todos corren la misma imagen
# vendor-mock; VENDOR/MODE seleccionan el comportamiento en runtime. El nombre
# <vendor>-<modo> es el que coredns.tf reescribe desde los hostnames externos.

locals {
  vendors      = ["cardnet", "sentinel", "veridoc", "openfx", "mailgunner", "pushly"]
  vendor_modes = ["sandbox", "live"]

  vendor_instances = {
    for pair in setproduct(local.vendors, local.vendor_modes) :
    "${pair[0]}-${pair[1]}" => { vendor = pair[0], mode = pair[1] }
  }
}

resource "kubernetes_deployment" "vendor_mock" {
  for_each = local.vendor_instances

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = each.key
      "app.kubernetes.io/part-of" = "cauri"
      "cauri.io/team"             = "platform"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = each.key }
    }

    template {
      metadata {
        labels = { app = each.key }
      }

      spec {
        container {
          name  = "vendor-mock"
          image = "ghcr.io/demo-org-np-migration/vendor-mock:${var.vendor_mock_tag}"

          port {
            name           = "http"
            container_port = 8080
          }

          env {
            name  = "VENDOR"
            value = each.value.vendor
          }
          env {
            name  = "MODE"
            value = each.value.mode
          }
          env {
            name  = "PORT"
            value = "8080"
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 2
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "vendor_mock" {
  for_each = local.vendor_instances

  metadata {
    name      = each.key
    namespace = kubernetes_namespace.platform.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = each.key
      "app.kubernetes.io/part-of" = "cauri"
      "cauri.io/team"             = "platform"
    }
  }

  spec {
    selector = { app = each.key }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
    }
  }
}

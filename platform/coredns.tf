# k3s importa cualquier ConfigMap kube-system/coredns-custom con keys *.override
# dentro del bloque principal de Corefile. Así los hostnames "externos" de los
# vendors resuelven hacia los mocks del namespace platform sin tocar /etc/hosts
# en cada máquina que corre el generador de tráfico.
resource "kubernetes_config_map" "coredns_custom" {
  metadata {
    name      = "coredns-custom"
    namespace = "kube-system"
  }

  data = {
    "vendors.override" = <<-EOT
      rewrite name sandbox.cardnet-processor.io cardnet-sandbox.platform.svc.cluster.local
      rewrite name api.cardnet-processor.io cardnet-live.platform.svc.cluster.local
      rewrite name sandbox.sentinel-fraud.io sentinel-sandbox.platform.svc.cluster.local
      rewrite name api.sentinel-fraud.io sentinel-live.platform.svc.cluster.local
      rewrite name sandbox.veridoc-id.com veridoc-sandbox.platform.svc.cluster.local
      rewrite name api.veridoc-id.com veridoc-live.platform.svc.cluster.local
      rewrite name sandbox.openfx-rates.com openfx-sandbox.platform.svc.cluster.local
      rewrite name api.openfx-rates.com openfx-live.platform.svc.cluster.local
      rewrite name sandbox.mailgunner.net mailgunner-sandbox.platform.svc.cluster.local
      rewrite name api.mailgunner.net mailgunner-live.platform.svc.cluster.local
      rewrite name sandbox.pushly.app pushly-sandbox.platform.svc.cluster.local
      rewrite name api.pushly.app pushly-live.platform.svc.cluster.local
    EOT
  }
}

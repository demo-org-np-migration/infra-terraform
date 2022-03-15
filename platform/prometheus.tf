resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "69.2.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  # Sin esto el operator ignora los ServiceMonitor que traen las apps y solo mira
  # los que declaró el propio chart. Nos comimos un rato buscando por qué Grafana
  # no veía nada antes de encontrar este flag.
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  set {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "grafana.service.port"
    value = "3000"
  }

  set {
    name  = "grafana.adminPassword"
    value = "cauri123"
  }
}

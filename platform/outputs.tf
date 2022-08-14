output "argocd_url" {
  description = "UI de Argo CD desde la laptop (k3d mapea el 443 del Service al 8443 local)."
  value       = "https://localhost:8443"
}

output "keycloak_url" {
  description = "Keycloak desde la laptop. El issuer de los tokens sigue siendo el interno con :8080."
  value       = "http://localhost:8180"
}

output "kong_url" {
  description = "Proxy de Kong desde la laptop."
  value       = "http://localhost:8000"
}

output "grafana_url" {
  description = "Grafana desde la laptop."
  value       = "http://localhost:3000"
}

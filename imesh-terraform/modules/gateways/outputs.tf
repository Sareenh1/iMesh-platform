output "envoy_gateway_status" {
  description = "Envoy Gateway Helm release status"
  value       = helm_release.envoy_gateway.status
}

output "istio_status" {
  description = "Istio Helm release status"
  value       = helm_release.istiod.status
}

output "app_gateway_external_url" {
  description = "Application gateway external URL"
  value       = "https://app.${var.domain}"
}

output "keycloak_gateway_external_url" {
  description = "Keycloak gateway external URL"
  value       = "https://auth.${var.domain}"
}

output "services_external_url" {
  description = "Services external URL"
  value       = "https://services.${var.domain}"
}

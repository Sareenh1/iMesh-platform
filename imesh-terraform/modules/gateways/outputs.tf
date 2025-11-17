output "envoy_gateway_status" {
  description = "Envoy Gateway Helm release status"
  value       = helm_release.envoy_gateway.status
}

output "app_gateway_name" {
  description = "Application gateway name"
  value       = "app"
}

output "keycloak_gateway_name" {
  description = "Keycloak gateway name"
  value       = "keycloak"
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

output "gateway_class" {
  description = "Gateway class name"
  value       = "eg"
}

output "graphql_backend_secret" {
  description = "GraphQL backend client secret"
  value       = random_password.graphql_backend_secret.result
  sensitive   = true
}

output "realm_name" {
  description = "Name of the created Keycloak realm"
  value       = var.realm_config.name
}

output "ui_client_id" {
  description = "UI client ID"
  value       = var.clients.ui.client_id
}

output "graphql_backend_client_id" {
  description = "GraphQL backend client ID"
  value       = var.clients.graphql_backend.client_id
}

output "keycloak_admin_user" {
  description = "Keycloak admin username"
  value       = var.admin_user
}

output "keycloak_service_url" {
  description = "Keycloak service URL"
  value       = "http://keycloak.${var.namespace}.svc.cluster.local"
}

output "configuration_complete" {
  description = "Indicates if Keycloak configuration is complete"
  value       = null_resource.configure_keycloak.id != "" ? "complete" : "pending"
}

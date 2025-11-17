output "graphql_backend_secret" {
  description = "GraphQL backend client secret"
  value       = random_password.graphql_backend_secret.result
  sensitive   = true
}

output "configuration_complete" {
  description = "Indicates if Keycloak configuration is complete"
  value       = null_resource.configure_keycloak.id != "" ? "complete" : "pending"
}

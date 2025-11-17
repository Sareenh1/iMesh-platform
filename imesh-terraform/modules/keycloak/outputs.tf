output "graphql_backend_secret" {
  description = "GraphQL backend client secret"
  value       = random_password.graphql_backend_secret.result
  sensitive   = true
}

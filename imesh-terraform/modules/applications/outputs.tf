output "ui_service_url" {
  description = "UI service URL"
  value       = "http://ui.${var.namespace}.svc.cluster.local"
}

output "graphql_backend_service_url" {
  description = "GraphQL backend service URL"
  value       = "http://graphql-backend.${var.namespace}.svc.cluster.local"
}

output "cluster_backend_service_url" {
  description = "Cluster backend service URL"
  value       = "http://cluster-backend.${var.namespace}.svc.cluster.local"
}

output "graphql_endpoint" {
  description = "GraphQL endpoint URL"
  value       = "http://graphql-backend.${var.namespace}.svc.cluster.local/graphql"
}

output "ui_external_url" {
  description = "UI external URL"
  value       = "https://app.${var.domain}"
}

output "services_external_url" {
  description = "Services external URL"
  value       = "https://services.${var.domain}"
}

output "deployed_services" {
  description = "List of deployed services"
  value = [
    "ui",
    "graphql-backend", 
    "cluster-backend"
  ]
}

output "docker_registry_secret" {
  description = "Name of the Docker registry secret"
  value       = kubernetes_secret.docker_registry.metadata[0].name
}

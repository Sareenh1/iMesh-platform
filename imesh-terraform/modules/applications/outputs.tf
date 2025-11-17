output "deployed_services" {
  description = "List of deployed services"
  value = [
    "ui",
    "graphql-backend", 
    "cluster-backend"
  ]
}

output "ui_service_url" {
  description = "UI service URL"
  value       = "http://ui.${var.namespace}.svc.cluster.local"
}

output "graphql_service_url" {
  description = "GraphQL service URL"
  value       = "http://graphql-backend.${var.namespace}.svc.cluster.local"
}

output "cluster_backend_service_url" {
  description = "Cluster backend service URL"
  value       = "http://cluster-backend.${var.namespace}.svc.cluster.local"
}

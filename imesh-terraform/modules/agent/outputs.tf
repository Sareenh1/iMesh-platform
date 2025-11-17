output "agent_service_url" {
  description = "Agent service URL"
  value       = "http://agent.${var.namespace}.svc.cluster.local"
}

output "cluster_role_name" {
  description = "Cluster role name for the agent"
  value       = "imesh-agent"
}

output "cluster_role_binding_name" {
  description = "Cluster role binding name"
  value       = "imesh-agent"
}

output "docker_registry_secret" {
  description = "Name of the Docker registry secret"
  value       = kubernetes_secret.docker_registry.metadata[0].name
}

output "agent_deployment_name" {
  description = "Agent deployment name"
  value       = "agent"
}

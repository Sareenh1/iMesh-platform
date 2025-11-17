output "agent_status" {
  description = "Agent deployment status"
  value       = "deployed"
}

output "cluster_role_name" {
  description = "Cluster role name"
  value       = kubernetes_cluster_role.imesh_agent.metadata[0].name
}

output "service_account_name" {
  description = "Service account name"
  value       = kubernetes_service_account.agent.metadata[0].name
}

output "application_urls" {
  description = "URLs to access the deployed applications"
  value = {
    ui          = "https://app.${var.domain}"
    auth        = "https://auth.${var.domain}"
    services    = "https://services.${var.domain}"
    graphql     = "https://services.${var.domain}/graphql"
  }
}

output "keycloak_admin_credentials" {
  description = "Keycloak admin credentials"
  value = {
    username = var.keycloak_admin.username
    password = var.keycloak_admin.password
    url      = "https://auth.${var.domain}"
  }
  sensitive = true
}

output "keycloak_client_secrets" {
  description = "Keycloak client secrets"
  value = {
    graphql_backend = module.keycloak.graphql_backend_secret
  }
  sensitive = true
}

output "namespaces" {
  description = "Created Kubernetes namespaces"
  value = [
    kubernetes_namespace.v2_deps.metadata[0].name,
    kubernetes_namespace.v2.metadata[0].name,
    kubernetes_namespace.v2_agent.metadata[0].name,
    kubernetes_namespace.cert_manager.metadata[0].name,
    kubernetes_namespace.envoy_gateway_system.metadata[0].name
  ]
}

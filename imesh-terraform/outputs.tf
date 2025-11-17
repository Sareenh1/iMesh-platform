output "application_urls" {
  description = "URLs to access the deployed applications"
  value = {
    ui          = module.gateways.app_ingress_url
    auth        = module.gateways.keycloak_ingress_url
    services    = module.gateways.services_ingress_url
    graphql     = "${module.gateways.services_ingress_url}/graphql"
  }
}

output "keycloak_admin_credentials" {
  description = "Keycloak admin credentials"
  value = {
    username = var.keycloak_admin.username
    password = var.keycloak_admin.password
    url      = module.gateways.keycloak_ingress_url
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
  value = {
    v2_deps    = kubernetes_namespace.v2_deps.metadata[0].name
    v2         = kubernetes_namespace.v2.metadata[0].name
    v2_agent   = kubernetes_namespace.v2_agent.metadata[0].name
    cert_manager = kubernetes_namespace.cert_manager.metadata[0].name
    ingress_nginx = "ingress-nginx"
  }
}

output "deployment_status" {
  description = "Deployment status"
  value = {
    certificates = module.certificates.cert_manager_status
    dependencies = module.dependencies.mongodb_status
    keycloak     = module.keycloak.configuration_complete
    applications = module.applications.deployed_services
    gateways     = module.gateways.nginx_ingress_status
    agent        = module.agent.agent_status
  }
}

output "ingress_info" {
  description = "Ingress controller information"
  value = module.gateways.ingress_controller
}

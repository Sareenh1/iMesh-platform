output "application_urls" {
  description = "URLs to access the deployed applications"
  value = {
    ui          = module.applications.ui_external_url
    auth        = module.gateways.keycloak_gateway_external_url
    services    = module.gateways.services_external_url
    graphql     = "${module.applications.graphql_endpoint}"
  }
}

output "keycloak_admin_credentials" {
  description = "Keycloak admin credentials"
  value = {
    username = module.keycloak.keycloak_admin_user
    password = var.keycloak_admin.password
    url      = module.gateways.keycloak_gateway_external_url
    internal_url = module.keycloak.keycloak_service_url
  }
  sensitive = true
}

output "keycloak_client_secrets" {
  description = "Keycloak client secrets"
  value = {
    graphql_backend = module.keycloak.graphql_backend_secret
    ui_client_id    = module.keycloak.ui_client_id
    graphql_client_id = module.keycloak.graphql_backend_client_id
  }
  sensitive = true
}

output "database_connections" {
  description = "Database connection details"
  value = {
    mongodb = module.dependencies.mongodb_url
    redis   = module.dependencies.redis_url
    nats    = module.dependencies.nats_url
  }
}

output "service_endpoints" {
  description = "Internal service endpoints"
  value = {
    ui              = module.applications.ui_service_url
    graphql_backend = module.applications.graphql_backend_service_url
    cluster_backend = module.applications.cluster_backend_service_url
    agent           = module.agent.agent_service_url
  }
}

output "deployment_status" {
  description = "Deployment status of various components"
  value = {
    certificates    = module.certificates.cert_manager_status
    dependencies    = module.dependencies.mongodb_helm_release
    keycloak        = module.keycloak.configuration_complete
    applications    = length(module.applications.deployed_services)
    gateways        = module.gateways.envoy_gateway_status
    agent           = module.agent.agent_deployment_name
  }
}

output "namespaces" {
  description = "Created Kubernetes namespaces"
  value = {
    v2_deps    = kubernetes_namespace.v2_deps.metadata[0].name
    v2         = kubernetes_namespace.v2.metadata[0].name
    v2_agent   = kubernetes_namespace.v2_agent.metadata[0].name
    cert_manager = kubernetes_namespace.cert_manager.metadata[0].name
    envoy_gateway = kubernetes_namespace.envoy_gateway_system.metadata[0].name
  }
}

output "security_info" {
  description = "Security-related information"
  value = {
    cluster_role        = module.agent.cluster_role_name
    docker_secret_v2    = module.applications.docker_registry_secret
    docker_secret_agent = module.agent.docker_registry_secret
    nats_cert_secret    = module.certificates.certificate_secrets.nats_server_cert
  }
  sensitive = false
}

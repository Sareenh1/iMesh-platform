output "keycloak_admin_credentials" {
  description = "Keycloak admin credentials"
  value = {
    username = var.keycloak_admin_user
    password = module.keycloak.keycloak_admin_password
    url      = "https://auth.${var.domain}"
  }
  sensitive = true
}

output "application_urls" {
  description = "URLs for accessing the applications"
  value = {
    ui        = "https://app.${var.domain}"
    keycloak  = "https://auth.${var.domain}"
    services  = "https://services.${var.domain}"
  }
}

output "agent_configuration" {
  description = "Agent configuration details"
  value = {
    token = module.applications.agent_token
  }
  sensitive = true
}

output "database_passwords" {
  description = "Database passwords"
  value = {
    mongodb = module.dependencies.mongodb_password
    redis   = module.dependencies.redis_password
  }
  sensitive = true
}

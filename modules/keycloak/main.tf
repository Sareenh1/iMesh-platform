# This module now primarily handles Keycloak configuration
# The actual deployment is in dependencies module

output "keycloak_admin_password" {
  description = "Keycloak admin password"
  value       = var.keycloak_admin_password
  sensitive   = true
}

output "keycloak_url" {
  description = "Keycloak URL"
  value       = "https://auth.${var.domain}"
}

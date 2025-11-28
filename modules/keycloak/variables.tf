variable "domain" {
  description = "Base domain"
  type        = string
}

variable "keycloak_admin_user" {
  description = "Keycloak admin username"
  type        = string
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
}

variable "storage_class" {
  description = "Storage class"
  type        = string
}

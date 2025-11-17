variable "namespace" {
  description = "Namespace for Keycloak"
  type        = string
}

variable "domain" {
  description = "Base domain"
  type        = string
}

variable "admin_user" {
  description = "Keycloak admin username"
  type        = string
}

variable "admin_pass" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
}

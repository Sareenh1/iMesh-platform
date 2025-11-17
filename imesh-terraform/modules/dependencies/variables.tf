variable "namespace" {
  description = "Namespace for dependencies"
  type        = string
}

variable "keycloak_admin" {
  description = "Keycloak admin credentials"
  type = object({
    username = string
    password = string
  })
  sensitive = true
}

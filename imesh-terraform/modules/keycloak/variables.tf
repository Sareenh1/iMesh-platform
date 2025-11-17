variable "namespace" {
  description = "Namespace for Keycloak"
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

variable "realm_config" {
  description = "Keycloak realm configuration"
  type = object({
    name         = string
    display_name = string
  })
}

variable "clients" {
  description = "Keycloak clients configuration"
  type = map(object({
    client_id     = string
    public_client = bool
    redirect_uris = list(string)
    web_origins   = list(string)
  }))
}

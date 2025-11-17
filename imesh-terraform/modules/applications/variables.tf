variable "namespace" {
  description = "Namespace for applications"
  type        = string
}

variable "docker_registry" {
  description = "Docker registry credentials"
  type = object({
    server   = string
    username = string
    password = string
    email    = string
  })
}

variable "keycloak_config" {
  description = "Keycloak configuration"
  type = object({
    url                   = string
    realm                 = string
    graphql_client_secret = string
  })
}

variable "dependencies" {
  description = "Dependencies configuration"
  type = object({
    mongodb_url = string
    redis_url   = string
    nats_url    = string
  })
}

variable "domain" {
  description = "Base domain"
  type        = string
  default     = "dev.imesh.ai"
}

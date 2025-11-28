variable "domain" {
  description = "Base domain"
  type        = string
}

variable "docker_registry" {
  description = "Docker registry"
  type        = string
}

variable "keycloak_client_secret" {
  description = "Keycloak client secret"
  type        = string
  sensitive   = true
}

variable "agent_token" {
  description = "Agent token"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Cluster name"
  type        = string
}

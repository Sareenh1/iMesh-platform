variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "imesh-dev"
}

variable "domain" {
  description = "Base domain for the platform"
  type        = string
  default     = "dev.imesh.ai"
}

variable "docker_registry" {
  description = "Docker registry credentials"
  type = object({
    server   = string
    username = string
    password = string
    email    = string
  })
  default = {
    server   = "gcr.imesh.ai"
    username = "pulak.das@imesh.ai"
    password = "f82f8317aed4fd7fcad9b969350f5771aacf9f34"
    email    = "pulak.das@imesh.ai"
  }
  sensitive = true
}

variable "keycloak_admin" {
  description = "Keycloak admin credentials"
  type = object({
    username = string
    password = string
  })
  default = {
    username = "admin"
    password = "Wuas#CK4dr6E44YYg!d"
  }
  sensitive = true
}

variable "agent_token" {
  description = "Agent token for cluster registration"
  type        = string
  default     = "*BUBj0ovg/.aW1lc2guYWk="
  sensitive   = true
}

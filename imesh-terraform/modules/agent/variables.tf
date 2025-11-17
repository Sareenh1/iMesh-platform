variable "namespace" {
  description = "Namespace for agent"
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
  sensitive = true
}

variable "cluster_name" {
  description = "Cluster name"
  type        = string
}

variable "agent_token" {
  description = "Agent token"
  type        = string
  sensitive   = true
}

variable "dependencies" {
  description = "Dependencies configuration"
  type = object({
    nats_url = string
  })
}

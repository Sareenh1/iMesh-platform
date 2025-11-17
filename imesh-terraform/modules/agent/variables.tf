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
}

variable "cluster_name" {
  description = "Cluster name"
  type        = string
}

variable "dependencies" {
  description = "Dependencies configuration"
  type = object({
    nats_url = string
  })
}

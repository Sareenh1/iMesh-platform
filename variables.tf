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
  description = "Docker registry URL"
  type        = string
  default     = "gcr.imesh.ai"
}

variable "docker_username" {
  description = "Docker registry username"
  type        = string
  default     = "pulak.das@imesh.ai"
}

variable "docker_password" {
  description = "Docker registry password"
  type        = string
  sensitive   = true
}

variable "keycloak_admin_user" {
  description = "Keycloak admin username"
  type        = string
  default     = "admin"
}

variable "email" {
  description = "Email for Let's Encrypt certificates"
  type        = string
  default     = "pulak.das@imesh.ai"
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "civo-volume"
}

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
}

variable "keycloak_realm" {
  description = "Keycloak realm configuration"
  type = object({
    name        = string
    display_name = string
  })
  default = {
    name        = "istio-manager"
    display_name = "Istio Manager"
  }
}

variable "keycloak_clients" {
  description = "Keycloak clients configuration"
  type = map(object({
    client_id    = string
    public_client = bool
    redirect_uris = list(string)
    web_origins  = list(string)
  }))
  default = {
    ui = {
      client_id    = "ui"
      public_client = true
      redirect_uris = ["https://app.dev.imesh.ai/*"]
      web_origins  = ["*"]
    }
    graphql_backend = {
      client_id    = "graphql-backend"
      public_client = false
      redirect_uris = []
      web_origins  = []
    }
  }
}

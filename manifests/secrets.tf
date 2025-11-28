variable "docker_registry" {
  type = string
}

variable "docker_username" {
  type = string
}

variable "docker_password" {
  type      = string
  sensitive = true
}

# Docker registry secrets
resource "kubernetes_secret" "forgejo_creds_v2" {
  metadata {
    name      = "forgejo-creds"
    namespace = "v2"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (var.docker_registry) = {
          username = var.docker_username
          password = var.docker_password
          auth     = base64encode("${var.docker_username}:${var.docker_password}")
        }
      }
    })
  }
}

resource "kubernetes_secret" "forgejo_creds_v2_agent" {
  metadata {
    name      = "forgejo-creds"
    namespace = "v2-agent"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (var.docker_registry) = {
          username = var.docker_username
          password = var.docker_password
          auth     = base64encode("${var.docker_username}:${var.docker_password}")
        }
      }
    })
  }
}

resource "kubernetes_secret" "docker_registry" {
  metadata {
    name      = "forgejo-creds"
    namespace = var.namespace
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.docker_registry.server}" = {
          username = var.docker_registry.username
          password = var.docker_registry.password
          email    = var.docker_registry.email
          auth     = base64encode("${var.docker_registry.username}:${var.docker_registry.password}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}

# GraphQL Backend
resource "kubernetes_service_account" "graphql_backend" {
  metadata {
    name      = "graphql-backend"
    namespace = var.namespace
  }
}

resource "kubernetes_service" "graphql_backend" {
  metadata {
    name      = "graphql-backend"
    namespace = var.namespace
    labels = {
      app     = "graphql-backend"
      service = "graphql-backend"
    }
  }

  spec {
    selector = {
      app = "graphql-backend"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 3000
    }
  }
}

resource "kubernetes_deployment" "graphql_backend" {
  metadata {
    name      = "graphql-backend"
    namespace = var.namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app     = "graphql-backend"
        version = "v1"
      }
    }

    template {
      metadata {
        labels = {
          app     = "graphql-backend"
          version = "v1"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.graphql_backend.metadata[0].name
        
        image_pull_secrets {
          name = kubernetes_secret.docker_registry.metadata[0].name
        }

        container {
          name  = "graphql-backend"
          image = "gcr.imesh.ai/imesh-v2/backend-graphql:v2.0001"
          image_pull_policy = "Always"

          port {
            container_port = 3000
          }

          env {
            name  = "NODE_ENV"
            value = "development"
          }

          env {
            name  = "GRAPHQL_PLAYGROUND"
            value = "true"
          }

          env {
            name  = "MONGO_URI"
            value = var.dependencies.mongodb_url
          }

          env {
            name  = "MONGO_URI_CONNECTOR"
            value = ""
          }

          env {
            name  = "REDIS_URI"
            value = var.dependencies.redis_url
          }

          env {
            name  = "REDIS_PORT"
            value = "6379"
          }

          env {
            name  = "KEYCLOAK_AUTH_SERVER_URL"
            value = var.keycloak_config.url
          }

          env {
            name  = "KEYCLOAK_REALM"
            value = var.keycloak_config.realm
          }

          env {
            name  = "KEYCLOAK_AUTH_CLIENT_ID"
            value = "graphql-backend"
          }

          env {
            name  = "KEYCLOAK_AUTH_CLIENT_SECRET"
            value = var.keycloak_config.graphql_client_secret
          }

          env {
            name  = "CLUSTER_BACKEND_URL"
            value = "http://cluster-backend.${var.namespace}.svc.cluster.local"
          }
        }
      }
    }
  }
}

# UI Application
resource "kubernetes_service_account" "ui" {
  metadata {
    name      = "ui"
    namespace = var.namespace
  }
}

resource "kubernetes_service" "ui" {
  metadata {
    name      = "ui"
    namespace = var.namespace
    labels = {
      app     = "ui"
      service = "ui"
    }
  }

  spec {
    selector = {
      app = "ui"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 3000
    }
  }
}

resource "kubernetes_deployment" "ui" {
  metadata {
    name      = "ui"
    namespace = var.namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app     = "ui"
        version = "v1"
      }
    }

    template {
      metadata {
        labels = {
          app     = "ui"
          version = "v1"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.ui.metadata[0].name
        
        image_pull_secrets {
          name = kubernetes_secret.docker_registry.metadata[0].name
        }

        container {
          name  = "ui"
          image = "gcr.imesh.ai/imesh-v3/ui:v2.0001"
          image_pull_policy = "Always"

          port {
            container_port = 3000
          }

          env {
            name  = "GRAPHQL_BACKEND"
            value = "http://graphql-backend.${var.namespace}.svc.cluster.local/graphql"
          }

          env {
            name  = "NEXT_PUBLIC_KEYCLOAK_URL"
            value = "https://auth.${var.domain}/"
          }

          env {
            name  = "NEXT_PUBLIC_KEYCLOAK_REALM"
            value = "istio-manager"
          }

          env {
            name  = "NEXT_PUBLIC_KEYCLOAK_CLIENT_ID"
            value = "ui"
          }
        }
      }
    }
  }
}

# Cluster Backend
resource "kubernetes_service_account" "cluster_backend" {
  metadata {
    name      = "cluster-backend"
    namespace = var.namespace
  }
}

resource "kubernetes_service" "cluster_backend" {
  metadata {
    name      = "cluster-backend"
    namespace = var.namespace
    labels = {
      app     = "cluster-backend"
      service = "cluster-backend"
    }
  }

  spec {
    selector = {
      app = "cluster-backend"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 9090
    }
  }
}

resource "kubernetes_deployment" "cluster_backend" {
  metadata {
    name      = "cluster-backend"
    namespace = var.namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app     = "cluster-backend"
        version = "v1"
      }
    }

    template {
      metadata {
        labels = {
          app     = "cluster-backend"
          version = "v1"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.cluster_backend.metadata[0].name
        
        image_pull_secrets {
          name = kubernetes_secret.docker_registry.metadata[0].name
        }

        container {
          name  = "cluster-backend"
          image = "gcr.imesh.ai/imesh-v2/backend-cluster:v2.0001"
          image_pull_policy = "Always"

          port {
            container_port = 9090
          }

          env {
            name  = "MANAGEMENT_SERVICE"
            value = "http://graphql-backend.${var.namespace}.svc.cluster.local/graphql"
          }

          env {
            name  = "MONGO_URI"
            value = "${var.dependencies.mongodb_url}:27017"
          }

          env {
            name  = "HTTP_LISTENING_ADDRESS"
            value = "0.0.0.0"
          }

          env {
            name  = "HTTP_LISTENING_PORT"
            value = "9090"
          }

          env {
            name  = "NATS_URL"
            value = var.dependencies.nats_url
          }
        }
      }
    }
  }
}

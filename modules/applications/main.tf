resource "kubernetes_namespace" "v2" {
  metadata {
    name = "v2"
  }
}

resource "kubernetes_namespace" "v2_agent" {
  metadata {
    name = "v2-agent"
  }
}

# UI Deployment
resource "kubernetes_deployment_v1" "ui" {
  metadata {
    name      = "ui"
    namespace = kubernetes_namespace.v2.metadata[0].name
    labels = {
      app     = "ui"
      version = "v1"
    }
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
        service_account_name = "ui"
        image_pull_secrets {
          name = "forgejo-creds"
        }

        container {
          name  = "ui"
          image = "${var.docker_registry}/imesh-v3/ui:v2.0001"
          image_pull_policy = "Always"

          env {
            name  = "GRAPHQL_BACKEND"
            value = "http://graphql-backend.v2.svc.cluster.local/graphql"
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

          port {
            container_port = 3000
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.v2]
}

resource "kubernetes_service_v1" "ui" {
  metadata {
    name      = "ui"
    namespace = kubernetes_namespace.v2.metadata[0].name
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

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment_v1.ui]
}

resource "kubernetes_service_account_v1" "ui" {
  metadata {
    name      = "ui"
    namespace = kubernetes_namespace.v2.metadata[0].name
  }
}

# GraphQL Backend Deployment
resource "kubernetes_deployment_v1" "graphql_backend" {
  metadata {
    name      = "graphql-backend"
    namespace = kubernetes_namespace.v2.metadata[0].name
    labels = {
      app     = "graphql-backend"
      version = "v1"
    }
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
        service_account_name = "graphql-backend"
        image_pull_secrets {
          name = "forgejo-creds"
        }

        container {
          name  = "graphql-backend"
          image = "${var.docker_registry}/imesh-v2/backend-graphql:v2.0001"
          image_pull_policy = "Always"

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
            value = "mongodb://mongodb.v2-deps.svc.cluster.local"
          }

          env {
            name  = "MONGO_URI_CONNECTOR"
            value = ""
          }

          env {
            name  = "REDIS_URI"
            value = "redis-master.v2-deps.svc.cluster.local"
          }

          env {
            name  = "REDIS_PORT"
            value = "6379"
          }

          env {
            name  = "KEYCLOAK_AUTH_SERVER_URL"
            value = "http://keycloak.v2-deps.svc.cluster.local"
          }

          env {
            name  = "KEYCLOAK_REALM"
            value = "master"
          }

          env {
            name  = "KEYCLOAK_AUTH_CLIENT_ID"
            value = "graphql-backend"
          }

          env {
            name  = "KEYCLOAK_AUTH_CLIENT_SECRET"
            value = var.keycloak_client_secret
          }

          env {
            name  = "CLUSTER_BACKEND_URL"
            value = "http://cluster-backend.v2.svc.cluster.local"
          }

          port {
            container_port = 3000
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.v2]
}

resource "kubernetes_service_v1" "graphql_backend" {
  metadata {
    name      = "graphql-backend"
    namespace = kubernetes_namespace.v2.metadata[0].name
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

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment_v1.graphql_backend]
}

resource "kubernetes_service_account_v1" "graphql_backend" {
  metadata {
    name      = "graphql-backend"
    namespace = kubernetes_namespace.v2.metadata[0].name
  }
}

# Cluster Backend Deployment
resource "kubernetes_deployment_v1" "cluster_backend" {
  metadata {
    name      = "cluster-backend"
    namespace = kubernetes_namespace.v2.metadata[0].name
    labels = {
      app     = "cluster-backend"
      version = "v1"
    }
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
        service_account_name = "cluster-backend"
        image_pull_secrets {
          name = "forgejo-creds"
        }

        container {
          name  = "cluster-backend"
          image = "${var.docker_registry}/imesh-v2/backend-cluster:v2.0001"
          image_pull_policy = "Always"

          env {
            name  = "MANAGEMENT_SERVICE"
            value = "http://graphql-backend.v2.svc.cluster.local/graphql"
          }

          env {
            name  = "MONGO_URI"
            value = "mongodb://mongodb.v2-deps.svc.cluster.local:27017"
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
            value = "nats://nats.v2-deps.svc.cluster.local:4222"
          }

          port {
            container_port = 9090
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.v2]
}

resource "kubernetes_service_v1" "cluster_backend" {
  metadata {
    name      = "cluster-backend"
    namespace = kubernetes_namespace.v2.metadata[0].name
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

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment_v1.cluster_backend]
}

resource "kubernetes_service_account_v1" "cluster_backend" {
  metadata {
    name      = "cluster-backend"
    namespace = kubernetes_namespace.v2.metadata[0].name
  }
}

# Agent Deployment
resource "kubernetes_deployment_v1" "agent" {
  metadata {
    name      = "agent"
    namespace = kubernetes_namespace.v2_agent.metadata[0].name
    labels = {
      app     = "agent"
      version = "v1"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app     = "agent"
        version = "v1"
      }
    }

    template {
      metadata {
        labels = {
          app     = "agent"
          version = "v1"
        }
      }

      spec {
        service_account_name = "agent"
        image_pull_secrets {
          name = "forgejo-creds"
        }

        container {
          name  = "agent"
          image = "${var.docker_registry}/imesh-v2/agent:v2.0001"
          image_pull_policy = "Always"

          env {
            name  = "LOG_LEVEL"
            value = "DEBUG"
          }

          env {
            name  = "PROMETHEUS_URL"
            value = "http://prometheus.istio-system.svc.cluster.local:9090"
          }

          env {
            name  = "NATS_URL"
            value = "nats://nats.v2-deps.svc.cluster.local"
          }

          env {
            name  = "AGENT_TOKEN"
            value = var.agent_token
          }

          env {
            name  = "CLUSTER_NAME"
            value = var.cluster_name
          }

          port {
            container_port = 3000
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.v2_agent]
}

resource "kubernetes_service_v1" "agent" {
  metadata {
    name      = "agent"
    namespace = kubernetes_namespace.v2_agent.metadata[0].name
    labels = {
      app     = "agent"
      service = "agent"
    }
  }

  spec {
    selector = {
      app = "agent"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 3000
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment_v1.agent]
}

resource "kubernetes_service_account_v1" "agent" {
  metadata {
    name      = "agent"
    namespace = kubernetes_namespace.v2_agent.metadata[0].name
  }
}

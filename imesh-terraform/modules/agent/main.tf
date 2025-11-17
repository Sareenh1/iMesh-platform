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

resource "kubernetes_service_account" "agent" {
  metadata {
    name      = "agent"
    namespace = var.namespace
  }
}

resource "kubernetes_service" "agent" {
  metadata {
    name      = "agent"
    namespace = var.namespace
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
  }
}

resource "kubernetes_deployment" "agent" {
  metadata {
    name      = "agent"
    namespace = var.namespace
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
        service_account_name = kubernetes_service_account.agent.metadata[0].name
        
        image_pull_secrets {
          name = kubernetes_secret.docker_registry.metadata[0].name
        }

        container {
          name  = "agent"
          image = "gcr.imesh.ai/imesh-v2/agent:v2.0001"
          image_pull_policy = "Always"

          port {
            container_port = 3000
          }

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
            value = var.dependencies.nats_url
          }

          env {
            name  = "AGENT_TOKEN"
            value = var.agent_token
          }

          env {
            name  = "CLUSTER_NAME"
            value = var.cluster_name
          }
        }
      }
    }
  }
}

resource "kubernetes_cluster_role" "imesh_agent" {
  metadata {
    name = "imesh-agent"
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services"]
    verbs      = ["list"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["list"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["list"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
    verbs      = ["get"]
  }

  rule {
    api_groups = ["telemetry.istio.io"]
    resources  = ["telemetries"]
    verbs      = ["get", "create", "delete"]
  }

  rule {
    api_groups = ["networking.istio.io"]
    resources  = ["virtualservices", "destinationrules"]
    verbs      = ["list"]
  }
}

resource "kubernetes_cluster_role_binding" "imesh_agent" {
  metadata {
    name = "imesh-agent"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.imesh_agent.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.agent.metadata[0].name
    namespace = var.namespace
  }
}

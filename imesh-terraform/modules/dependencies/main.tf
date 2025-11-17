# MongoDB with explicit repository
resource "helm_release" "mongodb" {
  name       = "mongodb"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mongodb"
  namespace  = var.namespace
  version    = "14.4.3"  # Use a stable version
  timeout    = 600  # Increase timeout

  set {
    name  = "architecture"
    value = "standalone"
  }

  set {
    name  = "auth.enabled"
    value = "false"
  }

  set {
    name  = "persistence.enabled"
    value = "false"  # Disable persistence for testing
  }

  wait = true
}

# Redis with explicit repository
resource "helm_release" "redis" {
  name       = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  namespace  = var.namespace
  version    = "18.2.0"  # Use a stable version
  timeout    = 600

  set {
    name  = "architecture"
    value = "standalone"
  }

  set {
    name  = "auth.enabled"
    value = "false"
  }

  set {
    name  = "master.persistence.enabled"
    value = "false"  # Disable persistence for testing
  }

  wait = true

  depends_on = [helm_release.mongodb]
}

# NATS with explicit repository
resource "helm_release" "nats" {
  name       = "nats"
  repository = "https://nats-io.github.io/k8s/helm/charts/"
  chart      = "nats"
  namespace  = var.namespace
  version    = "0.19.9"  # Use a stable version
  timeout    = 600

  set {
    name  = "nats.port"
    value = "4222"
  }

  set {
    name  = "nats.jetstream.enabled"
    value = "false"  # Disable jetstream for simplicity
  }

  wait = true

  depends_on = [helm_release.redis]
}

# Simple Keycloak Deployment (not StatefulSet)
resource "kubernetes_deployment" "keycloak" {
  metadata {
    name      = "keycloak"
    namespace = var.namespace
    labels = {
      app = "keycloak"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "keycloak"
      }
    }

    template {
      metadata {
        labels = {
          app = "keycloak"
        }
      }

      spec {
        container {
          name  = "keycloak"
          image = "quay.io/keycloak/keycloak:22.0.0"  # Use stable version
          args  = ["start-dev"]
          
          env {
            name  = "KEYCLOAK_ADMIN"
            value = var.keycloak_admin.username
          }

          env {
            name  = "KEYCLOAK_ADMIN_PASSWORD"
            value = var.keycloak_admin.password
          }

          env {
            name  = "KC_HTTP_ENABLED"
            value = "true"  # Enable HTTP for simplicity
          }

          port {
            container_port = 8080
          }

          readiness_probe {
            http_get {
              path = "/realms/master"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/realms/master"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 30
          }
        }
      }
    }
  }

  depends_on = [helm_release.nats]
}

resource "kubernetes_service" "keycloak" {
  metadata {
    name      = "keycloak"
    namespace = var.namespace
    labels = {
      app = "keycloak"
    }
  }

  spec {
    selector = {
      app = "keycloak"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.keycloak]
}

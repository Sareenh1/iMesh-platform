resource "kubernetes_namespace" "v2_deps" {
  metadata {
    name = "v2-deps"
  }
}

# MongoDB
resource "helm_release" "mongodb" {
  name      = "mongodb"
  repository = "https://charts.bitnami.com/bitnami"
  chart     = "mongodb"
  namespace = kubernetes_namespace.v2_deps.metadata[0].name
  version   = "14.4.3"

  set {
    name  = "auth.rootPassword"
    value = var.mongodb_password
  }

  set {
    name  = "auth.username"
    value = "imesh"
  }

  set {
    name  = "auth.password"
    value = var.mongodb_password
  }

  set {
    name  = "auth.database"
    value = "imesh"
  }

  set {
    name  = "persistence.storageClass"
    value = var.storage_class
  }

  set {
    name  = "persistence.size"
    value = "8Gi"
  }

  depends_on = [kubernetes_namespace.v2_deps]
}

# Redis
resource "helm_release" "redis" {
  name      = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart     = "redis"
  namespace = kubernetes_namespace.v2_deps.metadata[0].name
  version   = "17.11.3"

  set {
    name  = "auth.password"
    value = var.redis_password
  }

  set {
    name  = "architecture"
    value = "standalone"
  }

  set {
    name  = "master.persistence.storageClass"
    value = var.storage_class
  }

  set {
    name  = "master.persistence.size"
    value = "4Gi"
  }

  depends_on = [kubernetes_namespace.v2_deps]
}

# NATS
resource "helm_release" "nats" {
  name      = "nats"
  repository = "https://nats-io.github.io/k8s/helm/charts/"
  chart     = "nats"
  namespace = kubernetes_namespace.v2_deps.metadata[0].name
  version   = "0.19.12"

  set {
    name  = "nats.image"
    value = "nats:2.9-alpine"
  }

  set {
    name  = "nats.jetstream.enabled"
    value = "true"
  }

  set {
    name  = "nats.jetstream.fileStorage.enabled"
    value = "true"
  }

  set {
    name  = "nats.jetstream.fileStorage.storageDirectory"
    value = "/data"
  }

  set {
    name  = "nats.jetstream.fileStorage.size"
    value = "4Gi"
  }

  set {
    name  = "nats.jetstream.fileStorage.storageClassName"
    value = var.storage_class
  }

  depends_on = [kubernetes_namespace.v2_deps]
}

# Keycloak StatefulSet
resource "kubernetes_stateful_set_v1" "keycloak" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.v2_deps.metadata[0].name
    labels = {
      app = "keycloak"
    }
  }

  spec {
    service_name = "keycloak"
    replicas     = 1

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
          image = "keycloak/keycloak:26.2.5"
          args  = ["start-dev", "--log-console-color=true", "--log-level=DEBUG"]

          env {
            name  = "KC_HTTP_ENABLED"
            value = "false"
          }

          env {
            name  = "KEYCLOAK_ADMIN"
            value = "admin"
          }

          env {
            name  = "KEYCLOAK_ADMIN_PASSWORD"
            value = var.keycloak_admin_password
          }

          env {
            name  = "KC_PROXY_HEADERS"
            value = "xforwarded"
          }

          env {
            name  = "KC_HOSTNAME"
            value = "https://auth.dev.imesh.ai/"
          }

          env {
            name  = "KC_HOSTNAME_BACKCHANNEL_DYNAMIC"
            value = "true"
          }

          port {
            container_port = 8080
            name           = "http"
            protocol       = "TCP"
          }

          readiness_probe {
            http_get {
              path = "/realms/master"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 1
            failure_threshold     = 3
          }

          volume_mount {
            name       = "keycloak-data"
            mount_path = "/opt/keycloak/data"
          }
        }

        security_context {
          fs_group = 1001
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "keycloak-data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "2Gi"
          }
        }
        storage_class_name = var.storage_class
      }
    }
  }

  depends_on = [kubernetes_namespace.v2_deps]
}

resource "kubernetes_service_v1" "keycloak" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.v2_deps.metadata[0].name
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
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_stateful_set_v1.keycloak]
}

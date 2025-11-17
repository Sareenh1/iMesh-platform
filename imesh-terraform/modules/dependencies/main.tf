resource "helm_release" "mongodb" {
  name       = "mongodb"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mongodb"
  namespace  = var.namespace
  version    = "13.18.2"

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
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = "8Gi"
  }
}

resource "helm_release" "redis" {
  name       = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  namespace  = var.namespace
  version    = "17.11.6"

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
    value = "true"
  }

  set {
    name  = "master.persistence.size"
    value = "4Gi"
  }
}

resource "helm_release" "nats" {
  name       = "nats"
  repository = "https://nats-io.github.io/k8s/helm/charts/"
  chart      = "nats"
  namespace  = var.namespace
  version    = "0.19.0"

  set {
    name  = "nats.port"
    value = "4222"
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
    name  = "nats.jetstream.fileStorage.size"
    value = "4Gi"
  }
}

resource "kubernetes_stateful_set" "keycloak" {
  metadata {
    name      = "keycloak"
    namespace = var.namespace
    labels = {
      app = "keycloak"
    }
  }

  spec {
    service_name = ""
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

          port {
            container_port = 8080
            name           = "http"
          }

          env {
            name  = "KC_HTTP_ENABLED"
            value = "false"
          }

          env {
            name  = "KEYCLOAK_ADMIN"
            value = var.keycloak_admin.username
          }

          env {
            name  = "KEYCLOAK_ADMIN_PASSWORD"
            value = var.keycloak_admin.password
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

          readiness_probe {
            http_get {
              path = "/realms/master"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 1
          }

          volume_mount {
            name       = "keycloak-persistent-storage"
            mount_path = "/opt/keycloak/data"
          }
        }

        volume {
          name = "keycloak-persistent-storage"
          persistent_volume_claim {
            claim_name = "keycloak-persistent-storage"
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "keycloak-persistent-storage"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "2Gi"
          }
        }
        storage_class_name = "civo-volume"
      }
    }
  }
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
}

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

resource "kubectl_manifest" "keycloak" {
  yaml_body = file("${path.module}/../../manifests/keycloak.yaml")
}

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

resource "kubectl_manifest" "graphql_backend" {
  yaml_body = templatefile("${path.module}/../../manifests/graphql-backend.yaml", {
    namespace           = var.namespace
    mongodb_url         = var.dependencies.mongodb_url
    redis_url           = var.dependencies.redis_url
    keycloak_url        = var.keycloak_config.url
    keycloak_realm      = var.keycloak_config.realm
    keycloak_secret     = var.keycloak_config.graphql_client_secret
    cluster_backend_url = "http://cluster-backend.${var.namespace}.svc.cluster.local"
  })

  depends_on = [kubernetes_secret.docker_registry]
}

resource "kubectl_manifest" "ui" {
  yaml_body = templatefile("${path.module}/../../manifests/ui.yaml", {
    namespace      = var.namespace
    graphql_backend = "http://graphql-backend.${var.namespace}.svc.cluster.local/graphql"
    keycloak_url   = "https://auth.${var.domain}"
    keycloak_realm = var.keycloak_config.realm
  })

  depends_on = [kubernetes_secret.docker_registry]
}

resource "kubectl_manifest" "cluster_backend" {
  yaml_body = templatefile("${path.module}/../../manifests/cluster-backend.yaml", {
    namespace       = var.namespace
    mongodb_url     = var.dependencies.mongodb_url
    nats_url        = var.dependencies.nats_url
    management_service = "http://graphql-backend.${var.namespace}.svc.cluster.local/graphql"
  })

  depends_on = [kubernetes_secret.docker_registry]
}

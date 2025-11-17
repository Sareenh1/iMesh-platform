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

resource "kubectl_manifest" "agent" {
  yaml_body = templatefile("${path.module}/../../manifests/agent.yaml", {
    namespace    = var.namespace
    nats_url     = var.dependencies.nats_url
    cluster_name = var.cluster_name
  })

  depends_on = [kubernetes_secret.docker_registry]
}

resource "kubectl_manifest" "cluster_role" {
  yaml_body = file("${path.module}/../../manifests/clusterrole.yaml")
}

resource "kubernetes_cluster_role_v1" "imesh_agent" {
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

resource "kubernetes_cluster_role_binding_v1" "imesh_agent" {
  metadata {
    name = "imesh-agent"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.imesh_agent.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "agent"
    namespace = "v2-agent"
  }
}

# Create namespaces
resource "kubernetes_namespace" "v2_deps" {
  metadata {
    name = "v2-deps"
  }
}

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

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_namespace" "envoy_gateway_system" {
  metadata {
    name = "envoy-gateway-system"
  }
}

resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

# Deploy modules in order
module "certificates" {
  source = "./modules/certificates"
  
  namespaces = {
    v2      = kubernetes_namespace.v2.metadata[0].name
    v2_deps = kubernetes_namespace.v2_deps.metadata[0].name
  }
  
  domain = var.domain
  email  = "pulak.das@imesh.ai"
}

module "dependencies" {
  source = "./modules/dependencies"
  
  namespace = kubernetes_namespace.v2_deps.metadata[0].name
  keycloak_admin = var.keycloak_admin
  
  depends_on = [
    kubernetes_namespace.v2_deps,
    module.certificates
  ]
}

module "keycloak" {
  source = "./modules/keycloak"
  
  namespace    = kubernetes_namespace.v2_deps.metadata[0].name
  domain       = var.domain
  admin_user   = var.keycloak_admin.username
  admin_pass   = var.keycloak_admin.password
  
  depends_on = [module.dependencies]
}

module "applications" {
  source = "./modules/applications"
  
  namespace = kubernetes_namespace.v2.metadata[0].name
  domain    = var.domain
  docker_registry = var.docker_registry
  
  keycloak_config = {
    url    = "http://keycloak.${kubernetes_namespace.v2_deps.metadata[0].name}.svc.cluster.local"
    realm  = "master"
    graphql_client_secret = module.keycloak.graphql_backend_secret
  }
  
  dependencies = {
    mongodb_url = "mongodb://mongodb.${kubernetes_namespace.v2_deps.metadata[0].name}.svc.cluster.local"
    redis_url   = "redis-master.${kubernetes_namespace.v2_deps.metadata[0].name}.svc.cluster.local"
    nats_url    = "nats://nats.${kubernetes_namespace.v2_deps.metadata[0].name}.svc.cluster.local:4222"
  }
  
  depends_on = [
    module.dependencies,
    module.keycloak,
    kubernetes_namespace.v2
  ]
}

module "agent" {
  source = "./modules/agent"
  
  namespace = kubernetes_namespace.v2_agent.metadata[0].name
  docker_registry = var.docker_registry
  cluster_name = var.cluster_name
  agent_token = var.agent_token
  
  dependencies = {
    nats_url = "nats://nats.${kubernetes_namespace.v2_deps.metadata[0].name}.svc.cluster.local"
  }
  
  depends_on = [
    module.dependencies,
    kubernetes_namespace.v2_agent
  ]
}

# Deploy gateways LAST after everything else is working
module "gateways" {
  source = "./modules/gateways"
  
  namespaces = {
    v2      = kubernetes_namespace.v2.metadata[0].name
    v2_deps = kubernetes_namespace.v2_deps.metadata[0].name
  }
  
  domain = var.domain
  
  depends_on = [
    module.certificates,
    module.dependencies,
    module.applications,
    module.agent,
    kubernetes_namespace.v2,
    kubernetes_namespace.v2_deps
  ]
}

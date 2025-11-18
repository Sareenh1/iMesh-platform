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

# Skip cert-manager namespace for now
/*
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}
*/

# Deploy dependencies using Kubernetes manifests (no Helm)
module "dependencies" {
  source = "./modules/dependencies"
  
  namespace = kubernetes_namespace.v2_deps.metadata[0].name
  keycloak_admin = var.keycloak_admin
  
  depends_on = [kubernetes_namespace.v2_deps]
}

# Deploy applications
module "applications" {
  source = "./modules/applications"
  
  namespace = kubernetes_namespace.v2.metadata[0].name
  domain    = var.domain
  docker_registry = var.docker_registry
  
  keycloak_config = {
    url    = "http://keycloak.${kubernetes_namespace.v2_deps.metadata[0].name}.svc.cluster.local"
    realm  = "master"
    graphql_client_secret = "temp-secret-12345"  # Temporary secret
  }
  
  dependencies = {
    mongodb_url = "mongodb://mongodb.${kubernetes_namespace.v2_deps.metadata[0].name}.svc.cluster.local:27017"
    redis_url   = "redis.${kubernetes_namespace.v2_deps.metadata[0].name}.svc.cluster.local"
    nats_url    = "nats://nats.${kubernetes_namespace.v2_deps.metadata[0].name}.svc.cluster.local:4222"
  }
  
  depends_on = [module.dependencies]
}

# Skip certificates and gateways for now
/*
module "certificates" {
  source = "./modules/certificates"
  # ...
}

module "gateways" {
  source = "./modules/gateways"
  # ...
}
*/

# Deploy agent
module "agent" {
  source = "./modules/agent"
  
  namespace = kubernetes_namespace.v2_agent.metadata[0].name
  docker_registry = var.docker_registry
  cluster_name = var.cluster_name
  agent_token = var.agent_token
  
  dependencies = {
    nats_url = "nats://nats.${kubernetes_namespace.v2_deps.metadata[0].name}.svc.cluster.local:4222"
  }
  
  depends_on = [module.dependencies]
}

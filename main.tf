# Generate random passwords and tokens
resource "random_password" "keycloak_admin_password" {
  length  = 20
  special = true
}

resource "random_password" "keycloak_client_secret" {
  length  = 32
  special = false
}

resource "random_password" "agent_token" {
  length  = 32
  special = true
}

resource "random_password" "mongodb_password" {
  length  = 16
  special = false
}

resource "random_password" "redis_password" {
  length  = 16
  special = false
}

# Create namespaces
module "namespaces" {
  source = "./manifests"
}

# Docker registry secrets
module "secrets" {
  source = "./manifests"

  docker_registry = var.docker_registry
  docker_username = var.docker_username
  docker_password = var.docker_password
  
  depends_on = [module.namespaces]
}

# Deploy Cert Manager
module "cert_manager" {
  source = "./modules/cert-manager"

  email = var.email
  
  depends_on = [module.namespaces]
}

# Deploy Dependencies
module "dependencies" {
  source = "./modules/dependencies"

  mongodb_password = random_password.mongodb_password.result
  redis_password   = random_password.redis_password.result
  storage_class    = var.storage_class
  keycloak_admin_password = random_password.keycloak_admin_password.result
  
  depends_on = [module.namespaces]
}

# Deploy Istio
module "istio" {
  source = "./modules/istio"
  
  depends_on = [module.namespaces]
}

# Deploy Envoy Gateway
module "envoy_gateway" {
  source = "./modules/envoy-gateway"
  
  depends_on = [module.namespaces]
}

# Deploy Keycloak
module "keycloak" {
  source = "./modules/keycloak"

  domain                 = var.domain
  keycloak_admin_user    = var.keycloak_admin_user
  keycloak_admin_password = random_password.keycloak_admin_password.result
  storage_class          = var.storage_class
  
  depends_on = [module.dependencies, module.namespaces]
}

# Deploy Networking
module "networking" {
  source = "./modules/networking"

  domain = var.domain
  
  depends_on = [
    module.cert_manager,
    module.envoy_gateway,
    module.istio
  ]
}

# Deploy Applications
module "applications" {
  source = "./modules/applications"

  domain                  = var.domain
  docker_registry         = var.docker_registry
  keycloak_client_secret  = random_password.keycloak_client_secret.result
  agent_token             = random_password.agent_token.result
  cluster_name            = var.cluster_name
  
  depends_on = [
    module.dependencies,
    module.networking,
    module.secrets
  ]
}

# Configure RBAC
module "rbac" {
  source = "./manifests"
  
  depends_on = [module.namespaces]
}

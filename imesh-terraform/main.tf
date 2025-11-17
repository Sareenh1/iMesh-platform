# In the dependencies module call in main.tf:
module "dependencies" {
  source = "./modules/dependencies"
  namespace = kubernetes_namespace.v2_deps.metadata[0].name
}

# In the applications module call in main.tf:
module "applications" {
  source = "./modules/applications"
  # ... existing variables ...
  
  dependencies = {
    mongodb_url = module.dependencies.mongodb_url
    redis_url   = module.dependencies.redis_url  
    nats_url    = module.dependencies.nats_url
  }
  
  keycloak_config = {
    url    = module.dependencies.keycloak_url
    realm  = var.keycloak_realm.name
    graphql_client_secret = module.keycloak.graphql_backend_secret
  }
}

# In the agent module call in main.tf:
module "agent" {
  source = "./modules/agent"
  # ... existing variables ...
  
  dependencies = {
    nats_url = module.dependencies.nats_url
  }
}

# In the keycloak module call in main.tf:
module "keycloak" {
  source = "./modules/keycloak"
  # ... existing variables ...
  
  depends_on = [module.dependencies]
}

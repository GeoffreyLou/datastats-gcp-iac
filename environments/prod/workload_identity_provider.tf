# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Context
# ----------------------------------------------------------------------------------------------------------------------

/*
  This module creates a "ready to deploy" Workload Identity Provider to run securly the CI/CD pipeline.
  You may have to apply manually this module in first place. 
  That's because the CI/CD service account will have no rights when the project is created. 

  Please run : terraform apply -target module.workload_identity_provider
*/


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Workload Identity Provider module
# ----------------------------------------------------------------------------------------------------------------------

module "workload_identity_provider" {
  source = "../../modules/workload-identity-provider"

  project_id                        = var.project_id
  region                            = var.region
  pool_name                         = var.pool_name
  pool_description                  = var.pool_description
  provider_name                     = var.provider_name
  provider_description              = var.provider_description
  assertion_condition               = var.assertion_condition
  assertion_value                   = var.assertion_value
  attribute_condition               = var.attribute_condition
  workload_identity_provider_issuer = var.workload_identity_provider_issuer
  service_account_roles             = var.workload_identity_provider_sa_roles
}

# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Secret output
# ----------------------------------------------------------------------------------------------------------------------

# Commented because Terraform is not able to create this secret ATM

/* resource "google_secret_manager_secret" "workload_identity_pool_secret" {
  project = var.project_id
  secret_id = "workload-identity-provider"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    } 
  } 

  labels = {
    env = var.env
  }
}

resource "google_secret_manager_secret_version" "workload_identity_pool_secret_version" {
  secret = google_secret_manager_secret.workload_identity_pool_secret.secret_id
  secret_data = module.workload_identity_provider.workload_identity_provider_name
} */
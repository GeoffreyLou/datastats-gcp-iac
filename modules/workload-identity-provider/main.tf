terraform {
  required_version = "~> 1.10.0"

  required_providers {
    google = {
      version = "~> 6.17.0"
      source  = "hashicorp/google"
    }
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Context
# ----------------------------------------------------------------------------------------------------------------------

/*
  This module creates a "ready to deploy" Workload Identity Provider.
  It includes the following resources:
    - Project APIs
    - Service Account
    - Service Account roles
    - Artifact Repository
    - Build and push a sample Docker image 
    - Cloud Run Job
*/

# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Required data
# ----------------------------------------------------------------------------------------------------------------------

data "google_project" "main" {
  project_id = var.project_id
}

# ----------------------------------------------------------------------------------------------------------------------
# 🟢 APIs
# ----------------------------------------------------------------------------------------------------------------------

resource "google_project_service" "main" {
  for_each           = toset([
    "run.googleapis.com"
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Workload Identity Pool and Provider
# ----------------------------------------------------------------------------------------------------------------------

resource "google_iam_workload_identity_pool" "main" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_name
  description               = var.pool_description
}

resource "google_iam_workload_identity_pool_provider" "main" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.main.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_name
  display_name                       = var.provider_description
  attribute_condition                = "${var.assertion_condition} == '${var.assertion_value}'"
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.aud"              = "assertion.aud"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }
  oidc {
    issuer_uri = var.workload_identity_provider_issuer
  }
}

# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Service Account
# ----------------------------------------------------------------------------------------------------------------------

resource "google_service_account" "main" {
  project      = var.project_id
  account_id   = "${var.project_id}-wip-sa"
  display_name = "Workload Identity Provider Service Account"
}

resource "google_project_iam_member" "main" {
  for_each = toset(var.service_account_roles)

  project = var.project_id 
  role    = each.key
  member  = "serviceAccount:${google_service_account.main.email}"
}

resource "google_service_account_iam_binding" "main" {
  service_account_id = google_service_account.main.name
  role               = "roles/iam.workloadIdentityUser"
  members            = [ 
    "principalSet://iam.googleapis.com/projects/${data.google_project.main.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.main.workload_identity_pool_id}/${var.attribute_condition}/${var.assertion_value}" 

  ]
}
# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Context
# ----------------------------------------------------------------------------------------------------------------------

/*
  This module creates a Bucket on the desired project

  Be aware that you set force destroy on false in [PROD] environment
*/


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Configuration
# ----------------------------------------------------------------------------------------------------------------------

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
# 🟢 APIs
# ----------------------------------------------------------------------------------------------------------------------

resource "google_project_service" "main" {
  for_each           = toset([
    "storage.googleapis.com"
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Bucket
# ----------------------------------------------------------------------------------------------------------------------

resource "google_storage_bucket" "main" {
  name                        = var.name 
  project                     = var.project_id 
  location                    = var.location 
  storage_class               = var.storage_class 
  uniform_bucket_level_access = var.uniform_bucket_level_access 
  force_destroy               = var.force_destroy 

  versioning {
    enabled = var.versioning
  }

  autoclass {
    enabled = var.autoclass 
  }

  labels = {
    env = var.env
  }
}
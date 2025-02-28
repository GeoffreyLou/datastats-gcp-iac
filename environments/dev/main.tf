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
# 🟢 Project APIs
# ----------------------------------------------------------------------------------------------------------------------

resource "google_project_service" "project_apis" {
  for_each           = toset(var.apis_to_enable)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

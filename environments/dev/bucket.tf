# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Context
# ----------------------------------------------------------------------------------------------------------------------

/*
  Datastats project will require several bucket used by resources
  Each bucket will be created with a dedicated module

  Outputs could be used in Cloud Run environment variables
*/

# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Utils bucket
# ----------------------------------------------------------------------------------------------------------------------

module "utils_bucket" {
  source        = "../../modules/bucket"
  name          = var.utils_bucket_name
  project_id    = var.project_id
  location      = var.region
  force_destroy = true
  versioning    = true
  autoclass     = false
  env           = var.env
}

# The default jobs list to scrap
resource "google_storage_bucket_object" "default_jobs_list" {
  bucket       = module.utils_bucket.name
  name         = "jobs_to_scrap.json"
  content_type = "application/json"
  source       = "../../data/jobs_to_scrap.json"
}

# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Urls bucket
# ----------------------------------------------------------------------------------------------------------------------

module "urls_bucket" {
  source = "../../modules/bucket"
  name          = var.urls_bucket_name
  project_id    = var.project_id
  location      = var.region
  force_destroy = true
  versioning    = true
  autoclass     = false
  env           = var.env
}

# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Archive bucket
# ----------------------------------------------------------------------------------------------------------------------

module "urls_bucket" {
  source = "../../modules/bucket"
  name          = var.urls_bucket_name
  project_id    = var.project_id
  location      = var.region
  force_destroy = true
  versioning    = true
  autoclass     = false
  env           = var.env
}
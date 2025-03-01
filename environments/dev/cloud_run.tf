# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Context
# ----------------------------------------------------------------------------------------------------------------------

/*
  This Cloud Run will be used to scrap URLs for each Data Job provided.

  Required env vars : 
  - JOB_TO_SCRAP           : provided with Cloud Workflows 
  - DATASTATS_BUCKET_UTILS : provided with Terraform 
  - DATASTATS_BUCKET_URLS  : provided with Terraform
  - URL_TO_SCRAP           : provided with Terraform

  Required secret vars : 
  - DB_ROOT_CERT : provided with Terraform as GCP secret
  - DB_CERT      : provided with Terraform as GCP secret
  - DB_KEY       : provided with Terraform as GCP secret

  To interact with Cloud SQL, it will require Cloud SQL SSL Certificate as secret env vars.
*/

# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Cloud Run Job
# ----------------------------------------------------------------------------------------------------------------------

module "run_job_urls_scrapper" {
  source = "../../modules/cloud-run"

  project_id            = var.project_id
  env                   = var.env
  region                = var.region
  job_name              = var.run_job_urls_scrapper_name
  deletion_protection   = false

  sa_roles = [
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
  ]

  env_vars = [ 
    { name  = "URL_TO_SCRAP",           value = var.url_to_scrap },
    { name  = "DATASTATS_BUCKET_UTILS", value = module.utils_bucket.name },
    { name  = "DATASTATS_BUCKET_URLS",  value = module.urls_bucket.name },
  ]

   secret_env_vars = [ 
    { name  = "DB_ROOT_CERT", secret_name = google_secret_manager_secret.ssl_cert.id },
    { name  = "DB_CERT",      secret_name = google_secret_manager_secret.ssl_server_ca_cert.id },
    { name  = "DB_KEY",       secret_name = google_secret_manager_secret.ssl_private_key.id },
  ]
}
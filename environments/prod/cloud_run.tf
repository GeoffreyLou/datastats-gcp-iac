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
  - DB_NAME                : provided with Terraform
  - DB_USER                : provided with Terraform
  - DB_PORT                : provided with Terraform
  - DB_HOST                : provided with Terraform

  Required secret vars : 
  - DB_ROOT_CERT           : provided with Terraform as GCP secret
  - DB_CERT                : provided with Terraform as GCP secret
  - DB_KEY                 : provided with Terraform as GCP secret
  - DB_USER_PASSWORD       : provided with Terraform as GCP secret
*/

# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Cloud Run Job
# ----------------------------------------------------------------------------------------------------------------------

module "run_job_urls_scrapper" {
  source = "../../modules/cloud-run"

  project_id                         = var.project_id
  env                                = var.env
  region                             = var.region
  job_name                           = var.run_job_urls_scrapper_name
  cloud_sql_instance_connection_name = [ google_sql_database_instance.datastats_sql.connection_name ]
  deletion_protection                = false
  sa_roles                           = [ 
    "roles/cloudsql.client", 
    "roles/secretmanager.secretAccessor",
    "roles/storage.objectUser"
  ]

  env_vars                           = [ 
    { name  = "URL_TO_SCRAP",             value = var.url_to_scrap },
    { name  = "DATASTATS_BUCKET_UTILS",   value = module.utils_bucket.name },
    { name  = "DATASTATS_BUCKET_URLS",    value = module.urls_bucket.name },
    { name  = "DB_NAME",                  value = google_sql_database.datastats_bdd.name },
    { name  = "DB_USER",                  value = google_sql_user.datastats_user.name },
    { name  = "DB_PORT",                  value = "5432" },
    { name  = "DB_HOST",                  value = google_sql_database_instance.datastats_sql.ip_address[0].ip_address },
  ]

   secret_env_vars                   = [ 
    { name  = "DB_ROOT_CERT",      secret_name = google_secret_manager_secret.ssl_server_ca_cert.id },
    { name  = "DB_CERT",           secret_name = google_secret_manager_secret.ssl_cert.id },
    { name  = "DB_KEY",            secret_name = google_secret_manager_secret.ssl_private_key.id },
    { name  = "DB_USER_PASSWORD",  secret_name = google_secret_manager_secret.user_password_secret.id }
  ]
}
# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Context
# ----------------------------------------------------------------------------------------------------------------------

/*
  This module creates a "ready to deploy" Cloud Run Job.
  It includes the following resources:
    - Project APIs
    - Service Account
    - Service Account roles
    - Artifact Repository
    - Build and push a sample Docker image 
    - Cloud Run Job

  Be aware to get Artifact Repository output for CI/CD purpose
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
    "run.googleapis.com",
    "iam.googleapis.com",
    "artifactregistry.googleapis.com",
  ])
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Artifact Repository
# ----------------------------------------------------------------------------------------------------------------------

resource "google_artifact_registry_repository" "main" {
  repository_id = "${var.job_name}-repository"
  project       = var.project_id
  location      = var.region
  description   = "${var.job_name} Artifact Registry Repository in [${var.env}]"
  format        = "DOCKER"
  labels        = {
    env = var.env
  }

  cleanup_policies {
    id     = "keep-latest"
    action = "KEEP"

    condition {
      tag_state    = "TAGGED"
      tag_prefixes = [ "latest" ]
    }
  }

  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"

    condition {
      tag_state    = "UNTAGGED"
    }
  }
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Service Account
# ----------------------------------------------------------------------------------------------------------------------

resource "google_service_account" "main" {
  account_id   = "${var.job_name}-sa"
  display_name = "${var.job_name} Cloud Run Service Account in [${var.env}]"
  project      = var.project_id
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Service Account roles
# ----------------------------------------------------------------------------------------------------------------------

resource "google_project_iam_member" "main" {
  for_each = toset(var.sa_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.main.email}"
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Deploy sample Docker image
# ----------------------------------------------------------------------------------------------------------------------

resource "null_resource" "deploy_sample_job" {
  depends_on = [ google_artifact_registry_repository.main ]

  provisioner "local-exec" {
    command = "docker build -t ${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.name}/${var.job_name}:latest ../../modules/cloud-run/sample/. && docker push ${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.name}/${var.job_name}:latest"
  }
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Cloud Run
# ----------------------------------------------------------------------------------------------------------------------

resource "google_cloud_run_v2_job" "main" {
  depends_on = [ 
    null_resource.deploy_sample_job,
    google_project_iam_member.main
  ]

  project             = var.project_id
  location            = var.region
  name                = var.job_name
  deletion_protection = var.deletion_protection

  labels = {
    "env" = var.env
  }

  template {

    labels = {
      env = var.env
    }

    template {
      service_account = google_service_account.main.email
      timeout         = var.timeout
      max_retries     = var.max_retries

      vpc_access {
        egress = var.egress
        network_interfaces {
          network    = var.network_name 
          subnetwork = var.subnetwork_name 
          tags       = var.vpc_access_tags
        }
      }

      volumes {
        name = length(var.cloud_sql_instance_connection_name) > 0 ? "cloudsql" : null
        cloud_sql_instance {
          instances = var.cloud_sql_instance_connection_name
        }
      }


      containers {
        image   = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.main.name}/${var.job_name}:latest"
        command = var.command
        args    = var.args

        volume_mounts {
          name       = length(var.cloud_sql_instance_connection_name) > 0 ? "cloudsql" : null
          mount_path = length(var.cloud_sql_instance_connection_name) > 0 ? "/cloudsql" : null
        }

        resources {
          limits = {
            cpu    = var.cpu
            memory = var.memory
          }
        }

        dynamic "env" {
          for_each = var.env_vars
          content {
            name  = env.value.name
            value = env.value.value
          }
        }

        dynamic "env" {
          for_each = var.secret_env_vars
          content {
            name  = env.value.name
            value_source {
              secret_key_ref {
                secret  = env.value.secret_name
                version = "latest"
              }
            }
          }
        }
      }
    }
  }
}
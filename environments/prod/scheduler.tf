# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Context
# ----------------------------------------------------------------------------------------------------------------------

/*
  The scheduler is used to trigger workflows.
  One workflow can be triggered once a day or more according to its purpose. 
*/

# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Service account and roles
# ----------------------------------------------------------------------------------------------------------------------

resource "google_service_account" "scheduler_sa" {
  project      = var.project_id
  account_id   = "${var.project_name}-scheduler-sa"
  display_name = "Scheduler Service Account"
}

resource "google_project_iam_member" "scheduler_sa_roles" {
  for_each = toset([
    "roles/workflows.invoker",
    "roles/logging.logWriter"
  ])
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.scheduler_sa.email}"
}


# ----------------------------------------------------------------------------------------------------------------------
# 🟢 Urls scrapper workflow Scheduler
# ----------------------------------------------------------------------------------------------------------------------

resource "google_cloud_scheduler_job" "urls_scrapper_workflow_scheduler" {
  for_each = var.urls_scrapper_workflow_schedules

  name        = each.key
  project     = var.project_id
  description = "Scheduler used to trigger the Urls Scrapper Cloud Run Job"
  region      = var.scheduler_region
  schedule    = each.value
  time_zone   = "Etc/UTC"

  http_target {
    uri         = "https://workflowexecutions.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.urls_scrapper_workflow.name}/executions"
    http_method = "POST"
    headers = {
      "Content-Type" = "application/octet-stream",
      "User-Agent"   = "Google-Cloud-Scheduler"
    }

    oauth_token {
      service_account_email = google_service_account.scheduler_sa.email
    }
  }
}
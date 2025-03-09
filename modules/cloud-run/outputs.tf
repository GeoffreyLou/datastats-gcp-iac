output "artifact_repository_name" {
  description = "The name of the Artifact Repository to be used in CI/CD"
  value       = google_artifact_registry_repository.main.name
}

output "service_account_email" {
  description = "The email of the Service Account related to this Cloud Run"
  value       = google_service_account.main.email
}

output "cloud_run_job_name" {
  description = "The name of the Cloud Run Job"
  value       = google_cloud_run_v2_job.main.name
}
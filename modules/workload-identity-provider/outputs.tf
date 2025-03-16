output "workload_identity_provider_name" {
  description = "The name of the Workload Identity Pool Provider"
  value       = google_iam_workload_identity_pool_provider.main.name
}

output "workload_identity_provider_sa_email" {
  description = "The email of the Workload Identity Pool Provider Service account"
  value       = google_service_account.main.email
}
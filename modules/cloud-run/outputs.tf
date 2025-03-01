output "artifact_repository_name" {
  description = "The name of the Artifact Repository to be used in CI/CD"
  value       = google_artifact_registry_repository.main.name
}
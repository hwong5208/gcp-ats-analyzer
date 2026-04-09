output "cloud_run_service_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.app.uri
}

output "service_account_email" {
  description = "Email of the service account used by Cloud Run"
  value       = google_service_account.app_sa.email
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository path"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}"
}

output "cloud_run_service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_v2_service.app.name
}

output "docker_image_path" {
  description = "Full path for Docker image in Artifact Registry"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repository}/${var.app_name}"
}

# ============================================================================
# Enable Required APIs
# ============================================================================

resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "aiplatform.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

# ============================================================================
# Service Account
# ============================================================================

resource "google_service_account" "app_sa" {
  account_id   = "${var.app_name}-${var.environment}"
  display_name = "Service account for ${var.app_name} (${var.environment})"
  description  = "Used by Cloud Run service for ${var.app_name}"
}

# Grant Vertex AI API user role (for Cloud Run to call Gemini model)
resource "google_project_iam_member" "vertex_ai_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

# Grant Cloud Logging writer role
resource "google_project_iam_member" "logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

# Grant Cloud Monitoring metric writer role
resource "google_project_iam_member" "monitoring_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

# ============================================================================
# Artifact Registry Repository (Docker)
# ============================================================================

resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = var.artifact_registry_repository
  description   = "Docker registry for ${var.app_name} (${var.environment})"
  format        = "DOCKER"

  depends_on = [google_project_service.required_apis["artifactregistry.googleapis.com"]]
}

# ============================================================================
# Cloud Run Service
# ============================================================================

resource "google_cloud_run_v2_service" "app" {
  name     = "${var.app_name}-${var.environment}"
  location = var.region

  template {
    service_account = google_service_account.app_sa.email

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_repository}/${var.app_name}:latest"

      # Cloud Run requires port to be set
      ports {
        container_port = 8000
      }

      # Environment variables
      env {
        name  = "GCP_PROJECT_ID"
        value = var.project_id
      }

      env {
        name  = "GCP_REGION"
        value = var.region
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      # Resource limits
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      # Startup probe
      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 24

        http_get {
          path = "/health"
          port = 8000
        }
      }

      # Liveness probe
      liveness_probe {
        initial_delay_seconds = 10
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 3

        http_get {
          path = "/health"
          port = 8000
        }
      }
    }

    # Scaling configuration
    scaling {
      min_instance_count = var.cloud_run_min_instances
      max_instance_count = var.cloud_run_max_instances
    }

    # Timeout for requests
    timeout = "60s"
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [
    google_project_service.required_apis["run.googleapis.com"],
    google_project_service.required_apis["aiplatform.googleapis.com"],
  ]
}

# ============================================================================
# Allow Unauthenticated Access to Cloud Run Service
# ============================================================================

resource "google_cloud_run_service_iam_member" "unauthenticated" {
  service    = google_cloud_run_v2_service.app.name
  location   = google_cloud_run_v2_service.app.location
  role       = "roles/run.invoker"
  member     = "allUsers"
  depends_on = [google_cloud_run_v2_service.app]
}

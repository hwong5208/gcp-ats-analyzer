terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Uncomment the backend configuration when you're ready to use remote state
  # backend "gcs" {
  #   bucket = "your-terraform-state-bucket"
  #   prefix = "gcp-ats-analyzer/phase1"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

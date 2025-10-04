terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.6.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_iam_member" "collaborators" {
  for_each = toset(var.collaborators_emails)
  project  = var.project_id
  role     = "roles/editor"
  member   = "user:${each.value}"
}

resource "google_project_iam_member" "teacher" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "user:${var.teacher_email}"
}
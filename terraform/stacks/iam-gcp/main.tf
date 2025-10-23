terraform {
  backend "gcs" {}
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

# -----------------------------
# GCP Project IAM - Collaborators
# -----------------------------

resource "google_project_iam_member" "collaborators" {
  for_each = toset(var.collaborators_emails)
  project  = var.project_id
  role     = "roles/editor"
  member   = "user:${each.value}"
}

# -----------------------------
# GCP Project IAM - Teacher
# -----------------------------

resource "google_project_iam_member" "teacher" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "user:${var.teacher_email}"
}

# -----------------------------
# Terraform Service Account
# -----------------------------

resource "google_service_account" "terraform" {
  account_id   = "terraform-sa"
  display_name = "Terraform Service Account"
}

resource "google_project_iam_member" "terraform_sa_secret_access" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_project_iam_member" "terraform_sa_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

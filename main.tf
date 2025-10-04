terraform {
  backend "gcs" {}
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0" # version stable récente
    }
  }
  required_version = ">= 1.6.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# -----------------------------
# Service enabler
# -----------------------------
resource "google_project_service" "compute" {
  project = var.project_id
  service = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "storage.googleapis.com"
  ]

  disable_on_destroy = true # désactive l'API si tu fais terraform destroy
}

resource "google_compute_network" "gpc_vpc" {
  name                    = "test-network"
  auto_create_subnetworks = false

  depends_on = [google_project_service.compute]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "main-subnet"
  region        = var.region
  network       = google_compute_network.gpc_vpc.id
  ip_cidr_range = var.subnet_cidr

  depends_on = [google_project_service.compute]
}

resource "google_storage_bucket" "demo" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
}

# -----------------------------
# Outputs
# -----------------------------
output "vpc_id" {
  value       = google_compute_network.gpc_vpc.id
  description = "The ID of the created VPC"
}

output "subnet_id" {
  value       = google_compute_subnetwork.subnet.id
  description = "The ID of the created subnet"
}

output "bucket_name" {
  value       = google_storage_bucket.demo.name
  description = "The name of the created GCS bucket"
}
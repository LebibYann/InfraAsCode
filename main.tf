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
variable "required_services" {
  type = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "storage.googleapis.com"
  ]
}

resource "google_project_service" "enabled" {
  for_each = toset(var.required_services)

  project = var.project_id
  service = each.value

  disable_on_destroy = true
}

# -----------------------------
# VPC Network
# -----------------------------

# Réseau VPC → dépend de Compute Engine
resource "google_compute_network" "vpc_network" {
  name                    = "vpc-network"
  auto_create_subnetworks = false

  depends_on = [
    google_project_service.enabled["compute.googleapis.com"]
  ]
}

# -----------------------------
# Public Subnet
# -----------------------------

resource "google_compute_subnetwork" "public-subnet" {
  name          = "public-subnet"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = var.public_subnet_cidr
  private_ip_google_access = true

  depends_on = [
    google_project_service.enabled["compute.googleapis.com"]
  ]
}

# -----------------------------
# Private Subnet
# -----------------------------

resource "google_compute_subnetwork" "private-subnet" {
  name          = "private-subnet"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = var.private_subnet_cidr
  private_ip_google_access = true

  depends_on = [
    google_project_service.enabled["compute.googleapis.com"]
  ]
}

# Bucket GCS → dépend de l’API Storage
resource "google_storage_bucket" "demo" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  depends_on = [
    google_project_service.enabled["storage.googleapis.com"]
  ]
}

# -----------------------------
# Outputs
# -----------------------------
output "vpc_id" {
  value       = google_compute_network.vpc_network.id
  description = "The ID of the created VPC"
}

output "public_subnet_id" {
  value       = google_compute_subnetwork.public-subnet.id
  description = "The ID of the created subnet"
}

output "private_subnet_id" {
  value       = google_compute_subnetwork.private-subnet.id
  description = "The ID of the created subnet"
}

output "bucket_name" {
  value       = google_storage_bucket.demo.name
  description = "The name of the created GCS bucket"
}

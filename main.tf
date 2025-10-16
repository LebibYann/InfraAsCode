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

  disable_on_destroy          = true
  disable_dependent_services  = true
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

resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = var.public_subnet_cidr
  private_ip_google_access = true

  depends_on = [
    google_compute_network.vpc_network
  ]
}

# -----------------------------
# Private Subnet
# -----------------------------

resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = var.private_subnet_cidr
  private_ip_google_access = true

  depends_on = [
    google_compute_network.vpc_network
  ]
}

# -----------------------------
# GCS Bucket
# -----------------------------

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
# Cloud Router
# -----------------------------

resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  region  = var.region
  network = google_compute_network.vpc_network.id

  depends_on = [
    google_compute_subnetwork.private_subnet
  ]
}

# -----------------------------
# Cloud NAT
# -----------------------------

resource "google_compute_router_nat" "nat_config" {
  name                                = "nat-config"
  router                              = google_compute_router.nat_router.name
  region                              = var.region
  nat_ip_allocate_option              = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat  = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name = google_compute_subnetwork.private_subnet.name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  depends_on = [
    google_compute_router.nat_router
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
  value       = google_compute_subnetwork.public_subnet.id
  description = "The ID of the created subnet"
}

output "private_subnet_id" {
  value       = google_compute_subnetwork.private_subnet.id
  description = "The ID of the created subnet"
}

output "bucket_name" {
  value       = google_storage_bucket.demo.name
  description = "The name of the created GCS bucket"
}

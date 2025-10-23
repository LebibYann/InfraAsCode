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
# Enable Required Services
# -----------------------------
variable "required_services" {
  type = list(string)
  default = [
   "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "storage.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com"
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
# Modules
# -----------------------------

module "network" {
  source              = "./modules/network"
  project_id          = var.project_id
  region              = var.region
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  network_name        = var.network_name
  
  depends_on = [
    google_project_service.enabled
  ]
}

module "nat" {
  source         = "./modules/nat"
  project_id     = var.project_id
  region         = var.region
  network_id     = module.network.vpc_id
  private_subnet = module.network.private_subnet_name
  
  depends_on = [
    module.network
  ]
}

module "iam" {
  source     = "./modules/iam"
  project_id = var.project_id
  
  depends_on = [
    google_project_service.enabled
  ]
  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = "10.92.0.0/14"
  }

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.96.0.0/20"
  }
}

# -----------------------------
# Reserve IP range for Private Services Access
# -----------------------------
resource "google_compute_global_address" "private_services_ip" {
  name          = "google-managed-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

# -----------------------------
# VPC Peering with Google Services
# -----------------------------
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services_ip.name]

  depends_on = [
    google_compute_global_address.private_services_ip
  ]
}

module "gke" {
  source          = "./modules/gke"
  project_id      = var.project_id
  region          = var.region
  network_id      = module.network.vpc_id
  subnetwork      = module.network.private_subnet_id
  service_account = module.iam.gke_sa_email
  
  depends_on = [
    module.nat,
    module.iam,
    google_project_service.enabled
  ]
}

module "storage" {
  source      = "./modules/storage"
  bucket_name = var.bucket_name
  region      = var.region
  
  depends_on = [
    google_project_service.enabled
  ]
}

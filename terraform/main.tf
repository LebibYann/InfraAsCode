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
    "logging.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}

resource "google_project_service" "enabled" {
  for_each = toset(var.required_services)

  project = var.project_id
  service = each.value

  disable_on_destroy         = false
  disable_dependent_services = false
}

# -----------------------------
# Network Module
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

# -----------------------------
# Reserve IP range for Private Services Access (Cloud SQL)
# -----------------------------

resource "google_compute_global_address" "private_services_ip" {
  name          = "google-managed-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.network.vpc_id

  depends_on = [
    module.network
  ]
}

# -----------------------------
# VPC Peering with Google Services (for Cloud SQL)
# -----------------------------

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = module.network.vpc_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services_ip.name]

  depends_on = [
    google_compute_global_address.private_services_ip,
    google_project_service.enabled
  ]
}

# -----------------------------
# NAT Module
# -----------------------------

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

# -----------------------------
# IAM Module
# -----------------------------

module "iam" {
  source     = "./modules/iam"
  project_id = var.project_id

  depends_on = [
    google_project_service.enabled
  ]
}

# -----------------------------
# Secrets Module
# -----------------------------

module "secrets" {
  source     = "./modules/secrets"
  project_id = var.project_id
  environment = var.environment
  
  gke_service_account       = module.iam.gke_sa_email
  terraform_service_account = ""  # À configurer si vous utilisez un SA Terraform dédié
  cloudsql_service_account  = ""  # Cloud SQL utilise un SA géré par Google

  depends_on = [
    google_project_service.enabled,
    module.iam
  ]
}

# -----------------------------
# GKE Module
# -----------------------------

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
    google_project_service.enabled,
    module.network
  ]
}

# -----------------------------
# Cloud SQL Module
# -----------------------------

module "cloudsql" {
  source                       = "./modules/cloudsql"
  project_id                   = var.project_id
  region                       = var.region
  instance_name                = "postgres-instance"
  database_version             = "POSTGRES_15"
  tier                         = var.cloudsql_tier
  vpc_id                       = module.network.vpc_id
  vpc_peering_connection       = google_service_networking_connection.private_vpc_connection
  db_name                      = var.db_name
  db_user                      = var.db_user
  db_password_secret_id        = "cloudsql-${var.environment}-password"
  db_password_secret_project   = var.project_id
  deletion_protection          = false

  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_project_service.enabled,
    module.secrets
  ]
}

# -----------------------------
# Storage Module
# -----------------------------

module "storage" {
  source      = "./modules/storage"
  bucket_name = var.bucket_name
  region      = var.region

  depends_on = [
    google_project_service.enabled
  ]
}

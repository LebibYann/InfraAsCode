terraform {
    backend "gcs" {}
}
# -----------------------------
# Enable Required GCP Services
# -----------------------------
variable "required_services" {
    type = list(string)
    default = [
        "container.googleapis.com",     # Required for GKE
        "sqladmin.googleapis.com",      # Required for Cloud SQL
        "secretmanager.googleapis.com", # Required for Secret Manager
    ]
}

resource "google_project_service" "enabled_services" {
    for_each = toset(var.required_services)

    project = var.project_id
    service = each.value

    disable_on_destroy = false
}

# -----------------------------
# Import Network State (from base infrastructure)
# -----------------------------
data "terraform_remote_state" "network" {
    backend = "gcs"
    config = {
        bucket = "lenny-iac-tfstates-bucket"
        prefix = "terraform/state"
    }
}

locals {
    vpc_id         = data.terraform_remote_state.network.outputs.vpc_id
    public_subnet  = data.terraform_remote_state.network.outputs.public_subnet_id
    private_subnet = data.terraform_remote_state.network.outputs.private_subnet_id
}


# -----------------------------
# GKE Cluster
# -----------------------------
resource "google_container_cluster" "primary" {
    name                      = "gke-cluster"
    project                   = var.project_id
    location                  = var.region
    remove_default_node_pool   = true
    initial_node_count         = 1
    network                   = local.vpc_id
    subnetwork                = local.private_subnet
    deletion_protection        = false

    ip_allocation_policy {
        cluster_secondary_range_name  = "pods-range"
        services_secondary_range_name = "services-range"
    }

    depends_on = [google_project_service.enabled_services["container.googleapis.com"]]
}

# -----------------------------
# GKE Node Pool
# -----------------------------
resource "google_container_node_pool" "primary_nodes" {
    project  = var.project_id
    cluster  = google_container_cluster.primary.name
    location = var.region

    node_config {
        machine_type = var.machine_type
        disk_size_gb  = 30
        oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    }

    initial_node_count = var.node_count

    depends_on = [google_container_cluster.primary]
}

# -----------------------------
# Cloud SQL (PostgreSQL)
# -----------------------------
resource "google_sql_database_instance" "postgres_instance" {
    project          = var.project_id
    name             = "postgres-instance"
    database_version = "POSTGRES_15"
    region           = var.region

    settings {
        tier = "db-f1-micro"
        ip_configuration {
            ipv4_enabled    = false
            private_network = data.terraform_remote_state.network.outputs.vpc_id
        }
    }
}

# -----------------------------
# Database
# -----------------------------
resource "google_sql_database" "db" {
    project  = var.project_id
    name     = var.db_name
    instance = google_sql_database_instance.postgres_instance.name

    depends_on = [google_sql_database_instance.postgres_instance]
}

# -----------------------------
# Database User (password stored in Secret Manager)
# -----------------------------

data "google_secret_manager_secret_version" "db_password" {
    secret  = "db-password"
    project = var.project_id
}

resource "google_sql_user" "db_user" {
    project  = var.project_id 
    name     = var.db_user
    instance = google_sql_database_instance.postgres_instance.name
    password = data.google_secret_manager_secret_version.db_password.secret_data

    depends_on = [google_sql_database_instance.postgres_instance, google_project_service.enabled_services["secretmanager.googleapis.com"]]
}

# -----------------------------
# Outputs
# -----------------------------
output "gke_cluster_name" {
    value       = google_container_cluster.primary.name
    description = "Le nom du cluster GKE"
}

output "db_instance_name" {
    value       = google_sql_database_instance.postgres_instance.name
    description = "Le nom de l'instance PostgreSQL"
}

output "db_name" {
    value       = google_sql_database.db.name
    description = "Le nom de la base PostgreSQL"
}
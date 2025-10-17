# -----------------------------
# Private Service Access (obligatoire)
# -----------------------------
resource "google_compute_global_address" "private_ip_block" {
  name          = "cloudsql-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.network_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.network_id
  service                 = "services/${var.project_number}/servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_block.name]
}

# -----------------------------
# Cloud SQL (PostgreSQL)
# -----------------------------
resource "google_sql_database_instance" "cloudsql" {
  name             = "iac-db"
  region           = var.region
  database_version = "POSTGRES_15"

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]

  settings {
    tier = "db-f1-micro"
    availability_type = "ZONAL"

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
    }

    backup_configuration {
      enabled = true
    }

    maintenance_window {
      day  = 7
      hour = 3
    }
  }

  deletion_protection = false
}

# -----------------------------
# Database & User
# -----------------------------

resource "google_sql_database" "default" {
  name     = var.db_name
  instance = google_sql_database_instance.cloudsql.name
}

resource "google_sql_user" "app_user" {
  name     = var.db_user
  instance = google_sql_database_instance.cloudsql.name
  password = var.db_password
}

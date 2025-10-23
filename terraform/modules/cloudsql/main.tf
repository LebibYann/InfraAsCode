# -----------------------------
# Retrieve password from Secret Manager
# -----------------------------

data "google_secret_manager_secret_version" "db_password" {
  project = coalesce(var.db_password_secret_project, var.project_id)
  secret  = var.db_password_secret_id
  version = "latest"
}

# -----------------------------
# Cloud SQL PostgreSQL Instance
# -----------------------------

resource "google_sql_database_instance" "postgres_instance" {
  project          = var.project_id
  name             = var.instance_name
  database_version = var.database_version
  region           = var.region

  settings {
    tier = var.tier

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_id
    }

    backup_configuration {
      enabled    = true
      start_time = "03:00"
    }

    maintenance_window {
      day  = 7
      hour = 3
    }
  }

  deletion_protection = var.deletion_protection

  # Ensure this resource is destroyed before the VPC peering connection
  lifecycle {
    create_before_destroy = false
  }

  depends_on = [var.vpc_peering_connection]
}

# -----------------------------
# Database
# -----------------------------

resource "google_sql_database" "database" {
  project  = var.project_id
  name     = var.db_name
  instance = google_sql_database_instance.postgres_instance.name

  depends_on = [google_sql_database_instance.postgres_instance]
}

# -----------------------------
# Database User
# -----------------------------

resource "google_sql_user" "db_user" {
  project  = var.project_id
  name     = var.db_user
  instance = google_sql_database_instance.postgres_instance.name
  password = data.google_secret_manager_secret_version.db_password.secret_data

  depends_on = [google_sql_database_instance.postgres_instance]
}

# -----------------------------
# Secret Manager Secrets
# -----------------------------

# Secret for Cloud SQL Database Password
resource "google_secret_manager_secret" "db_password" {
  secret_id = "cloudsql-${var.environment}-password"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
    purpose     = "cloudsql"
  }
}

# Note: The secret version must be created manually or via a script
# For security reasons, we do NOT store the password in plain text in Terraform
# Use: gcloud secrets versions add cloudsql-dev-password --data-file="-"

# -----------------------------
# IAM Permissions for Secret Access
# -----------------------------

# Allow Cloud SQL to access the secret (via service account)
# Note: Cloud SQL uses a Google-managed service account, no explicit permissions needed here
resource "google_secret_manager_secret_iam_member" "cloudsql_secret_access" {
  count     = var.cloudsql_service_account != "" ? 1 : 0
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.cloudsql_service_account}"
}

# Allow GKE workloads to access the secret (via Workload Identity)
resource "google_secret_manager_secret_iam_member" "gke_secret_access" {
  count     = var.gke_service_account != "" ? 1 : 0
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.gke_service_account}"
}

# Allow Terraform SA to manage secrets
resource "google_secret_manager_secret_iam_member" "terraform_secret_admin" {
  count     = var.terraform_service_account != "" ? 1 : 0
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.admin"
  member    = "serviceAccount:${var.terraform_service_account}"
}

output "db_password_secret_id" {
  value       = google_secret_manager_secret.db_password.secret_id
  description = "Secret ID for database password"
}

output "db_password_secret_name" {
  value       = google_secret_manager_secret.db_password.name
  description = "Full secret name (projects/*/secrets/*)"
}

output "db_password_secret_version" {
  value       = "${google_secret_manager_secret.db_password.name}/versions/latest"
  description = "Path to the latest version of the secret"
}

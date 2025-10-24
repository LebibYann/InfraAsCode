output "instance_name" {
  value       = google_sql_database_instance.postgres.name
  description = "Cloud SQL instance name"
}

output "instance_connection_name" {
  value       = google_sql_database_instance.postgres.connection_name
  description = "Cloud SQL instance connection name"
}

output "database_name" {
  value       = google_sql_database.database.name
  description = "Database name"
}

output "private_ip_address" {
  value       = google_sql_database_instance.postgres.private_ip_address
  description = "Private IP address of the Cloud SQL instance"
}

output "db_password_secret_id" {
  value       = google_secret_manager_secret.db_password.secret_id
  description = "Secret Manager secret ID for database password"
}

output "db_password_secret_name" {
  value       = google_secret_manager_secret.db_password.name
  description = "Secret Manager secret name for database password"
}

output "db_user" {
  value       = google_sql_user.users.name
  description = "Database user name"
}

output "db_password" {
  value       = random_password.db_password.result
  description = "Database password (sensitive)"
  sensitive   = true
}

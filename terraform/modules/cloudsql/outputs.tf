output "instance_name" {
  value       = google_sql_database_instance.postgres_instance.name
  description = "Cloud SQL instance name"
}

output "instance_connection_name" {
  value       = google_sql_database_instance.postgres_instance.connection_name
  description = "Cloud SQL instance connection name"
}

output "database_name" {
  value       = google_sql_database.database.name
  description = "Database name"
}

output "private_ip_address" {
  value       = google_sql_database_instance.postgres_instance.private_ip_address
  description = "Private IP address of the Cloud SQL instance"
}

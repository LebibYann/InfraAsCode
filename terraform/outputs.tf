
# -----------------------------
# Outputs
# -----------------------------

# Network Outputs
output "vpc_id" {
  value       = module.network.vpc_id
  description = "The ID of the created VPC"
}

output "public_subnet_id" {
  value       = module.network.public_subnet_id
  description = "The ID of the public subnet"
}

output "private_subnet_id" {
  value       = module.network.private_subnet_id
  description = "The ID of the private subnet"
}

# Storage Outputs
output "bucket_name" {
  value       = module.storage.bucket_name
  description = "The name of the created GCS bucket"
}

# GKE Outputs
output "gke_cluster_name" {
  value       = module.gke.cluster_name
  description = "The name of the GKE cluster"
}

output "gke_cluster_endpoint" {
  value       = module.gke.cluster_endpoint
  description = "The endpoint of the GKE cluster"
  sensitive   = true
}

# Cloud SQL Outputs
output "cloudsql_instance_name" {
  value       = module.cloudsql.instance_name
  description = "Cloud SQL instance name"
}

output "cloudsql_connection_name" {
  value       = module.cloudsql.instance_connection_name
  description = "Cloud SQL connection name for Cloud SQL Proxy"
}

output "database_name" {
  value       = module.cloudsql.database_name
  description = "Database name"
}

output "cloudsql_private_ip" {
  value       = module.cloudsql.private_ip_address
  description = "Private IP address of Cloud SQL instance"
}

# IAM Outputs
output "gke_service_account_email" {
  value       = module.iam.gke_sa_email
  description = "Email of the GKE service account"
}


# -----------------------------
# Outputs
# -----------------------------

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

output "bucket_name" {
  value       = module.storage.bucket_name
  description = "The name of the created GCS bucket"
}

output "gke_cluster_name" {
  value       = module.gke.cluster_name
  description = "The name of the GKE cluster"
}

output "gke_cluster_endpoint" {
  value       = module.gke.cluster_endpoint
  description = "The endpoint of the GKE cluster"
  sensitive   = true
}

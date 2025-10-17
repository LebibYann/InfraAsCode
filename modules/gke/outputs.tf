# -----------------------------
# Outputs
# -----------------------------

output "cluster_name" {
  value       = google_container_cluster.main.name
  description = "The name of the GKE cluster"
}

output "cluster_endpoint" {
  value       = google_container_cluster.main.endpoint
  description = "The endpoint of the GKE cluster"
  sensitive   = true
}

output "cluster_ca_certificate" {
  value       = google_container_cluster.main.master_auth[0].cluster_ca_certificate
  description = "The CA certificate of the GKE cluster"
  sensitive   = true
}

output "app_pool_name" {
  value       = google_container_node_pool.app_pool.name
  description = "The name of the app node pool"
}

output "runners_pool_name" {
  value       = google_container_node_pool.runners_pool.name
  description = "The name of the runners node pool"
}

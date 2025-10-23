# -----------------------------
# Outputs
# -----------------------------

output "gke_sa_email" {
  value       = google_service_account.gke_nodes.email
  description = "The email of the GKE nodes service account"
}

output "gke_sa_id" {
  value       = google_service_account.gke_nodes.id
  description = "The ID of the GKE nodes service account"
}

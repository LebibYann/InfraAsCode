# -----------------------------
# GKE Nodes Outputs
# -----------------------------

output "gke_sa_email" {
  value       = google_service_account.gke_nodes.email
  description = "The email of the GKE nodes service account"
}

output "gke_sa_id" {
  value       = google_service_account.gke_nodes.id
  description = "The ID of the GKE nodes service account"
}

# -----------------------------
# GitHub Actions Outputs
# -----------------------------

output "github_workload_identity_pool_id" {
  value       = google_iam_workload_identity_pool.github.workload_identity_pool_id
  description = "Workload Identity Pool ID for GitHub Actions"
}

output "github_workload_identity_pool_name" {
  value       = google_iam_workload_identity_pool.github.name
  description = "Workload Identity Pool name for GitHub Actions"
}

output "github_workload_identity_provider_name" {
  value       = google_iam_workload_identity_pool_provider.github.name
  description = "Workload Identity Pool Provider name for GitHub Actions"
}

output "github_actions_sa_email" {
  value       = google_service_account.github_actions.email
  description = "GitHub Actions service account email"
}

output "github_actions_sa_id" {
  value       = google_service_account.github_actions.id
  description = "GitHub Actions service account ID"
}

output "github_actions_sa_name" {
  value       = google_service_account.github_actions.name
  description = "GitHub Actions service account name"
}

# -----------------------------
# Kubernetes Application Outputs
# -----------------------------

output "k8s_app_sa_email" {
  value       = google_service_account.k8s_app.email
  description = "Kubernetes application service account email"
}

output "k8s_app_sa_id" {
  value       = google_service_account.k8s_app.id
  description = "Kubernetes application service account ID"
}

output "k8s_app_sa_name" {
  value       = google_service_account.k8s_app.name
  description = "Kubernetes application service account name"
}

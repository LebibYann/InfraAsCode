# ========================================
# Actions Runner Controller Outputs
# ========================================

output "arc_namespace" {
  description = "Namespace where Actions Runner Controller is installed"
  value       = kubernetes_namespace.arc.metadata[0].name
}

output "arc_release_name" {
  description = "ARC Helm release name"
  value       = helm_release.actions_runner_controller.name
}

output "arc_release_status" {
  description = "ARC deployment status"
  value       = helm_release.actions_runner_controller.status
}

# ========================================
# GitHub Runners Outputs
# ========================================

output "node_pool_name" {
  description = "GitHub runners node pool name"
  value       = google_container_node_pool.github_runners.name
}

output "namespace" {
  description = "Kubernetes namespace for runners"
  value       = kubernetes_namespace.github_runners.metadata[0].name
}

output "service_account_name" {
  description = "Kubernetes service account name"
  value       = kubernetes_service_account.github_runner.metadata[0].name
}

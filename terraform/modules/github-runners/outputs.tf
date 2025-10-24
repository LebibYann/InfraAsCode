# ========================================
# Actions Runner Controller Outputs
# ========================================

output "arc_namespace" {
  description = "Namespace où Actions Runner Controller est installé"
  value       = kubernetes_namespace.arc.metadata[0].name
}

output "arc_release_name" {
  description = "Nom du Helm release ARC"
  value       = helm_release.actions_runner_controller.name
}

output "arc_release_status" {
  description = "Statut du déploiement ARC"
  value       = helm_release.actions_runner_controller.status
}

# ========================================
# GitHub Runners Outputs
# ========================================

output "node_pool_name" {
  description = "Nom du node pool GitHub runners"
  value       = google_container_node_pool.github_runners.name
}

output "namespace" {
  description = "Namespace Kubernetes pour les runners"
  value       = kubernetes_namespace.github_runners.metadata[0].name
}

output "service_account_name" {
  description = "Nom du service account Kubernetes"
  value       = kubernetes_service_account.github_runner.metadata[0].name
}

output "namespace" {
  description = "Namespace where cert-manager is installed"
  value       = kubernetes_namespace.cert_manager.metadata[0].name
}

output "release_name" {
  description = "Helm release name for cert-manager"
  value       = helm_release.cert_manager.name
}

output "release_status" {
  description = "cert-manager deployment status"
  value       = helm_release.cert_manager.status
}

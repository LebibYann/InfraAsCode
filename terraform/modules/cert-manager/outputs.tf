output "namespace" {
  description = "Namespace où cert-manager est installé"
  value       = kubernetes_namespace.cert_manager.metadata[0].name
}

output "release_name" {
  description = "Nom du Helm release cert-manager"
  value       = helm_release.cert_manager.name
}

output "release_status" {
  description = "Statut du déploiement cert-manager"
  value       = helm_release.cert_manager.status
}

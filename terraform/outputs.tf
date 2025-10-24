
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

# Application Outputs
output "app_namespace" {
  value       = "iac"
  description = "Kubernetes namespace for the application"
}

output "app_helm_release_name" {
  value       = helm_release.iac_app.name
  description = "Helm release name for the application"
}

output "app_image" {
  value       = "${var.app_image_repository}:${var.app_image_tag}"
  description = "Docker image deployed for the application"
}

output "app_loadbalancer_ip" {
  description = "IP Address of the Application Load Balancer"
  value       = try(data.kubernetes_service.iac_service.status[0].load_balancer[0].ingress[0].ip, "pending")
}

output "app_url" {
  description = "URL to access the application"
  value       = "http://${try(data.kubernetes_service.iac_service.status[0].load_balancer[0].ingress[0].ip, "pending")}"
}

# GitHub Runners Outputs
output "github_runners_node_pool" {
  value       = module.github_runners.node_pool_name
  description = "Name of the GitHub runners node pool"
}

output "github_runners_namespace" {
  value       = module.github_runners.namespace
  description = "Kubernetes namespace for GitHub runners"
}

output "github_runners_service_account" {
  value       = module.github_runners.service_account_name
  description = "Service account for GitHub runners"
}

output "github_runners_info" {
  value = <<-EOT
    GitHub Self-Hosted Runners deployed successfully!
    
    Namespace: ${module.github_runners.namespace}
    Node Pool: ${module.github_runners.node_pool_name}
    
    To check the status of your runners:
    kubectl get pods -n ${module.github_runners.namespace}
    
    To view runner logs:
    kubectl logs -n ${module.github_runners.namespace} -l app.kubernetes.io/name=github-runners
    
    Runners should be visible in GitHub at:
    https://github.com/${replace(var.github_repository_url, "https://github.com/", "")}/settings/actions/runners
  EOT
  description = "Information about the deployed GitHub runners"
}

output "app_access_info" {
  value = <<-EOT
    Application deployed successfully!
    
    Access your application at:
    ${try(data.kubernetes_service.iac_service.status[0].load_balancer[0].ingress[0].ip, "pending")}
    
    Health check endpoint:
    http://${try(data.kubernetes_service.iac_service.status[0].load_balancer[0].ingress[0].ip, "pending")}/api/v1/health
    
    To check the LoadBalancer status:
    kubectl get svc iac-service -n iac
  EOT
  description = "Instructions to access the deployed application"
}

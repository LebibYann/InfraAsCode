output "vpc_id" {
  value       = google_compute_network.vpc_network.id
  description = "The ID of the created VPC"
}

output "public_subnet_id" {
  value       = google_compute_subnetwork.public_subnet.id
  description = "The ID of the public subnet"
}

output "private_subnet_id" {
  value       = google_compute_subnetwork.private_subnet.id
  description = "The ID of the private subnet"
}

output "private_subnet_name" {
  value       = google_compute_subnetwork.private_subnet.name
  description = "The name of the private subnet"
}

# ========================================
# NAT Outputs
# ========================================

output "nat_router_name" {
  value       = google_compute_router.nat_router.name
  description = "The name of the NAT router"
}

output "nat_config_name" {
  value       = google_compute_router_nat.nat_config.name
  description = "The name of the NAT configuration"
}

# ========================================
# Load Balancer Outputs
# ========================================

output "lb_ip_address" {
  value       = var.enable_load_balancer ? google_compute_global_address.lb_ip[0].address : ""
  description = "Adresse IP publique du Load Balancer"
}

output "lb_ip_name" {
  value       = var.enable_load_balancer ? google_compute_global_address.lb_ip[0].name : ""
  description = "Nom de l'IP réservée"
}

output "ssl_certificate_id" {
  value       = var.enable_load_balancer && length(var.lb_domains) > 0 ? google_compute_managed_ssl_certificate.lb_cert[0].id : ""
  description = "ID du certificat SSL managé"
}

output "http_forwarding_rule" {
  value       = var.enable_load_balancer ? google_compute_global_forwarding_rule.http[0].name : ""
  description = "Nom de la règle de forwarding HTTP"
}

output "https_forwarding_rule" {
  value       = var.enable_load_balancer && length(var.lb_domains) > 0 ? google_compute_global_forwarding_rule.https[0].name : ""
  description = "Nom de la règle de forwarding HTTPS"
}

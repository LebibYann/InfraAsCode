# -----------------------------
# Outputs
# -----------------------------

output "nat_router_name" {
  value       = google_compute_router.nat_router.name
  description = "The name of the NAT router"
}

output "nat_config_name" {
  value       = google_compute_router_nat.nat_config.name
  description = "The name of the NAT configuration"
}

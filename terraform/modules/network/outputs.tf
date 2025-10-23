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
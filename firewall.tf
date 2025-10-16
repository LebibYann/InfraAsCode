# Allow internal communication within the VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc_network.id

  direction = "INGRESS"
  priority  = 1000

  source_ranges = ["10.0.0.0/8"]
  allow {
    protocol = "all"
  }

  description = "Allow internal traffic between private resources"
}

# Allow HTTP/HTTPS from Internet to public subnet
resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = google_compute_network.vpc_network.id

  direction = "INGRESS"
  priority  = 1000

  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  description = "Allow external HTTP/HTTPS traffic (for load balancer)"
}

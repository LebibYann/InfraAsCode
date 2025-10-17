# -----------------------------
# VPC Network
# -----------------------------

# Réseau VPC → dépend de Compute Engine
resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

# -----------------------------
# Public Subnet
# -----------------------------

resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = var.public_subnet_cidr
  private_ip_google_access = true

  depends_on = [
    google_compute_network.vpc_network
  ]
}

# -----------------------------
# Private Subnet
# -----------------------------

resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = var.private_subnet_cidr
  private_ip_google_access = true

  depends_on = [
    google_compute_network.vpc_network
  ]
}

# -----------------------------
# Firewalls
# -----------------------------

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

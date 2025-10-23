# -----------------------------
# VPC Network
# -----------------------------

# VPC Network → depends on Compute Engine
resource "google_compute_network" "vpc_network" {
  name                            = var.network_name
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

# -----------------------------
# Public Subnet
# -----------------------------

resource "google_compute_subnetwork" "public_subnet" {
  name                     = "public-subnet"
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  ip_cidr_range            = var.public_subnet_cidr
  private_ip_google_access = true

  depends_on = [
    google_compute_network.vpc_network
  ]
}

# -----------------------------
# Private Subnet (GKE)
# -----------------------------

resource "google_compute_subnetwork" "private_subnet" {
  name                     = "private-subnet"
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  ip_cidr_range            = var.private_subnet_cidr
  private_ip_google_access = true

  # Secondary IP ranges for GKE
  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = "10.92.0.0/14"
  }

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.96.0.0/20"
  }

  # Ignore les ranges secondaires créées automatiquement par GKE
  lifecycle {
    ignore_changes = [
      secondary_ip_range
    ]
  }

  depends_on = [
    google_compute_network.vpc_network
  ]
}

# -----------------------------
# Firewalls
# -----------------------------

# Default route to Internet (created manually since we delete default routes)
resource "google_compute_route" "default_internet_gateway" {
  name             = "default-internet-gateway"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc_network.id
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  description      = "Default route to Internet"

  depends_on = [google_compute_network.vpc_network]
}

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

# Allow health checks from Google Load Balancers
resource "google_compute_firewall" "allow_health_checks" {
  name    = "allow-health-checks"
  network = google_compute_network.vpc_network.id

  direction = "INGRESS"
  priority  = 1000

  source_ranges = [
    "35.191.0.0/16", # Google Cloud health check ranges
    "130.211.0.0/22"
  ]

  allow {
    protocol = "tcp"
    ports    = ["8080", "9090", "3000"] # App, Prometheus, Grafana
  }

  target_tags = ["gke-default"]

  description = "Allow health checks from Google Load Balancers"
}

# Allow SSH for debugging (optional, can be removed in production)
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.id

  direction = "INGRESS"
  priority  = 1000

  source_ranges = ["35.235.240.0/20"] # IAP for TCP forwarding

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["gke-default"]

  description = "Allow SSH via IAP for debugging"
}

# Deny all other inbound traffic (implicit, but explicit for clarity)
resource "google_compute_firewall" "deny_all_ingress" {
  name    = "deny-all-ingress"
  network = google_compute_network.vpc_network.id

  direction = "INGRESS"
  priority  = 65535

  source_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }

  description = "Deny all other inbound traffic"
}

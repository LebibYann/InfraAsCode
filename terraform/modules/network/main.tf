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

# ========================================
# Cloud NAT
# ========================================

# -----------------------------
# Cloud Router
# -----------------------------

resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  region  = var.region
  network = google_compute_network.vpc_network.id
}

# -----------------------------
# Cloud NAT Configuration
# -----------------------------

resource "google_compute_router_nat" "nat_config" {
  name                               = "nat-config"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private_subnet.name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ========================================
# Load Balancer (Optional)
# ========================================

# -----------------------------
# Réservation d'une IP statique globale
# -----------------------------

resource "google_compute_global_address" "lb_ip" {
  count = var.enable_load_balancer ? 1 : 0

  name         = "${var.lb_name}-lb-ip"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

# -----------------------------
# Certificat SSL managé par Google
# -----------------------------

resource "google_compute_managed_ssl_certificate" "lb_cert" {
  count = var.enable_load_balancer && length(var.lb_domains) > 0 ? 1 : 0

  name = "${var.lb_name}-ssl-cert"

  managed {
    domains = var.lb_domains
  }
}

# -----------------------------
# Health Check
# -----------------------------

resource "google_compute_health_check" "http_health_check" {
  count = var.enable_load_balancer ? 1 : 0

  name                = "${var.lb_name}-http-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = var.lb_backend_port
    request_path = var.lb_health_check_path
  }
}

# -----------------------------
# URL Map - Redirection HTTP vers HTTPS
# -----------------------------

resource "google_compute_url_map" "http_redirect" {
  count = var.enable_load_balancer ? 1 : 0

  name = "${var.lb_name}-http-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

# -----------------------------
# URL Map - HTTPS
# -----------------------------

resource "google_compute_url_map" "https_lb" {
  count = var.enable_load_balancer ? 1 : 0

  name            = "${var.lb_name}-https-lb"
  default_service = var.lb_backend_service_id
}

# -----------------------------
# HTTP Proxy for redirection
# -----------------------------

resource "google_compute_target_http_proxy" "http_proxy" {
  count = var.enable_load_balancer ? 1 : 0

  name    = "${var.lb_name}-http-proxy"
  url_map = google_compute_url_map.http_redirect[0].id
}

# -----------------------------
# HTTPS Proxy
# -----------------------------

resource "google_compute_target_https_proxy" "https_proxy" {
  count = var.enable_load_balancer && length(var.lb_domains) > 0 ? 1 : 0

  name             = "${var.lb_name}-https-proxy"
  url_map          = google_compute_url_map.https_lb[0].id
  ssl_certificates = [google_compute_managed_ssl_certificate.lb_cert[0].id]
}

# -----------------------------
# Forwarding Rule HTTP (port 80) - Redirects to HTTPS
# -----------------------------

resource "google_compute_global_forwarding_rule" "http" {
  count = var.enable_load_balancer ? 1 : 0

  name                  = "${var.lb_name}-http-forwarding-rule"
  target                = google_compute_target_http_proxy.http_proxy[0].id
  port_range            = "80"
  ip_address            = google_compute_global_address.lb_ip[0].address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# -----------------------------
# Forwarding Rule HTTPS (port 443)
# -----------------------------

resource "google_compute_global_forwarding_rule" "https" {
  count = var.enable_load_balancer && length(var.lb_domains) > 0 ? 1 : 0

  name                  = "${var.lb_name}-https-forwarding-rule"
  target                = google_compute_target_https_proxy.https_proxy[0].id
  port_range            = "443"
  ip_address            = google_compute_global_address.lb_ip[0].address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

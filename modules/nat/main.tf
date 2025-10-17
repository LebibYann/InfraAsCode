# -----------------------------
# Cloud Router
# -----------------------------

resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  region  = var.region
  network = var.network_id
}

# -----------------------------
# Cloud NAT
# -----------------------------

resource "google_compute_router_nat" "nat_config" {
  name                                = "nat-config"
  router                              = google_compute_router.nat_router.name
  region                              = var.region
  nat_ip_allocate_option              = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat  = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name = var.private_subnet
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

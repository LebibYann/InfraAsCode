# -----------------------------
# GKE Cluster
# -----------------------------

resource "google_container_cluster" "main" {
  name       = "iac-cluster"
  location   = var.region
  network    = var.network_id
  subnetwork = var.subnetwork

  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false

  # Private cluster (nodes without public IP)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # IP ranges for pods and services
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/14"
    services_ipv4_cidr_block = "/20"
  }

  # Enable network policy addon
  network_policy {
    enabled = true
  }

  # Enable shielded nodes for security
  enable_shielded_nodes = true

  # Release channel for auto-updates
  release_channel {
    channel = "REGULAR"
  }

  # Note: node_config is removed because we use remove_default_node_pool = true
  # All node configuration is done in the node pools below

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Ignorer les changements sur node_config car le default pool est supprimé
  lifecycle {
    ignore_changes = [
      node_config,
      initial_node_count
    ]
  }
}

resource "google_container_node_pool" "app_pool" {
  name     = "app-pool"
  cluster  = google_container_cluster.main.name
  location = var.region

  node_config {
    machine_type    = "e2-standard-4"
    service_account = var.service_account
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    tags            = ["gke-default"]
    
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  management {
    auto_upgrade = true
    auto_repair  = true
  }
}

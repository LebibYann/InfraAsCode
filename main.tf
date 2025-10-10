terraform {
  backend "gcs" {}
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.6.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# -----------------------------
# Enable Compute API
# -----------------------------
resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = true
}

# -----------------------------
# Network + Subnet
# -----------------------------
resource "google_compute_network" "gpc_vpc" {
  name                    = "test-network"
  auto_create_subnetworks = false

  depends_on = [google_project_service.compute]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "main-subnet"
  region        = var.region
  network       = google_compute_network.gpc_vpc.id
  ip_cidr_range = var.subnet_cidr

  depends_on = [google_project_service.compute]
}

# -----------------------------
# Storage Bucket (optional)
# -----------------------------
resource "google_storage_bucket" "demo" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
}

# -----------------------------
# Compute Instances (backends)
# -----------------------------
resource "google_compute_instance" "vm1" {
  name         = "vm1"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["http-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork   = google_compute_subnetwork.subnet.id
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt update -y && apt install -y apache2
    echo "Hello from VM1" > /var/www/html/index.html
    systemctl enable apache2
    systemctl start apache2
  EOT

  depends_on = [google_compute_subnetwork.subnet]
}

resource "google_compute_instance" "vm2" {
  name         = "vm2"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["http-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork   = google_compute_subnetwork.subnet.id
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt update -y && apt install -y apache2
    echo "Hello from VM2" > /var/www/html/index.html
    systemctl enable apache2
    systemctl start apache2
  EOT

  depends_on = [google_compute_subnetwork.subnet]
}

# -----------------------------
# Instance Group for Load Balancer
# -----------------------------
resource "google_compute_instance_group" "backend_group" {
  name        = "backend-group"
  zone        = var.zone
  instances   = [
    google_compute_instance.vm1.self_link,
    google_compute_instance.vm2.self_link
  ]
  network     = google_compute_network.gpc_vpc.id
  description = "Backend group for HTTP Load Balancer"
}

# -----------------------------
# Health Check
# -----------------------------
resource "google_compute_health_check" "default" {
  name = "http-health-check"

  http_health_check {
    port = 80
  }
}

# -----------------------------
# Backend Service
# -----------------------------
resource "google_compute_backend_service" "default" {
  name                  = "backend-service"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 10
  health_checks         = [google_compute_health_check.default.self_link]
  connection_draining_timeout_sec = 0

  backend {
    group = google_compute_instance_group.backend_group.self_link
  }
}

# -----------------------------
# URL Map + Target Proxy
# -----------------------------
resource "google_compute_url_map" "default" {
  name            = "url-map"
  default_service = google_compute_backend_service.default.self_link
}

resource "google_compute_target_http_proxy" "default" {
  name    = "http-proxy"
  url_map = google_compute_url_map.default.self_link
}

# -----------------------------
# Global IP + Forwarding Rule
# -----------------------------
resource "google_compute_global_address" "default" {
  name = "lb-ip"
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "http-forwarding-rule"
  target     = google_compute_target_http_proxy.default.self_link
  port_range = "80"
  ip_address = google_compute_global_address.default.address
}

# -----------------------------
# Outputs
# -----------------------------
output "vpc_id" {
  value       = google_compute_network.gpc_vpc.id
  description = "The ID of the created VPC"
}

output "subnet_id" {
  value       = google_compute_subnetwork.subnet.id
  description = "The ID of the created subnet"
}

output "bucket_name" {
  value       = google_storage_bucket.demo.name
  description = "The name of the created GCS bucket"
}

output "load_balancer_ip" {
  value       = google_compute_global_address.default.address
  description = "Public IP of the HTTP Load Balancer"
}

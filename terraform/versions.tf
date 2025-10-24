terraform {
  backend "gcs" {}

  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Configure Kubernetes provider using GKE cluster credentials
data "google_client_config" "default" {}

# Use module outputs directly for cluster configuration
# No need for data source since we create the cluster ourselves
locals {
  # Use module outputs if available, otherwise use dummy values for initial deployment
  cluster_endpoint = try(module.gke.cluster_endpoint, "https://127.0.0.1")
  cluster_ca       = try(module.gke.cluster_ca_certificate, "")
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = local.cluster_ca != "" ? base64decode(local.cluster_ca) : ""
}

provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = local.cluster_ca != "" ? base64decode(local.cluster_ca) : ""
  }
}

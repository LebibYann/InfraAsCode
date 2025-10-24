# -----------------------------
# Locals
# -----------------------------

locals {
  pool_id            = var.pool_id != null ? var.pool_id : "github-pool-${var.environment}"
  provider_id        = var.provider_id != null ? var.provider_id : "github-provider-${var.environment}"
  service_account_id = var.service_account_id != null ? var.service_account_id : "github-actions-${var.environment}-sa"
}

# -----------------------------
# Service Account for GKE Nodes
# -----------------------------

resource "google_service_account" "gke_nodes" {
  account_id   = "gke-nodes"
  display_name = "GKE Nodes Service Account"
  project      = var.project_id
}

# IAM minimal permissions for GKE node service account
resource "google_project_iam_member" "gke_node_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/artifactregistry.reader",      # Pour accéder à GCR/Artifact Registry
    "roles/secretmanager.secretAccessor"  # Pour accéder aux secrets
  ])
  project = var.project_id
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
  role    = each.key
}

# -----------------------------
# GitHub Actions - Workload Identity Pool
# -----------------------------

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = local.pool_id
  display_name              = "GitHub Actions Pool (${var.environment})"
  description               = "Workload Identity Pool for GitHub Actions - ${var.environment}"
  project                   = var.project_id
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = local.provider_id
  display_name                       = "GitHub Provider (${var.environment})"
  project                            = var.project_id

  attribute_mapping = {
    "google.subject"        = "assertion.sub"
    "attribute.actor"       = "assertion.actor"
    "attribute.repository"  = "assertion.repository"
    "attribute.environment" = "assertion.environment"
  }

  attribute_condition = "assertion.repository == '${var.github_repository}' && assertion.repository_owner == '${var.github_organization}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# -----------------------------
# GitHub Actions - Service Account
# -----------------------------

resource "google_service_account" "github_actions" {
  account_id   = local.service_account_id
  display_name = "GitHub Actions Service Account (${var.environment})"
  description  = "Service account for GitHub Actions with Workload Identity - ${var.environment}"
  project      = var.project_id
}

resource "google_project_iam_member" "github_actions_roles" {
  for_each = toset(var.github_actions_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_service_account_iam_member" "github_actions_workload_identity" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}

resource "google_service_account_iam_member" "github_actions_workload_identity_env" {
  count = var.github_environment != "" ? 1 : 0

  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}/attribute.environment/${var.github_environment}"
}

# -----------------------------
# Kubernetes Application - Service Account
# -----------------------------

resource "google_service_account" "k8s_app" {
  account_id   = "${var.app_name}-k8s-${var.environment}-sa"
  display_name = "Kubernetes Application Service Account (${var.environment})"
  description  = "Service account for application pods running in GKE - ${var.environment}"
  project      = var.project_id
}

resource "google_project_iam_member" "k8s_app_roles" {
  for_each = toset(var.k8s_app_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.k8s_app.email}"
}

# Note: Workload Identity binding is created in main.tf after GKE cluster exists
# to avoid the error: Identity Pool does not exist

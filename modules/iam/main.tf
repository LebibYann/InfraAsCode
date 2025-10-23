# -----------------------------
# Service Account for GKE
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
    "roles/storage.objectViewer"
  ])
  project = var.project_id
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
  role    = each.key
}

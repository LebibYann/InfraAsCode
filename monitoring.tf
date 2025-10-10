resource "google_project_service" "monitoring" {
  project = var.project_id
  service = "monitoring.googleapis.com"
}

resource "google_project_service" "logging" {
  project = var.project_id
  service = "logging.googleapis.com"
}

resource "google_project_service" "managed_prometheus" {
  project = var.project_id
  service = "monitoring.googleapis.com"
}
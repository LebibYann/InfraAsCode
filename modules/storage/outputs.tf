# -----------------------------
# Outputs
# -----------------------------

output "bucket_name" {
  value       = google_storage_bucket.terraform_state.name
  description = "The name of the created GCS bucket"
}

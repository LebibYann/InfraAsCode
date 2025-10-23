output "terraform_service_account_email" {
  value       = google_service_account.terraform.email
  description = "Email of the Terraform service account"
}

output "terraform_service_account_id" {
  value       = google_service_account.terraform.id
  description = "ID of the Terraform service account"
}

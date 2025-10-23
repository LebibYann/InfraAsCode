variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prd)"
  validation {
    condition     = contains(["dev", "prd"], var.environment)
    error_message = "Environment must be either 'dev' or 'prd'."
  }
}

variable "cloudsql_service_account" {
  type        = string
  description = "Service account email for Cloud SQL"
  default     = ""
}

variable "gke_service_account" {
  type        = string
  description = "Service account email for GKE nodes"
  default     = ""
}

variable "terraform_service_account" {
  type        = string
  description = "Service account email for Terraform"
  default     = ""
}

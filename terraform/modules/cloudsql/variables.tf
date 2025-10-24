variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP region for Cloud SQL instance"
}

variable "instance_name" {
  type        = string
  description = "Name of the Cloud SQL instance"
  default     = "postgres-instance"
}

variable "tier" {
  type        = string
  description = "Machine tier for Cloud SQL"
  default     = "db-f1-micro"
}

variable "disk_size" {
  type        = number
  description = "Disk size in GB for Cloud SQL instance"
  default     = 10
}

variable "network_id" {
  type        = string
  description = "VPC network ID for private IP"
}

variable "private_vpc_connection" {
  description = "VPC peering connection dependency"
  default     = null
}

variable "database_name" {
  type        = string
  description = "Name of the database to create"
}

variable "db_user" {
  type        = string
  description = "Database user name"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prd, etc.)"
}

variable "gke_service_account_email" {
  type        = string
  description = "GKE service account email for secret access"
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection for the Cloud SQL instance"
  default     = true
}

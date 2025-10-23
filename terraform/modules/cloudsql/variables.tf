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

variable "database_version" {
  type        = string
  description = "PostgreSQL version"
  default     = "POSTGRES_15"
}

variable "tier" {
  type        = string
  description = "Machine tier for Cloud SQL"
  default     = "db-f1-micro"
}

variable "vpc_id" {
  type        = string
  description = "VPC network ID for private IP"
}

variable "vpc_peering_connection" {
  description = "VPC peering connection dependency"
  default     = null
}

variable "db_name" {
  type        = string
  description = "Name of the database to create"
}

variable "db_user" {
  type        = string
  description = "Database user name"
}

variable "db_password_secret_id" {
  type        = string
  description = "Secret Manager secret_id for the database password (e.g. cloudsql-dev-password)"
}

variable "db_password_secret_project" {
  type        = string
  description = "Project ID where the secret resides (defaults to current project)"
  default     = null
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection"
  default     = false
}

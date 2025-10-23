variable "project_id" {
  type        = string
  description = "Cloud project ID"
}

variable "region" {
  type        = string
  description = "Region for resources"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prd)"
  validation {
    condition     = contains(["dev", "prd"], var.environment)
    error_message = "Environment must be either 'dev' or 'prd'."
  }
}

variable "bucket_name" {
  type        = string
  description = "Nom du bucket"
}

variable "network_name" {
  type        = string
  description = "Name of the VPC"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR block for the private subnet"
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "db_user" {
  type        = string
  description = "Database user"
}

# Database password is now managed via Secret Manager
# See modules/secrets/ for configuration

variable "cloudsql_tier" {
  type        = string
  description = "Cloud SQL machine tier"
  default     = "db-f1-micro"
}

# -----------------------------
# Variables
# -----------------------------

variable "project_id" {
  type        = string
  description = "Cloud project ID"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prd, etc.)"
}

# -----------------------------
# GitHub Actions Variables
# -----------------------------

variable "pool_id" {
  type        = string
  description = "Workload Identity Pool ID for GitHub Actions"
  default     = null
}

variable "provider_id" {
  type        = string
  description = "Workload Identity Pool Provider ID for GitHub Actions"
  default     = null
}

variable "service_account_id" {
  type        = string
  description = "Service Account ID for GitHub Actions"
  default     = null
}

variable "github_repository" {
  type        = string
  description = "GitHub repository in format 'owner/repo'"
}

variable "github_organization" {
  type        = string
  description = "GitHub organization name"
}

variable "github_environment" {
  type        = string
  description = "GitHub environment name for restricted access"
  default     = ""
}

variable "github_actions_roles" {
  type        = list(string)
  description = "List of IAM roles to assign to GitHub Actions service account"
  default = [
    "roles/container.developer",
    "roles/artifactregistry.writer",
    "roles/storage.objectViewer"
  ]
}

# -----------------------------
# Kubernetes Application Variables
# -----------------------------

variable "app_name" {
  type        = string
  description = "Application name for Kubernetes service account"
}

variable "k8s_namespace" {
  type        = string
  description = "Kubernetes namespace where the application runs"
  default     = "default"
}

variable "k8s_service_account_name" {
  type        = string
  description = "Kubernetes service account name"
}

variable "k8s_app_roles" {
  type        = list(string)
  description = "List of IAM roles to assign to Kubernetes application service account"
  default = [
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor"
  ]
}

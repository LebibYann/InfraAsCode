# -----------------------------
# Variables
# -----------------------------

variable "project_id" {
  type        = string
  description = "Cloud project ID"
}

variable "region" {
  type        = string
  description = "Region for the GKE cluster"
}

variable "network_id" {
  type        = string
  description = "The ID of the VPC network"
}

variable "subnetwork" {
  type        = string
  description = "The ID of the subnetwork"
}

variable "service_account" {
  type        = string
  description = "The service account email for GKE nodes"
}

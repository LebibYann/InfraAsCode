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

variable "min_node_count" {
  type        = number
  description = "Minimum number of nodes in the app node pool"
  default     = 1
}

variable "max_node_count" {
  type        = number
  description = "Maximum number of nodes in the app node pool"
  default     = 3
}

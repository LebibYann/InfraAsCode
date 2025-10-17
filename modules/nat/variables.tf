# -----------------------------
# Variables
# -----------------------------

variable "project_id" {
  type        = string
  description = "Cloud project ID"
}

variable "region" {
  type        = string
  description = "Region for resources"
}

variable "network_id" {
  type        = string
  description = "The ID of the VPC network"
}

variable "private_subnet" {
  type        = string
  description = "The name of the private subnet"
}

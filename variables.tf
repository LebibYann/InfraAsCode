variable "project_id" {
  type        = string
  description = "Cloud project ID"
}

variable "region" {
  type        = string
  description = "Region for resources"
}

variable "bucket_name" {
  type        = string
  description = "Nom du bucket"
}

variable "network_name" {
  type        = string
  description = "Name of the VPC"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR block for the subnet"
}

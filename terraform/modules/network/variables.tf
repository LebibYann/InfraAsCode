# Project

variable "project_id" {
  type        = string
  description = "Cloud project ID"
}

variable "region" {
  type        = string
  description = "Region for resources"
}

# Names

variable "network_name" {
  type        = string
  description = "Name of the vpc network"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
}

# Cidr

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR block for the private subnet"
}
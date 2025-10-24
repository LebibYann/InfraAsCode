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

# ========================================
# Load Balancer Configuration (Optional)
# ========================================

variable "enable_load_balancer" {
  type        = bool
  description = "Activer le Load Balancer HTTPS"
  default     = false
}

variable "lb_name" {
  type        = string
  description = "Nom du load balancer"
  default     = "app"
}

variable "lb_domains" {
  type        = list(string)
  description = "Liste des domaines pour le certificat SSL managé"
  default     = []
}

variable "lb_backend_port" {
  type        = number
  description = "Port du backend service"
  default     = 80
}

variable "lb_health_check_path" {
  type        = string
  description = "Chemin pour le health check"
  default     = "/health"
}

variable "lb_backend_service_id" {
  type        = string
  description = "ID du backend service Kubernetes (NEG)"
  default     = ""
}

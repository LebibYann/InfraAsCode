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

# Database password is now generated automatically by CloudSQL module
# and stored in Secret Manager

variable "cloudsql_tier" {
  type        = string
  description = "Cloud SQL machine tier"
  default     = "db-f1-micro"
}

# -----------------------------
# GKE Node Pool Autoscaling
# -----------------------------

variable "gke_min_node_count" {
  type        = number
  description = "Minimum number of nodes in the app node pool"
  default     = 1
}

variable "gke_max_node_count" {
  type        = number
  description = "Maximum number of nodes in the app node pool"
  default     = 3
}

# -----------------------------
# Application Deployment
# -----------------------------

variable "app_image_repository" {
  type        = string
  description = "Docker image repository for the application"
  default     = "gcr.io/infra-as-code-tek/iac"
}

variable "app_image_tag" {
  type        = string
  description = "Docker image tag for the application"
  default     = "latest"
}

variable "app_min_replicas" {
  type        = number
  description = "Minimum number of application replicas (HPA)"
  default     = 1
}

variable "app_max_replicas" {
  type        = number
  description = "Maximum number of application replicas (HPA)"
  default     = 3
}

variable "app_cpu_target" {
  type        = number
  description = "Target CPU utilization percentage for HPA"
  default     = 70
}

# -----------------------------
# GitHub Runners Configuration
# -----------------------------

# GitHub App Authentication (recommandé - secrets dans Secret Manager)
variable "github_app_id_secret" {
  type        = string
  description = "Nom du secret Secret Manager contenant le GitHub App ID (ex: github-app-id-dev)"
  default     = ""
}

variable "github_installation_id_secret" {
  type        = string
  description = "Nom du secret Secret Manager contenant le GitHub Installation ID (ex: github-installation-id-dev)"
  default     = ""
}

variable "github_private_key_secret" {
  type        = string
  description = "Nom du secret Secret Manager contenant la GitHub App Private Key (ex: github-private-key-dev)"
  default     = ""
}

variable "github_repository_url" {
  type        = string
  description = "URL du repository ou de l'organisation GitHub (ex: https://github.com/lenny-vigeon-dev/IAC)"
  default     = "https://github.com/lenny-vigeon-dev/IAC"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository in format 'owner/repo' (ex: lenny-vigeon-dev/IAC)"
  default     = "lenny-vigeon-dev/IAC"
}

variable "github_organization" {
  type        = string
  description = "GitHub organization or owner name"
  default     = "lenny-vigeon-dev"
}

variable "runner_machine_type" {
  type        = string
  description = "Type de machine pour les nœuds runners"
  default     = "e2-standard-2"
}

variable "runner_disk_size" {
  type        = number
  description = "Taille du disque en GB pour les nœuds runners"
  default     = 50
}

variable "min_runner_nodes" {
  type        = number
  description = "Nombre minimum de nœuds dans le pool runners"
  default     = 1
}

variable "max_runner_nodes" {
  type        = number
  description = "Nombre maximum de nœuds dans le pool runners"
  default     = 5
}

variable "runner_replicas" {
  type        = number
  description = "Nombre de runners déployés (ignoré si autoscaling activé)"
  default     = 1
}

variable "enable_runner_autoscaling" {
  type        = bool
  description = "Activer l'autoscaling des runners basé sur la queue GitHub Actions"
  default     = true
}

variable "min_runner_replicas" {
  type        = number
  description = "Nombre minimum de runners (autoscaler)"
  default     = 0
}

variable "max_runner_replicas" {
  type        = number
  description = "Nombre maximum de runners (autoscaler)"
  default     = 2
}

variable "runner_labels" {
  type        = list(string)
  description = "Labels pour les GitHub runners"
  default     = ["self-hosted", "kubernetes", "gke", "linux", "x64"]
}

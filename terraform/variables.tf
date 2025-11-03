variable "project_id" {
  type        = string
  description = "Cloud project ID"
}

variable "region" {
  type        = string
  description =variable "github_organization" {
  type        = string
  description = "GitHub organization name"
  default     = "your-org"
}ion for resources"
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
  description = "GCR repository for the application image"
  default     = "gcr.io/your-gcp-project/iac"
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

# GitHub App Authentication (recommended - secrets in Secret Manager)
variable "github_app_id_secret" {
  type        = string
  description = "Secret Manager secret name containing the GitHub App ID (e.g.: github-app-id-dev)"
  default     = ""
}

variable "github_installation_id_secret" {
  type        = string
  description = "Secret Manager secret name containing the GitHub Installation ID (e.g.: github-installation-id-dev)"
  default     = ""
}

variable "github_private_key_secret" {
  type        = string
  description = "Secret Manager secret name containing the GitHub App Private Key (e.g.: github-private-key-dev)"
  default     = ""
}

variable "github_repository_url" {
  type        = string
  description = "GitHub repository or organization URL (e.g.: https://github.com/your-org/your-repo)"
  default     = "https://github.com/your-org/your-repo"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository in format 'owner/repo' (e.g.: your-org/your-repo)"
  default     = "your-org/your-repo"
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

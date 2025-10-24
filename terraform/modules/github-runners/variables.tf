variable "cluster_name" {
  type        = string
  description = "Nom du cluster GKE"
}

variable "region" {
  type        = string
  description = "Région GCP"
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "service_account" {
  type        = string
  description = "Service account email pour les nœuds"
}

# ========================================
# Actions Runner Controller Configuration
# ========================================

variable "arc_namespace" {
  type        = string
  description = "Namespace pour Actions Runner Controller"
  default     = "actions-runner-system"
}

variable "github_app_id_secret" {
  type        = string
  description = "Nom du secret Secret Manager contenant le GitHub App ID"
}

variable "github_app_installation_id_secret" {
  type        = string
  description = "Nom du secret Secret Manager contenant le GitHub Installation ID"
}

variable "github_app_private_key_secret" {
  type        = string
  description = "Nom du secret Secret Manager contenant la GitHub App Private Key"
}

# ========================================
# GitHub Runners Configuration
# ========================================

variable "runner_machine_type" {
  type        = string
  description = "Type de machine pour les runners"
  default     = "e2-standard-2"
}

variable "runner_disk_size" {
  type        = number
  description = "Taille du disque en GB pour les runners"
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

variable "github_repository_url" {
  type        = string
  description = "URL du repository GitHub (ex: https://github.com/owner/repo)"
}

variable "runner_replicas" {
  type        = number
  description = "Nombre de runners à déployer (ignoré si autoscaler est activé)"
  default     = 1
}

variable "enable_autoscaling" {
  type        = bool
  description = "Activer l'autoscaling des runners basé sur la queue GitHub"
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

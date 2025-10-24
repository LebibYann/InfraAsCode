variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "europe-west1"
}

variable "collaborators_emails" {
  type        = list(string)
  description = "List of collaborator emails to grant Editor role"
}

variable "teacher_email" {
  type        = string
  description = "Teacher email to grant Viewer role"
}

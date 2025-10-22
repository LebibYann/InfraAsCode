variable "project_id" {
  type        = string
  description = "Cloud project ID"
}

variable "region" {
  type        = string
  description = "Region for resources"
}

variable "collaborators_emails" {
  description = "collaborators GCP email"
  type        = list(string)
}

variable "teacher_email" {
  description = "teacher GCP email"
  type        = string
}
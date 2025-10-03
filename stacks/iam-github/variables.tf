variable "github_owner" {
  description = "Owner of the repository"
  type        = string
}

variable "repository" {
  description = "Name of the Github repository"
  type        = string
}

variable "collaborators_github" {
  description = "GitHub login of the collaborators"
  type        = list(string)
}

variable "teacher_github" {
  description = "GitHub login of the teacher"
  type        = string
}

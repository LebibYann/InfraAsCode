terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = var.github_owner
}

resource "github_repository_collaborator" "collaborators" {
  for_each   = toset(var.collaborators_github)
  repository = var.repository
  username   = each.value
  permission = "admin"
}

resource "github_repository_collaborator" "teacher" {
  repository = var.repository
  username   = var.teacher_github
  permission = "pull"
}
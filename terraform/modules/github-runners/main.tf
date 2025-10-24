# ========================================
# Actions Runner Controller Installation
# ========================================

# Namespace pour Actions Runner Controller
resource "kubernetes_namespace" "arc" {
  metadata {
    name = var.arc_namespace
    labels = {
      name = var.arc_namespace
    }
  }
}

# Récupérer les credentials GitHub App depuis Secret Manager
data "google_secret_manager_secret_version" "github_app_id" {
  secret  = var.github_app_id_secret
  project = var.project_id
}

data "google_secret_manager_secret_version" "github_app_installation_id" {
  secret  = var.github_app_installation_id_secret
  project = var.project_id
}

data "google_secret_manager_secret_version" "github_app_private_key" {
  secret  = var.github_app_private_key_secret
  project = var.project_id
}

# Secret Kubernetes avec les credentials GitHub App
resource "kubernetes_secret" "controller_manager" {
  metadata {
    name      = "controller-manager"
    namespace = kubernetes_namespace.arc.metadata[0].name
  }

  data = {
    github_app_id              = data.google_secret_manager_secret_version.github_app_id.secret_data
    github_app_installation_id = data.google_secret_manager_secret_version.github_app_installation_id.secret_data
    github_app_private_key     = data.google_secret_manager_secret_version.github_app_private_key.secret_data
  }

  type = "Opaque"
}

# Installation du controller via Helm
resource "helm_release" "actions_runner_controller" {
  name       = "actions-runner-controller"
  repository = "https://actions-runner-controller.github.io/actions-runner-controller"
  chart      = "actions-runner-controller"
  version    = "0.23.7"
  namespace  = kubernetes_namespace.arc.metadata[0].name

  set {
    name  = "authSecret.create"
    value = "false"
  }

  set {
    name  = "authSecret.name"
    value = kubernetes_secret.controller_manager.metadata[0].name
  }

  set {
    name  = "authSecret.github_app_id"
    value = data.google_secret_manager_secret_version.github_app_id.secret_data
  }

  set {
    name  = "authSecret.github_app_installation_id"
    value = data.google_secret_manager_secret_version.github_app_installation_id.secret_data
  }

  set_sensitive {
    name  = "authSecret.github_app_private_key"
    value = data.google_secret_manager_secret_version.github_app_private_key.secret_data
  }

  set {
    name  = "syncPeriod"
    value = "1m"
  }

  set {
    name  = "image.tag"
    value = "v0.27.6"
  }

  timeout = 600
  wait    = true

  depends_on = [
    kubernetes_namespace.arc,
    kubernetes_secret.controller_manager
  ]
}

# ========================================
# GitHub Runners Infrastructure
# ========================================

# -----------------------------
# GitHub Runners Node Pool
# -----------------------------

resource "google_container_node_pool" "github_runners" {
  name     = "github-runners-pool"
  cluster  = var.cluster_name
  location = var.region

  node_config {
    machine_type = var.runner_machine_type
    disk_size_gb = var.runner_disk_size
    disk_type    = "pd-standard"
    
    service_account = var.service_account
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      workload-type = "github-runners"
      pool          = "runners"
    }

    # Taints pour que seuls les runners s'exécutent sur ces nœuds
    taint {
      key    = "workload-type"
      value  = "github-runners"
      effect = "NO_SCHEDULE"
    }

    tags = ["gke-runners"]

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  autoscaling {
    min_node_count = var.min_runner_nodes
    max_node_count = var.max_runner_nodes
  }

  management {
    auto_upgrade = true
    auto_repair  = true
  }
}

# -----------------------------
# Namespace pour les GitHub Runners
# -----------------------------

resource "kubernetes_namespace" "github_runners" {
  metadata {
    name = "github-runners"
    labels = {
      name = "github-runners"
    }
  }

  depends_on = [google_container_node_pool.github_runners]
}

# -----------------------------
# Deploy GitHub Runners via Helm Chart
# -----------------------------

resource "helm_release" "github_runners" {
  name       = "github-runners"
  chart      = "${path.module}/../../charts/github-runners"
  namespace  = kubernetes_namespace.github_runners.metadata[0].name
  wait       = true
  timeout    = 300

  # GitHub configuration
  set {
    name  = "github.repository"
    value = replace(var.github_repository_url, "https://github.com/", "")
  }

  # Runner configuration
  set {
    name  = "runner.name"
    value = "iac-runners"
  }

  set {
    name  = "runner.replicas"
    value = var.runner_replicas
  }

  set {
    name  = "runner.ephemeral"
    value = "true"
  }

  set {
    name  = "runner.dockerEnabled"
    value = "true"
  }

  # Labels (en JSON array)
  set {
    name  = "runner.labels"
    value = "{${join(",", var.runner_labels)}}"
  }

  # Autoscaling
  set {
    name  = "autoscaling.enabled"
    value = var.enable_autoscaling
  }

  set {
    name  = "autoscaling.minReplicas"
    value = var.min_runner_replicas
  }

  set {
    name  = "autoscaling.maxReplicas"
    value = var.max_runner_replicas
  }

  # Service Account
  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.github_runner.metadata[0].name
  }

  depends_on = [
    kubernetes_namespace.github_runners,
    kubernetes_service_account.github_runner,
    helm_release.actions_runner_controller
  ]
}

# -----------------------------
# ServiceAccount pour les runners
# -----------------------------

resource "kubernetes_service_account" "github_runner" {
  metadata {
    name      = "github-runner"
    namespace = kubernetes_namespace.github_runners.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "github_runner" {
  metadata {
    name = "github-runner"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/exec"]
    verbs      = ["create"]
  }
}

resource "kubernetes_cluster_role_binding" "github_runner" {
  metadata {
    name = "github-runner"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.github_runner.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.github_runner.metadata[0].name
    namespace = kubernetes_namespace.github_runners.metadata[0].name
  }
}

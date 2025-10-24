# -----------------------------
# Enable Required Services
# -----------------------------
variable "required_services" {
  type = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "storage.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}

resource "google_project_service" "enabled" {
  for_each = toset(var.required_services)

  project = var.project_id
  service = each.value

  disable_on_destroy         = false
  disable_dependent_services = false
}

# -----------------------------
# Network Module
# -----------------------------

module "network" {
  source              = "./modules/network"
  project_id          = var.project_id
  region              = var.region
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  network_name        = var.network_name

  depends_on = [
    google_project_service.enabled
  ]
}

# -----------------------------
# Reserve IP range for Private Services Access (Cloud SQL)
# -----------------------------

resource "google_compute_global_address" "private_services_ip" {
  name          = "google-managed-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.network.vpc_id

  depends_on = [
    module.network
  ]
}

# -----------------------------
# VPC Peering with Google Services (for Cloud SQL)
# -----------------------------

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = module.network.vpc_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services_ip.name]

  # Prevent deletion until deletion_policy is set
  deletion_policy = "ABANDON"

  depends_on = [
    google_compute_global_address.private_services_ip,
    google_project_service.enabled
  ]
}

# -----------------------------
# IAM Module
# -----------------------------

module "iam" {
  source     = "./modules/iam"
  project_id = var.project_id
  environment = var.environment

  # GitHub Actions configuration
  github_repository    = var.github_repository
  github_organization  = var.github_organization
  
  # Kubernetes application configuration
  app_name                   = "iac"
  k8s_namespace              = "iac"
  k8s_service_account_name   = "iac-sa"

  depends_on = [
    google_project_service.enabled
  ]
}

# -----------------------------
# GKE Module
# -----------------------------

module "gke" {
  source          = "./modules/gke"
  project_id      = var.project_id
  region          = var.region
  network_id      = module.network.vpc_id
  subnetwork      = module.network.private_subnet_id
  service_account = module.iam.gke_sa_email
  min_node_count  = var.gke_min_node_count
  max_node_count  = var.gke_max_node_count

  depends_on = [
    module.network,
    module.iam,
    google_project_service.enabled,
    module.network
  ]
}

# -----------------------------
# Workload Identity Binding (requires GKE cluster to exist)
# TEMPORARILY COMMENTED - Will be added after cluster creation
# -----------------------------

# resource "google_service_account_iam_member" "k8s_app_workload_identity" {
#   service_account_id = module.iam.k8s_app_sa_name
#   role               = "roles/iam.workloadIdentityUser"
#   member             = "serviceAccount:${var.project_id}.svc.id.goog[iac/iac-sa]"

#   depends_on = [
#     module.gke  # Wait for GKE cluster to create the identity pool
#   ]

#   lifecycle {
#     # Recreate after the new cluster is created (when cluster is tainted)
#     create_before_destroy = false
#   }
# }

# -----------------------------
# Cloud SQL Module
# -----------------------------

module "cloudsql" {
  source                       = "./modules/cloudsql"
  project_id                   = var.project_id
  region                       = var.region
  instance_name                = "postgres-instance"
  tier                         = var.cloudsql_tier
  network_id                   = module.network.vpc_id
  private_vpc_connection       = google_service_networking_connection.private_vpc_connection
  database_name                = var.db_name
  db_user                      = var.db_user
  environment                  = var.environment
  gke_service_account_email    = module.iam.gke_sa_email
  deletion_protection          = false

  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_project_service.enabled,
    module.iam
  ]
}

# -----------------------------
# Storage Module
# -----------------------------

module "storage" {
  source      = "./modules/storage"
  bucket_name = var.bucket_name
  region      = var.region

  depends_on = [
    google_project_service.enabled
  ]
}

# -----------------------------
# Cert-Manager Module (requis pour ARC)
# -----------------------------

module "cert_manager" {
  source = "./modules/cert-manager"

  depends_on = [
    module.gke
  ]
}

# -----------------------------
# GitHub Runners (with Actions Runner Controller)
# -----------------------------

module "github_runners" {
  source = "./modules/github-runners"

  # GKE Configuration
  cluster_name    = module.gke.cluster_name
  region          = var.region
  service_account = module.iam.gke_sa_email
  project_id      = var.project_id

  # Actions Runner Controller - GitHub App Secrets
  arc_namespace                     = "actions-runner-system"
  github_app_id_secret              = var.github_app_id_secret
  github_app_installation_id_secret = var.github_installation_id_secret
  github_app_private_key_secret     = var.github_private_key_secret

  # Runner Deployment Configuration
  github_repository_url = var.github_repository_url
  runner_replicas       = var.runner_replicas
  runner_labels         = var.runner_labels

  # Autoscaling configuration
  enable_autoscaling  = var.enable_runner_autoscaling
  min_runner_replicas = var.min_runner_replicas
  max_runner_replicas = var.max_runner_replicas

  # Node Pool Configuration
  runner_machine_type = var.runner_machine_type
  runner_disk_size    = var.runner_disk_size
  min_runner_nodes    = var.min_runner_nodes
  max_runner_nodes    = var.max_runner_nodes

  depends_on = [
    module.gke,
    module.cert_manager
  ]
}

# -----------------------------
# Namespace pour l'application
# -----------------------------

resource "kubernetes_namespace" "iac" {
  metadata {
    name = "iac"
    labels = {
      name = "iac"
    }
  }

  depends_on = [
    module.gke
  ]
}

# -----------------------------
# Helm Release - Deploy Application
# -----------------------------

# Data source pour récupérer l'IP du LoadBalancer une fois créé
data "kubernetes_service" "iac_service" {
  metadata {
    name      = "iac-service"
    namespace = kubernetes_namespace.iac.metadata[0].name
  }

  depends_on = [helm_release.iac_app]
}

resource "helm_release" "iac_app" {
  name       = "iac"
  chart      = "${path.module}/charts/iac"
  namespace  = kubernetes_namespace.iac.metadata[0].name
  create_namespace = false

  timeout = 300  # 5 minutes
  wait    = false  # Ne pas attendre que tous les pods soient ready
  wait_for_jobs = false
  
  force_update = true
  cleanup_on_fail = true

  values = [
    yamlencode({
      image = {
        repository = var.app_image_repository
        tag        = var.app_image_tag
        pullPolicy = "Always"
      }
      
      replicaCount = var.app_min_replicas
      
      service = {
        type       = "LoadBalancer"
        port       = 80
        targetPort = 3000
      }
      
      ingress = {
        enabled = false
      }
      
      autoscaling = {
        enabled                        = true
        minReplicas                    = var.app_min_replicas
        maxReplicas                    = var.app_max_replicas
        targetCPUUtilizationPercentage = var.app_cpu_target
      }
      
      resources = {
        requests = {
          memory = "256Mi"
          cpu    = "250m"
        }
        limits = {
          memory = "512Mi"
          cpu    = "500m"
        }
      }
      
      env = {
        PORT             = "3000"
        NODE_ENV         = var.environment
        DATABASE_HOST    = module.cloudsql.private_ip_address
        DATABASE_PORT    = "5432"
        DATABASE_NAME    = var.db_name
        DATABASE_USER    = module.cloudsql.db_user
        DATABASE_PASSWORD = module.cloudsql.db_password
      }
      
      namespace = "iac"
    })
  ]

  depends_on = [
    module.gke,
    module.cloudsql
  ]
}

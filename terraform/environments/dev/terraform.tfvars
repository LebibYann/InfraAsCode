project_id          = "infra-as-code-tek"
region              = "europe-west1"
environment         = "dev"
public_subnet_cidr  = "10.20.0.0/24"
private_subnet_cidr = "10.10.0.0/16"
bucket_name         = "lenny-iac-bucket-dev"
network_name        = "vpc-network"

# Cloud SQL Configuration
db_name       = "app_database"
db_user       = "app_user"
cloudsql_tier = "db-f1-micro"

# GKE Node Pool Autoscaling (dev: smaller scale)
gke_min_node_count = 1
gke_max_node_count = 2

# Application Deployment
app_image_repository = "gcr.io/infra-as-code-tek/iac"
app_image_tag        = "dev"
app_min_replicas     = 1
app_max_replicas     = 2
app_cpu_target       = 70

# GitHub Configuration
# IMPORTANT: Les secrets GitHub App sont stockés dans Google Secret Manager
# Suivez le guide SETUP-GITHUB-RUNNERS.md pour créer la GitHub App et stocker les secrets
# Les noms des secrets ci-dessous doivent correspondre à ceux créés dans Secret Manager
github_app_id_secret         = "github-app-id-dev"
github_installation_id_secret = "github-installation-id-dev"
github_private_key_secret    = "github-private-key-dev"

github_repository_url = "https://github.com/lenny-vigeon-dev/IAC"
github_repository     = "lenny-vigeon-dev/IAC"
github_organization   = "lenny-vigeon-dev"
# GitHub Runners Configuration
runner_machine_type   = "e2-standard-2"
runner_disk_size      = 50
min_runner_nodes      = 0  # Scale to zero quand pas de workflows
max_runner_nodes      = 2  # Maximum 2 nodes

# Autoscaling des runners
enable_runner_autoscaling = true
min_runner_replicas       = 0  # Scale to zero
max_runner_replicas       = 2  # Maximum 2 runners simultanés
runner_replicas           = 0  # Valeur initiale (ignorée avec autoscaling)
runner_labels             = ["self-hosted", "kubernetes", "gke", "linux", "x64", "dev"]

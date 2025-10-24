project_id          = "lenny-iac-prd"
region              = "europe-west1"
environment         = "prd"
network_name        = "student-vpc"
public_subnet_cidr  = "10.30.0.0/24"
private_subnet_cidr = "10.20.0.0/16"
bucket_name         = "lenny-iac-bucket-prd"

# Cloud SQL Configuration
db_name       = "app_database"
db_user       = "app_user"
cloudsql_tier = "db-g1-small"  # Slightly better for production

# GKE Node Pool Autoscaling (prd: larger scale)
gke_min_node_count = 2
gke_max_node_count = 4

# Application Deployment
app_image_repository = "gcr.io/lenny-iac-prd/iac"
app_image_tag        = "latest"
app_min_replicas     = 2
app_max_replicas     = 5
app_cpu_target       = 70

# GitHub Configuration
# IMPORTANT: Les secrets GitHub App sont stockés dans Google Secret Manager
# Suivez le guide SETUP-GITHUB-RUNNERS.md pour créer la GitHub App et stocker les secrets
# Les noms des secrets ci-dessous doivent correspondre à ceux créés dans Secret Manager
github_app_id_secret         = "github-app-id-prd"
github_installation_id_secret = "github-installation-id-prd"
github_private_key_secret    = "github-private-key-prd"

github_repository_url = "https://github.com/lenny-vigeon-dev/IAC"
github_repository     = "lenny-vigeon-dev/IAC"
github_organization   = "lenny-vigeon-dev"

# GitHub Runners Configuration
runner_machine_type   = "e2-standard-4"  # Plus puissant pour production
runner_disk_size      = 100  # Plus d'espace disque pour production
min_runner_nodes      = 0  # Scale to zero quand pas de workflows
max_runner_nodes      = 3  # Maximum 3 nodes pour production

# Autoscaling des runners
enable_runner_autoscaling = true
min_runner_replicas       = 0  # Scale to zero
max_runner_replicas       = 3  # Maximum 3 runners simultanés
runner_replicas           = 0  # Valeur initiale (ignorée avec autoscaling)
runner_labels             = ["self-hosted", "kubernetes", "gke", "linux", "x64", "prd"]

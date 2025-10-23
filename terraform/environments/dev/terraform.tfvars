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
# db_password is now managed via Secret Manager (see docs/SECRET_MANAGER.md)
cloudsql_tier = "db-f1-micro"

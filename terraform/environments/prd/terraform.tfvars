project_id          = "lenny-iac-prd"
region              = "europe-west1"
environment         = "prd"
network_name        = "student-vpc"
public_subnet_cidr  = "10.0.0.0/24"
private_subnet_cidr = "10.0.0.0/16"
bucket_name         = "lenny-iac-bucket-prd"

# Cloud SQL Configuration
db_name       = "app_database"
db_user       = "app_user"
# db_password is now managed via Secret Manager (see docs/SECRET_MANAGER.md)
cloudsql_tier = "db-g1-small"  # Slightly better for production

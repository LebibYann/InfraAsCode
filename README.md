# 🏗️ Infrastructure as Code (IAO) - Terraform

Complete GCP infrastructure for deploying a containerized application with GKE, Cloud SQL, and private networking.

## 📋 Table of Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Modules](#modules)
- [IAM Stacks](#iam-stacks)
- [Environments](#environments)
- [Best Practices](#best-practices)

## 🏛️ Architecture

The infrastructure deploys:

- **VPC Network** with public and private subnets
- **Cloud NAT** for Internet access from private resources
- **GKE Cluster** private with 2 node pools (app + runners)
- **Cloud SQL PostgreSQL** with private IP
- **Cloud Storage** for artifacts
- **Service Accounts** with minimal permissions
- **Firewall Rules** for security

See `Architecture.png` for the complete diagram.

## ✅ Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.6.0
- [gcloud CLI](https://cloud.google.com/sdk/docs/install)
- GCP account with sufficient permissions
- GCS bucket for Terraform state

### GCP Configuration

```bash
# Authentication
gcloud auth application-default login

# Set project
gcloud config set project YOUR_PROJECT_ID

# Create bucket for state (one time only)
gsutil mb -l europe-west1 gs://YOUR-TERRAFORM-STATE-BUCKET
gsutil versioning set on gs://YOUR-TERRAFORM-STATE-BUCKET
```

## 📁 Project Structure

```
.
├── terraform/                   # 🔷 Terraform Infrastructure
│   ├── main.tf                 # Main configuration
│   ├── variables.tf            # Global variables
│   ├── outputs.tf              # Global outputs
│   ├── versions.tf             # Provider versions
│   ├── README.md
│   │
│   ├── environments/           # Environment-specific configuration
│   │   ├── dev/
│   │   │   ├── backend.tfvars
│   │   │   └── terraform.tfvars
│   │   └── prd/
│   │       ├── backend.tfvars
│   │       └── terraform.tfvars
│   │
│   ├── modules/                # Reusable modules
│   │   ├── network/           # VPC, subnets, firewalls
│   │   ├── nat/               # Cloud NAT
│   │   ├── gke/               # GKE cluster and node pools
│   │   ├── cloudsql/          # Cloud SQL PostgreSQL
│   │   ├── iam/               # Infrastructure service accounts
│   │   └── storage/           # Cloud Storage buckets
│   │
│   └── stacks/                # Isolated IAM stacks
│       ├── iam-github/        # Permissions GitHub repository
│       └── iam-gcp/           # GCP user permissions
│
├── kubernetes/                 # 🔷 Kubernetes Manifests
│   ├── base/                  # Base configuration
│   │   ├── namespace.yaml
│   │   ├── configmap.yaml
│   │   ├── secret.yaml
│   │   └── kustomization.yaml
│   ├── overlays/              # Environment-specific overlays
│   │   ├── dev/
│   │   └── prd/
│   ├── monitoring/            # Observability
│   └── README.md
│
├── application/                # 🔷 Application NestJS
│   ├── src/
## 🧲 Modules

### Network Module
Creates the VPC, subnets, and firewall rules.

**Resources:**
- VPC Network
- Public Subnet
- Private Subnet (with secondary IP ranges for GKE)
- Firewall Rules

### NAT Module
Configures Cloud NAT to allow private resources to access the Internet.

### GKE Module
Deploys a private GKE cluster with autoscaling.

**Resources:**
- GKE Cluster (private)
- Node Pool "app" (1-3 nodes)
- Node Pool "runners" (0-2 nodes)

### CloudSQL Module
Creates a Cloud SQL PostgreSQL instance with private IP.

**Resources:**
- Cloud SQL Instance
- Database
- User

### IAM Module
Creates the service accounts for the infrastructure.

### Storage Module
Creates a Cloud Storage bucket for artifacts.
Edit `terraform/environments/dev/terraform.tfvars`:

```hcl
project_id          = "your-gcp-project-id"
region              = "europe-west1"
network_name        = "vpc-network"
public_subnet_cidr  = "10.20.0.0/24"
private_subnet_cidr = "10.10.0.0/16"
bucket_name         = "your-bucket-name"
db_name             = "app_database"
db_user             = "app_user"
# Do not put password here, see Secrets section
```

### 3. Initialization

```bash
cd terraform/
terraform init -backend-config=environments/dev/backend.tfvars
```

### 4. Planning

```bash
# Development environment
terraform plan -var-file=environments/dev/terraform.tfvars

# Production environment
terraform plan -var-file=environments/prd/terraform.tfvars
```

### 5. Deployment

```bash
# Dev
terraform apply -var-file=environments/dev/terraform.tfvars

# Production
terraform apply -var-file=environments/prd/terraform.tfvars
```

### 6. Secrets Management

**Option 1: Environment variable** (recommended for dev)
```bash
export TF_VAR_db_password="your-secure-password"
terraform apply -var-file=environments/dev/terraform.tfvars
```

**Option 2: Secrets file** (do not commit)
```bash
# Create secrets.tfvars (added to .gitignore)
echo 'db_password = "your-secure-password"' > secrets.tfvars

# Use
terraform apply -var-file=environments/dev/terraform.tfvars -var-file=secrets.tfvars
```

**Option 3: Secret Manager** (recommended for production)
- Create secret in Secret Manager
- Uncomment code in `terraform/modules/cloudsql/main.tf`

 

## 🔐 IAM Stacks

Permissions are managed separately in `stacks/`:

### iam-github
Manages collaborator permissions on the GitHub repository.

```bash
cd terraform/stacks/iam-github
terraform init
terraform apply -var-file=common.tfvars
```

### iam-gcp
Manages user permissions on the GCP project.

```bash
cd terraform/stacks/iam-gcp
terraform init -backend-config=init.config
terraform apply -var-file=common.tfvars
```

## 🌍 Environments

| Environment | File        | Usage             |
|-------------|-------------|-------------------|
| Development | `dev.tfvars`| Tests and development |
| Production  | `prd.tfvars`| Stable production |

## 📊 Outputs

After deployment, retrieve the information:

```bash
cd terraform/

# Tous les outputs
terraform output

# Specific output
terraform output gke_cluster_name
terraform output cloudsql_connection_name

# Format JSON
terraform output -json
```

## 🛠️ Useful Commands

### Terraform

```bash
cd terraform/

# Formater le code
terraform fmt -recursive

# Valider la syntaxe
terraform validate

# Lister les ressources
terraform state list

# Destroy the infrastructure
terraform destroy -var-file=environments/dev/terraform.tfvars
```

### Kubernetes

```bash
# Deploy with Kustomize
kubectl apply -k kubernetes/overlays/dev/

# Check deployments
kubectl get all -n iac
kubectl rollout status deployment/iac -n iac

# Logs
kubectl logs -n iac -l app=iac --tail=100 -f
```

## 🔄 Connect to the GKE Cluster

```bash
# Retrieve credentials
gcloud container clusters get-credentials iac-cluster \
  --region europe-west1 \
  --project YOUR_PROJECT_ID

# Verify the connection
kubectl get nodes
kubectl get pods -A
```

## 🗄️ Connect to Cloud SQL

```bash
# Via Cloud SQL Proxy
cloud_sql_proxy -instances=PROJECT_ID:REGION:INSTANCE_NAME=tcp:5432

# From a GKE pod (with Workload Identity)
# See k8s/cloudsql-connection.yaml
```

## 📚 Best Practices

See `TERRAFORM_BEST_PRACTICES.md` for:

- Modular structure
- Secrets management
- Versioning
- CI/CD
- Security
- And much more!

## 🐛 Troubleshooting

### Error: API not enabled

```bash
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
```

### Error: Quota exceeded

Check and increase quotas in the GCP console:
- Compute Engine API
- Kubernetes Engine API

### Error: Insufficient permissions

Check your account's IAM roles:
```bash
gcloud projects get-iam-policy YOUR_PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:YOUR_EMAIL"
```

## 🤝 Contributing

1. Create a branch for your changes
2. Format code: `terraform fmt -recursive`
3. Validate: `terraform validate`
4. Test with `dev.tfvars`
5. Open a Pull Request

## 📝 License

This project is for educational use.

## 👥 Authors

- Lenny (Linnchoeuh)

## 🔗 Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Google Cloud Terraform Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Cloud SQL Best Practices](https://cloud.google.com/sql/docs/postgres/best-practices)

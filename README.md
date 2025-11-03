# 🏗️ Infrastructure as Code (IAC)

Complete GCP infrastructure for deploying a NestJS application with GKE, Cloud SQL, GitHub Actions Runners, and automated CI/CD.

## 📋 Table of Contents

- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Projecgcloud container clusters get-credentials iac-cluster 
  --region europe-west1 
  --project your-gcp-project-dev  # or your-gcp-project-prd
```tructure](#project-structure)
- [Automated Deployment](#automated-deployment)
- [CI/CD Workflows](#cicd-workflows)
- [Modules](#modules)
- [Environments](#environments)
- [Troubleshooting](#troubleshooting)

## 🏛️ Architecture

The infrastructure deploys a complete production-ready stack:

- **VPC Network** with public and private subnets + Cloud NAT
- **GKE Cluster** (private) with 2 node pools:
  - **App Pool**: 2-4 nodes e2-standard-4 (dev: 1-2)
  - **Runners Pool**: 0-3 nodes e2-standard-4 (autoscaling)
- **Cloud SQL PostgreSQL 15** with private IP and VPC peering
- **GitHub Actions Runners** self-hosted on GKE
- **Actions Runner Controller (ARC)** for runner orchestration
- **Cert-Manager** for TLS certificate management
- **LoadBalancer** for application ingress
- **Secret Manager** for sensitive data
- **Workload Identity** for secure GCP authentication

See `docs/Architecture.png` for the complete diagram.

## ⚡ Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.9.0
- [gcloud CLI](https://cloud.google.com/sdk/docs/install)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- GCP account with Owner or Editor role
- GitHub repository with Actions enabled

### One-Time Setup

```bash
# 1. Authenticate with GCP
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID

# 2. Enable required APIs
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  iam.googleapis.com

# 3. Create GitHub App secrets in Secret Manager
```bash
# For dev
echo -n "YOUR_APP_ID" | gcloud secrets create github-app-id-dev --data-file=- --project=your-gcp-project-dev
echo -n "YOUR_INSTALLATION_ID" | gcloud secrets create github-installation-id-dev --data-file=- --project=your-gcp-project-dev
cat github-private-key.pem | gcloud secrets create github-private-key-dev --data-file=- --project=your-gcp-project-dev

# For prd
echo -n "YOUR_APP_ID" | gcloud secrets create github-app-id-prd --data-file=- --project=your-gcp-project-prd
echo -n "YOUR_INSTALLATION_ID" | gcloud secrets create github-installation-id-prd --data-file=- --project=your-gcp-project-prd
cat github-private-key.pem | gcloud secrets create github-private-key-prd --data-file=- --project=your-gcp-project-prd
```
```

## 📁 Project Structure

```
.
├── terraform/                   # 🔷 Terraform Infrastructure
│   ├── main.tf                 # Main orchestration
│   ├── variables.tf            # Global variables
│   ├── outputs.tf              # Infrastructure outputs
│   ├── versions.tf             # Provider configuration
│   ├── deploy.sh               # 🚀 Automated deployment script
│   ├── destroy.sh              # 🗑️ Safe destruction script
│   │
│   ├── environments/           # Environment-specific config
│   │   ├── dev/
│   │   │   ├── backend.tfvars      # State backend config
│   │   │   ├── terraform.tfvars    # Dev variables
│   │   │   └── output.tfplan       # Generated plan
│   │   └── prd/
│   │       ├── backend.tfvars
│   │       ├── terraform.tfvars
│   │       └── output.tfplan
│   │
│   ├── modules/                # 8 Terraform modules
│   │   ├── cert-manager/       # TLS certificate automation
│   │   ├── cloudsql/          # PostgreSQL database
│   │   ├── gke/               # Kubernetes cluster + node pools
│   │   ├── github-runners/    # Self-hosted runners + ARC
│   │   ├── iam/               # Service accounts + RBAC
│   │   ├── network/           # VPC + NAT + LoadBalancer
│   │   ├── secrets/           # Secret Manager integration
│   │   └── storage/           # Cloud Storage buckets
│   │
│   ├── charts/                # Helm charts
│   │   ├── iac/               # Application chart
│   │   └── github-runners/    # Runners chart
│   │
│   └── stacks/                # Isolated IAM stacks
│       ├── iam-github/        # GitHub repo permissions
│       └── iam-gcp/           # GCP user permissions
│
├── .github/workflows/          # 🔷 CI/CD Automation
│   ├── terraform.yml          # Infrastructure deployment
│   ├── destroy.yml            # Infrastructure destruction
│   └── terraform-destroy.yml  # Legacy destroy workflow
│
├── application/                # 🔷 NestJS Application
│   ├── src/
## 🚀 Automated Deployment

### Using Deploy Scripts (Recommended)

The easiest way to deploy infrastructure:

```bash
# Deploy to development
./deploy.sh dev

# Deploy to production
./deploy.sh prd
```

The script automatically:
1. ✅ Validates Terraform configuration
2. 🔄 Initializes backend with correct state
3. 📋 Creates execution plan
4. 🚀 Applies changes (with confirmation)
5. 📊 Displays outputs (cluster name, app URL, etc.)

### Using Destroy Scripts

Safe infrastructure destruction:

```bash
# Destroy development (confirmation required)
./destroy.sh dev

# Destroy production (requires typing "destroy-production")
./destroy.sh prd
```

### Manual Deployment

If you prefer manual control:

```bash
cd terraform/

# 1. Initialize
terraform init -backend-config=environments/dev/backend.tfvars

# 2. Plan
terraform plan -var-file=environments/dev/terraform.tfvars -out=environments/dev/output.tfplan

# 3. Apply
terraform apply environments/dev/output.tfplan

# 4. Get outputs
terraform output
```

## � CI/CD Workflows

### Terraform Deployment (`terraform.yml`)

Triggered on push to `main` branch:

1. **Plan Job** (matrix: dev + prd)
   - Runs on self-hosted GKE runners
   - Creates Terraform plans for both environments
   - Uploads plans as artifacts

2. **Apply Jobs** (parallel after plan)
   - `apply-dev`: Deploys to dev (auto-approved)
   - `apply-prd`: Deploys to prd (may require approval)
   - Uses Workload Identity for authentication
   - Downloads and applies corresponding plan

### Infrastructure Destruction (`destroy.yml`)

Manual workflow for safe infrastructure teardown:

1. Requires manual trigger via GitHub Actions UI
2. Confirmation input required: "yes-destroy-infrastructure"
3. Validates confirmation before proceeding
4. Destroys infrastructure with proper cleanup

### Self-Hosted Runners

All workflows run on GKE-hosted runners with labels:
- `self-hosted`
- `kubernetes`
- `gke`
- `linux`
- `x64`
- `dev` or `prd` (environment-specific)

Runner pools auto-scale from 0 to 2 (dev) or 0 to 3 (prd) nodes.

## 🌍 Environments

### Development (your-gcp-project-dev)

| Resource | Configuration |
|----------|---------------|
| **Project** | `your-gcp-project-dev` |
| **Region** | `europe-west1` |
| **VPC CIDRs** | Public: `10.20.0.0/24`, Private: `10.10.0.0/16` |
| **GKE App Pool** | 1-2 nodes, e2-standard-4 |
| **GKE Runners Pool** | 0-2 nodes, e2-standard-2, autoscaling |
| **Cloud SQL** | db-f1-micro, 10GB, regional HA |
| **App Replicas** | 1 (no HPA) |
| **Runner Labels** | `[self-hosted, kubernetes, gke, linux, x64, dev]` |

### Production (your-gcp-project-prd)

| Resource | Configuration |
|----------|---------------|
| **Project** | `your-gcp-project-prd` |
| **Region** | `europe-west1` |
| **VPC CIDRs** | Public: `10.30.0.0/24`, Private: `10.20.0.0/16` |
| **GKE App Pool** | 2-4 nodes, e2-standard-4 |
| **GKE Runners Pool** | 0-3 nodes, e2-standard-4, autoscaling |
| **Cloud SQL** | db-g1-small, 10GB, regional HA |
| **App Replicas** | 1 (no HPA) |
| **Runner Labels** | `[self-hosted, kubernetes, gke, linux, x64, prd]` |

## 📊 Outputs

After deployment, get infrastructure details:

```bash
cd terraform/

# All outputs
terraform output

# Key outputs
terraform output app_url              # http://<LoadBalancer-IP>/api/v1
terraform output gke_cluster_name     # iac-cluster
terraform output cloudsql_connection_name
terraform output app_loadbalancer_ip

# JSON format
terraform output -json
```

### Quick Access Commands

```bash
# Connect to GKE cluster
gcloud container clusters get-credentials iac-cluster \
  --region europe-west1 \
  --project infra-as-code-tek  # or lenny-iac-prd

# Check application health
curl http://$(terraform output -raw app_loadbalancer_ip)/api/v1/health

# View runner pods
kubectl get pods -n github-runners

# Check runner autoscaling
kubectl get nodes -l workload-type=github-runners
```

## 🧩 Modules

### cert-manager
Installs cert-manager via Helm for automated TLS certificate management.

### cloudsql
- PostgreSQL 15 instance with private IP
- VPC peering for secure connectivity
- Automated backups (30 days retention)
- Point-in-time recovery enabled
- High availability (regional)

### gke
- Private GKE cluster (public endpoint)
- Workload Identity enabled
- 2 node pools: app + runners
- Network Policy enabled
- Shielded nodes (secure boot)
- Auto-upgrade and auto-repair

### github-runners
**Unified module combining:**
- Actions Runner Controller (ARC) via Helm
- Runner infrastructure and RBAC
- Dedicated node pool with taints
- Auto-scaling from 0 to minimize costs
- GitHub App authentication via Secret Manager

### iam
- Service accounts for GKE nodes and app
- Workload Identity binding
- Cloud SQL Client permissions
- Secret Manager accessor roles

### network
**Unified module combining:**
- VPC with public/private subnets
- Cloud NAT for private node egress
- Optional global HTTPS load balancer
- Firewall rules for security

### secrets
- Secret Manager configuration
- GitHub App credentials
- Database passwords
- Access policies

### storage
- Cloud Storage buckets for artifacts
- Versioning enabled
- Lifecycle policies

## 🐛 Troubleshooting

### State Lock Issues

```bash
# If Terraform state is locked
cd terraform/
terraform force-unlock -force <LOCK_ID>
```

### Application Not Accessible

```bash
# Wait for LoadBalancer IP assignment (takes 2-5 minutes)
kubectl get svc -n iac iac-service -w

# Check pod status
kubectl get pods -n iac
kubectl describe pod -n iac <pod-name>

# View application logs
kubectl logs -n iac -l app=iac --tail=100
```

### Runners Not Starting

```bash
# Check ARC controller
kubectl get pods -n actions-runner-system
kubectl logs -n actions-runner-system -l app.kubernetes.io/name=actions-runner-controller

# Check runner pods
kubectl get pods -n github-runners
kubectl describe pod -n github-runners <runner-pod>

# Verify GitHub App secrets
gcloud secrets versions access latest --secret=github-app-id-dev
```

### API Not Enabled

```bash
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com \
  iam.googleapis.com \
  servicenetworking.googleapis.com
```

### Workload Identity Issues

```bash
# Verify service account binding
gcloud iam service-accounts get-iam-policy \
  k8s-app@PROJECT_ID.iam.gserviceaccount.com

# Check Kubernetes service account annotation
kubectl describe sa iac-sa -n iac
```

For more troubleshooting guides, see [`DEPLOYMENT.md`](DEPLOYMENT.md).

## 📚 Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Comprehensive deployment guide
- **[terraform/README.md](terraform/README.md)** - Terraform configuration details
- **[docs/architecture.md](docs/architecture.md)** - Architecture deep dive
- **[docs/runbooks/](docs/runbooks/)** - Operational runbooks

## 🎯 Key Features

✅ **Fully Automated** - Deploy/destroy scripts with zero manual steps  
✅ **Multi-Environment** - Dev and prd with separate configurations  
✅ **Self-Hosted Runners** - Cost-effective GitHub Actions on GKE  
✅ **Auto-Scaling** - Both infrastructure and application scale dynamically  
✅ **High Availability** - Regional Cloud SQL, multiple GKE nodes  
✅ **Security First** - Workload Identity, private networking, Secret Manager  
✅ **Cost Optimized** - Runners scale to 0 when idle  
✅ **Production Ready** - Monitoring, logging, health checks, and backups

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Test on dev environment: `./deploy.sh dev`
4. Format code: `terraform fmt -recursive`
5. Validate: `terraform validate`
6. Open a Pull Request

## 👥 Authors

- Your Team

## 🔗 Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Google Cloud Terraform Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Actions Runner Controller](https://github.com/actions/actions-runner-controller)

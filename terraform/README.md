# 📂 Terraform Infrastructure

Modern Infrastructure as Code for GCP with Kubernetes, automated CI/CD, and self-hosted GitHub Actions runners.

## 🚀 Quick Start

### Automated Deployment (Recommended)

```bash
# Deploy to development
./deploy.sh dev

# Deploy to production  
./deploy.sh prd

# Destroy infrastructure
./destroy.sh dev  # or prd
```

### Manual Deployment

```bash
# Initialize
terraform init -backend-config=environments/dev/backend.tfvars

# Plan
terraform plan -var-file=environments/dev/terraform.tfvars \
  --parallelism=20 -out=environments/dev/output.tfplan

# Apply
terraform apply environments/dev/output.tfplan

# Outputs
terraform output
```

## 📁 Structure

```
terraform/
├── main.tf                  # Root orchestration
├── variables.tf             # Global variables
├── outputs.tf               # Infrastructure outputs
├── versions.tf              # Provider configuration
├── deploy.sh                # 🚀 Automated deployment script
├── destroy.sh               # 🗑️ Safe destruction script
│
├── environments/            # Environment-specific configuration
│   ├── dev/
│   │   ├── backend.tfvars      # GCS state backend config
│   │   ├── terraform.tfvars    # Dev variables
│   │   └── output.tfplan       # Generated plan (gitignored)
│   └── prd/
│       ├── backend.tfvars
│       ├── terraform.tfvars
│       └── output.tfplan
│
├── modules/                 # 8 Terraform modules
│   ├── cert-manager/        # TLS certificate automation
│   ├── cloudsql/           # PostgreSQL database
│   ├── gke/                # Kubernetes cluster
│   ├── github-runners/     # Self-hosted runners + ARC
│   ├── iam/                # Service accounts + RBAC
│   ├── network/            # VPC + NAT + LoadBalancer
│   ├── secrets/            # Secret Manager integration
│   └── storage/            # Cloud Storage buckets
│
├── charts/                  # Helm charts
│   ├── iac/                # Application Helm chart
│   └── github-runners/     # Runners Helm chart
│
└── stacks/                  # Isolated IAM stacks
    ├── iam-github/         # GitHub repo permissions
    └── iam-gcp/            # GCP user permissions
```

## 🏗️ What Gets Deployed

This Terraform configuration deploys a complete production-ready infrastructure:

### Core Infrastructure
1. **VPC Network**
   - Public subnet (10.20.0.0/24 dev, 10.30.0.0/24 prd)
   - Private subnet (10.10.0.0/16 dev, 10.20.0.0/16 prd)
   - Cloud NAT for private node egress
   - Optional global HTTPS load balancer

2. **GKE Cluster** (Private)
   - Workload Identity enabled
   - Network Policy enabled
   - Shielded nodes (secure boot + integrity monitoring)
   - 2 node pools:
     - **App Pool**: 1-2 nodes (dev), 2-4 nodes (prd), e2-standard-4
     - **Runners Pool**: 0-2 nodes (dev), 0-3 nodes (prd), autoscaling

3. **Cloud SQL PostgreSQL 15**
   - Private IP with VPC peering
   - Regional high availability
   - Automated backups (30 days retention)
   - Point-in-time recovery
   - Performance insights enabled
   - db-f1-micro (dev), db-g1-small (prd)

### Application Layer
4. **NestJS Application** (via Helm)
   - Kubernetes Deployment
   - Service (LoadBalancer type)
   - Health checks (liveness + readiness)
   - Environment-specific configuration
   - Workload Identity for GCP access

### GitHub Integration
5. **Self-Hosted Runners**
   - Actions Runner Controller (ARC) v0.23.7
   - Runner infrastructure via Helm
   - Dedicated node pool with taints
   - Auto-scaling from 0 (cost optimization)
   - GitHub App authentication
   - Labels: `[self-hosted, kubernetes, gke, linux, x64, dev/prd]`

6. **Cert-Manager**
   - Automated TLS certificate management
   - CRD installation
   - Required for ARC

### Security & Secrets
7. **IAM & Workload Identity**
   - Service accounts: gke-nodes, k8s-app
   - Cloud SQL Client permissions
   - Secret Manager accessor roles
   - Workload Identity bindings

8. **Secret Manager**
   - GitHub App credentials (ID, installation ID, private key)
   - Database passwords
   - Access policies per environment

## 📊 Environment Comparison

| Component | Development | Production |
|-----------|-------------|------------|
| **Project** | infra-as-code-tek | lenny-iac-prd |
| **Public CIDR** | 10.20.0.0/24 | 10.30.0.0/24 |
| **Private CIDR** | 10.10.0.0/16 | 10.20.0.0/16 |
| **App Nodes** | 1-2 × e2-standard-4 | 2-4 × e2-standard-4 |
| **Runner Nodes** | 0-2 × e2-standard-2 | 0-3 × e2-standard-4 |
| **Runner Disk** | 50GB | 100GB |
| **Cloud SQL** | db-f1-micro | db-g1-small |
| **SQL Disk** | 10GB | 10GB |
| **Secrets Prefix** | dev | prd |
| **Runner Labels** | ..., dev | ..., prd |

## 📝 Usage Examples

### Development Deployment

```bash
# Option 1: Automated script
./deploy.sh dev

# Option 2: Manual
terraform init -backend-config=environments/dev/backend.tfvars
terraform plan -var-file=environments/dev/terraform.tfvars \
  --parallelism=20 -out=environments/dev/output.tfplan
terraform apply environments/dev/output.tfplan
```

### Production Deployment

```bash
# Option 1: Automated script (recommended)
./deploy.sh prd

# Option 2: Manual
terraform init -backend-config=environments/prd/backend.tfvars
terraform plan -var-file=environments/prd/terraform.tfvars \
  --parallelism=20 -out=environments/prd/output.tfplan
terraform apply environments/prd/output.tfplan
```

### Accessing the Deployed Application

```bash
# Get all outputs
terraform output

# Get LoadBalancer IP
terraform output app_loadbalancer_ip

# Test application health
curl http://$(terraform output -raw app_loadbalancer_ip)/api/v1/health

# Connect to GKE cluster
gcloud container clusters get-credentials iac-cluster \
  --region europe-west1 \
  --project $(terraform output -raw project_id)

# View application pods
kubectl get pods -n iac

# View runner pods (may be 0 if autoscaled down)
kubectl get pods -n github-runners

# View all services
kubectl get svc -A
```

## 🧩 Modules

### cert-manager
Installs cert-manager v1.13.2 via Helm for automated TLS certificate management (required for ARC).

**Resources:**
- Kubernetes namespace: `cert-manager`
- Helm release with CRD installation

### cloudsql
PostgreSQL 15 database with enterprise features.

**Resources:**
- Cloud SQL instance (regional HA)
- Database: `app_database`
- User: `app_user`
- VPC peering for private connectivity
- Backup configuration (daily, 30 days retention, PITR)
- Performance insights

### gke
Private Kubernetes cluster with security best practices.

**Resources:**
- GKE cluster (Workload Identity, Network Policy, Shielded Nodes)
- App node pool (autoscaling, e2-standard-4)
- Workload Identity configuration

### github-runners (Unified Module)
Complete self-hosted runner infrastructure.

**Resources:**
- Namespace: `actions-runner-system`
- Namespace: `github-runners`
- ARC Helm release (controller)
- Runners Helm release (workers)
- Runner node pool (dedicated, tainted, autoscaling from 0)
- RBAC: ServiceAccount, ClusterRole, ClusterRoleBinding
- GitHub App secrets integration

### iam
Service accounts and permissions.

**Resources:**
- Service account: `gke-nodes` (for GKE node pool)
- Service account: `k8s-app` (for application pods)
- Workload Identity binding (Kubernetes SA → GCP SA)
- Cloud SQL Client role
- Secret Manager accessor role

### network (Unified Module)
Complete networking stack.

**Resources:**
- VPC network
- Public subnet
- Private subnet (with GKE secondary ranges)
- Cloud NAT (always enabled)
- Cloud Router
- Optional: Global HTTPS Load Balancer with SSL

### secrets
Secret Manager integration.

**Resources:**
- GitHub App ID secret (per environment)
- GitHub Installation ID secret
- GitHub Private Key secret
- Access policies

### storage
Cloud Storage buckets for artifacts.

**Resources:**
- Bucket with versioning
- Lifecycle policies
- IAM bindings

## 🔧 Scripts

### deploy.sh

Automated deployment with safety checks and colored output.

```bash
./deploy.sh <environment>

# Features:
# - Validates Terraform syntax
# - Initializes correct backend
# - Creates execution plan
# - Requires confirmation before apply
# - Displays outputs after deployment
# - Colored output for better readability
```

### destroy.sh

Safe infrastructure destruction with confirmations.

```bash
./destroy.sh <environment>

# Safety features:
# - Dev: Simple confirmation
# - Prd: Must type "destroy-production"
# - Shows what will be destroyed
# - Refreshes state before destroy
# - Cleanup steps after destruction
```

## 📤 Outputs

After successful deployment:

```bash
terraform output
```

**Available outputs:**
- `app_url` - Application URL (http://<IP>/api/v1)
- `app_loadbalancer_ip` - LoadBalancer IP address
- `gke_cluster_name` - GKE cluster name
- `gke_cluster_endpoint` - GKE API endpoint (sensitive)
- `cloudsql_connection_name` - Cloud SQL connection string
- `cloudsql_private_ip` - Cloud SQL private IP
- `app_access_info` - Complete access information

## 🏛️ Architecture Highlights

### Security
- **Workload Identity**: No service account keys, GKE pods authenticate to GCP via IAM
- **Private GKE**: Nodes have no public IPs, egress via Cloud NAT
- **VPC Peering**: Cloud SQL accessible only from GKE (no Cloud SQL Proxy needed)
- **Secret Manager**: All sensitive data stored securely
- **Shielded Nodes**: Secure boot and integrity monitoring enabled
- **Network Policy**: Ready for pod-level network segmentation

### Cost Optimization
- **Runner Autoscaling**: Scale to 0 when no jobs running
- **Node Autoscaling**: GKE scales based on pod requests
- **Right-Sized Instances**: e2-standard-2/4 for optimal cost/performance
- **Regional Resources**: Single region (europe-west1) deployment

### High Availability
- **Regional Cloud SQL**: Automatic failover within region
- **Multi-Zone GKE**: Nodes distributed across 3 zones
- **Automated Backups**: Daily backups with 30-day retention
- **Point-in-Time Recovery**: Restore to any second in last 7 days

## ✅ Best Practices

### Development Workflow
- ✅ Always run `terraform plan` before `apply`
- ✅ Use `--parallelism=20` for faster operations
- ✅ Test changes in `dev` before deploying to `prd`
- ✅ Review generated plans in `environments/*/output.tfplan`
- ✅ Use scripts for consistent deployments

### Security
- ✅ Never commit secrets to Git (use Secret Manager)
- ✅ Use Workload Identity (no service account keys)
- ✅ Enable state encryption and versioning
- ✅ Separate tfvars for each environment
- ✅ Use GitHub App for runner authentication (not PAT)

### Infrastructure
- ✅ Enable auto-upgrade and auto-repair for node pools
- ✅ Use Network Policy for pod-level security
- ✅ Monitor costs with budget alerts
- ✅ Tag all resources with `managed_by = terraform`
- ✅ Document all custom configurations

### CI/CD
- ✅ Use self-hosted runners on GKE (cost savings)
- ✅ Implement environment protection for prd
- ✅ Store Terraform plans as artifacts
- ✅ Require manual approval for prd deployments
- ✅ Use Workload Identity for GCP authentication in workflows

## 🗑️ Cleanup

### Using Scripts (Recommended)

```bash
# Destroy development
./destroy.sh dev

# Destroy production (requires confirmation)
./destroy.sh prd
```

### Manual Cleanup

```bash
# Development
terraform destroy -var-file=environments/dev/terraform.tfvars

# Production
terraform destroy -var-file=environments/prd/terraform.tfvars
```

⚠️ **Warning**: This will delete:
- GKE cluster and all running workloads
- Cloud SQL database and all data
- VPC network and subnets
- All persistent volumes
- LoadBalancer and external IPs

**Retained after destroy:**
- Terraform state in GCS
- Secret Manager secrets
- Cloud Storage buckets (if not empty)

## 🐛 Troubleshooting

### State Lock

```bash
# List current locks
gsutil ls -L gs://YOUR-STATE-BUCKET/terraform/state/ENV/

# Force unlock
terraform force-unlock -force <LOCK_ID>
```

### Provider Errors

```bash
# Re-initialize providers
terraform init -upgrade

# Clear provider cache
rm -rf .terraform/
terraform init -backend-config=environments/dev/backend.tfvars
```

### Module Dependency Issues

If you encounter "chicken-and-egg" errors with GKE cluster data sources:

- The `versions.tf` uses `try()` to handle cluster creation
- Workload Identity binding is created after GKE module
- Run `terraform apply` twice if needed (first creates cluster, second binds identity)

### Runner Issues

```bash
# Check ARC logs
kubectl logs -n actions-runner-system -l app.kubernetes.io/name=actions-runner-controller

# Verify secrets
gcloud secrets versions access latest --secret=github-app-id-dev --project=infra-as-code-tek

# Check runner node pool
kubectl get nodes -l workload-type=github-runners
```

## 📚 Additional Resources

- **[DEPLOYMENT.md](../DEPLOYMENT.md)** - Complete deployment guide
- **[docs/architecture.md](../docs/architecture.md)** - Architecture deep dive
- **[docs/runbooks/](../docs/runbooks/)** - Operational procedures

## 🤝 Contributing

1. Create feature branch from `main`
2. Make changes and test on `dev`
3. Run `terraform fmt -recursive`
4. Run `terraform validate`
5. Submit PR with plan output
6. Get approval before merging

---

**Built with** ❤️ **using Terraform and best practices**


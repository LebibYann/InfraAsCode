# 📚 Documentation

Technical documentation for the Infrastructure as Code project.

## 📖 Available documents

### Architecture
- **[architecture.md](./architecture.md)** - Detailed architecture description
- **[Architecture.png](./Architecture.png)** - Architecture diagram

### Runbooks
- **[deployment.md](./runbooks/deployment.md)** - Complete deployment guide
- **[troubleshooting.md](./runbooks/troubleshooting.md)** - Troubleshooting guide

## 🏗️ Architecture

The infrastructure deploys on GCP:
- VPC Network with public/private subnets
- Private GKE Cluster with autoscaling
- Cloud SQL PostgreSQL (private IP)
- Cloud Storage for artifacts
- Cloud NAT for Internet access

See [architecture.md](./architecture.md) for details.

## 🚀 Deployment

See [runbooks/deployment.md](./runbooks/deployment.md) for:
- Deploying the Terraform infrastructure
- Configuring Kubernetes
- Updating the application
- Performing a rollback

## �️ Troubleshooting

See [runbooks/troubleshooting.md](./runbooks/troubleshooting.md) for:
- Common Terraform errors
- GKE and Kubernetes issues
- Cloud SQL connectivity
- Network and permissions issues

## 📝 Other resources

Back to the root:
- **[../README.md](../README.md)** - Main documentation
- **[../TERRAFORM_BEST_PRACTICES.md](../TERRAFORM_BEST_PRACTICES.md)** - Best practices
- **[../MIGRATION_GUIDE.md](../MIGRATION_GUIDE.md)** - Migration guide
- **[../QUICK_START.md](../QUICK_START.md)** - Quick start

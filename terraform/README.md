# 📂 Terraform Infrastructure

Infrastructure as Code for deployment on Google Cloud Platform.

## Structure

```
terraform/
├── versions.tf              # Terraform and provider versions
├── main.tf                  # Main configuration
├── variables.tf             # Global variables
├── outputs.tf               # Outputs
├── environments/           # Per-environment configuration
│   ├── dev/
│   │   ├── backend.tfvars
│   │   └── terraform.tfvars
│   └── prd/
│       ├── backend.tfvars
│       └── terraform.tfvars
├── modules/                # Reusable modules
└── stacks/                 # Isolated IAM stacks
```

## Usage

### Development

```bash
# Initialize
terraform init -backend-config=environments/dev/backend.tfvars

# Plan
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply
terraform apply -var-file=environments/dev/terraform.tfvars
```

### Production

```bash
# Initialize
terraform init -backend-config=environments/prd/backend.tfvars

# Plan
terraform plan -var-file=environments/prd/terraform.tfvars

# Apply
terraform apply -var-file=environments/prd/terraform.tfvars
```

## Modules

- **network**: VPC, subnets, firewalls
- **nat**: Cloud NAT
- **gke**: Kubernetes cluster
- **cloudsql**: PostgreSQL database
- **iam**: Service Accounts
- **storage**: Cloud Storage buckets

## Best Practices

- Always use `terraform plan` before `apply`
- Use workspaces or separate `.tfvars` files for environments
- Never commit secrets in code
- Enable versioning on the state bucket
- Use remote state with GCS

See [TERRAFORM_BEST_PRACTICES.md](../TERRAFORM_BEST_PRACTICES.md) for more details.

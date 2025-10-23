# Environment Production

Terraform configuration for the production environment.

## Usage

From the `terraform/` directory:

```bash
# Initialize
terraform init -backend-config=environments/prd/backend.tfvars

# Plan
terraform plan -var-file=environments/prd/terraform.tfvars

# Apply (with caution!)
terraform apply -var-file=environments/prd/terraform.tfvars
```

## Variables

The variables specific to this environment are defined in `terraform.tfvars`.

## Backend

The Terraform state is stored in GCS: `lenny-iac-tfstates-bucket` with the prefix `terraform/state/prd`.

## ⚠️ Warning

This environment is intended for production. All changes must be carefully planned and tested in development first.

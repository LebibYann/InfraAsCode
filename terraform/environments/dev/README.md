# Environment Development

Terraform configuration for the development environment.

## Usage

From the `terraform/` directory:

```bash
# Initialize
terraform init -backend-config=environments/dev/backend.tfvars

# Plan
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply
terraform apply -var-file=environments/dev/terraform.tfvars
```

## Variables

The variables specific to this environment are defined in `terraform.tfvars`.

## Backend

The Terraform state is stored in GCS: `lenny-iac-tfstates-bucket` with the prefix `terraform/state/dev`.

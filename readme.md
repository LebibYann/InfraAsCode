# Infra as code epitech project

## Quick start

### Dev environment
How to start:
> Google Service are automatically enabled when you create a new project.
```
terraform init -backend-config="./backends/dev.config"
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

How to destroy:
```
terraform destroy -var-file="dev.tfvars"
```
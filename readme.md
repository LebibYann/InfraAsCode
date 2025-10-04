# Infra as code epitech project

## Quick start

### Dev environment
How to start:
> Google Service are automatically enabled when you create a new project.
```
terraform init -backend-config="./init.config"
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```
> If the bucket for the tfstate is not created, you can create it manually or run the following command:
```
gsutil mb -p $PROJECT_ID -l europe-west1 gs://lenny-iac-tfstates-bucket
```

How to destroy:
```
terraform destroy -var-file="dev.tfvars"
```
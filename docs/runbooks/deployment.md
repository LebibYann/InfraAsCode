# Deployment Guide

## Prerequisites

- Terraform >= 1.6.0
- Configured gcloud CLI
- kubectl installed
- Access to the GCP project with appropriate permissions

## Deployment steps

### 1. Terraform infrastructure

#### Development environment

```bash
cd terraform/

# Initialize with the dev backend
terraform init -backend-config=environments/dev/backend.tfvars

# Review the plan
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply
terraform apply -var-file=environments/dev/terraform.tfvars
```

#### Production environment

```bash
cd terraform/

# Initialize with the prd backend
terraform init -backend-config=environments/prd/backend.tfvars

# Review the plan
terraform plan -var-file=environments/prd/terraform.tfvars

# Apply
terraform apply -var-file=environments/prd/terraform.tfvars
```

### 2. Kubernetes configuration

#### Retrieve GKE credentials

```bash
# Dev
gcloud container clusters get-credentials iac-cluster \
  --region europe-west1 \
  --project infra-as-code-tek

# Prd
gcloud container clusters get-credentials iac-cluster \
  --region europe-west1 \
  --project lenny-iac-prd
```

#### Deploy with Kustomize

```bash
# Dev
kubectl apply -k kubernetes/overlays/dev/

# Production
kubectl apply -k kubernetes/overlays/prd/
```

### 3. Verification

```bash
# Check pods
kubectl get pods -n iac

# Check services
kubectl get svc -n iac

# Check logs
kubectl logs -n iac -l app=iac --tail=100
```

## Application update

```bash
# 1. Build and push the new image
docker build -t gcr.io/PROJECT_ID/iac:TAG ./application
docker push gcr.io/PROJECT_ID/iac:TAG

# 2. Update the deployment
kubectl set image deployment/iac \
  iac=gcr.io/PROJECT_ID/iac:TAG \
  -n iac

# Or redeploy with Kustomize
kubectl apply -k kubernetes/overlays/dev/
```

## Rollback

```bash
# View deployment history
kubectl rollout history deployment/iac -n iac

# Roll back to the previous version
kubectl rollout undo deployment/iac -n iac

# Roll back to a specific revision
kubectl rollout undo deployment/iac --to-revision=2 -n iac
```

## Destruction

⚠️ **Warning**: This operation is irreversible!

```bash
# 1. Delete Kubernetes resources
kubectl delete -k kubernetes/overlays/dev/

# 2. Destroy the Terraform infrastructure
cd terraform/
terraform destroy -var-file=environments/dev/terraform.tfvars
```

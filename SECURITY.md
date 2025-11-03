# 🔐 Security & Configuration Guide

## ⚠️ Important Security Notice

This repository contains Infrastructure as Code that **does NOT include sensitive data** in the public repository. Before using this code, you need to configure your own environment variables and secrets.

## 📋 Files to Configure

### 1. Terraform Variables Files

Copy the example files and fill them with your own values:

```bash
# Development environment
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
cp terraform/environments/dev/backend.tfvars.example terraform/environments/dev/backend.tfvars

# Production environment
cp terraform/environments/prd/terraform.tfvars.example terraform/environments/prd/terraform.tfvars
cp terraform/environments/prd/backend.tfvars.example terraform/environments/prd/backend.tfvars

# IAM stacks
cp terraform/stacks/iam-gcp/dev.tfvars.example terraform/stacks/iam-gcp/dev.tfvars
cp terraform/stacks/iam-gcp/prd.tfvars.example terraform/stacks/iam-gcp/prd.tfvars
cp terraform/stacks/iam-github/common.tfvars.example terraform/stacks/iam-github/common.tfvars
```

### 2. Required Configuration

Update the following in your `.tfvars` files:

#### **terraform/environments/dev/terraform.tfvars**
```hcl
project_id          = "your-gcp-project-dev"
bucket_name         = "your-bucket-name-dev"
app_image_repository = "gcr.io/your-gcp-project-dev/iac"
github_repository_url = "https://github.com/your-org/your-repo"
github_repository     = "your-org/your-repo"
github_organization   = "your-org"
```

#### **terraform/environments/prd/terraform.tfvars**
```hcl
project_id          = "your-gcp-project-prd"
bucket_name         = "your-bucket-name-prd"
app_image_repository = "gcr.io/your-gcp-project-prd/iac"
github_repository_url = "https://github.com/your-org/your-repo"
github_repository     = "your-org/your-repo"
github_organization   = "your-org"
```

#### **terraform/environments/{dev,prd}/backend.tfvars**
```hcl
bucket = "your-tfstate-bucket"
```

#### **terraform/stacks/iam-gcp/{dev,prd}.tfvars**
```hcl
project_id           = "your-gcp-project"
collaborators_emails = ["user1@example.com", "user2@example.com"]
teacher_email        = "teacher@example.com"
```

#### **terraform/stacks/iam-github/common.tfvars**
```hcl
github_owner         = "your-github-username"
repository           = "your-org/your-repo"
collaborators_github = ["user1", "user2", "user3"]
```

### 3. GitHub Secrets to Configure

For GitHub Actions to work, configure these secrets in your repository settings:

- `GCP_PROJECT_ID_DEV` - Your GCP development project ID
- `GCP_PROJECT_ID_PRD` - Your GCP production project ID
- `GCP_SA_KEY_DEV` - Service account key for dev (JSON)
- `GCP_SA_KEY_PRD` - Service account key for prd (JSON)
- `WORKLOAD_IDENTITY_PROVIDER_DEV` - Workload Identity Provider for dev
- `WORKLOAD_IDENTITY_PROVIDER_PRD` - Workload Identity Provider for prd

### 4. Google Secret Manager Secrets

Create the following secrets in Google Secret Manager:

```bash
# Development
echo -n "YOUR_APP_ID" | gcloud secrets create github-app-id-dev --data-file=- --project=your-gcp-project-dev
echo -n "YOUR_INSTALLATION_ID" | gcloud secrets create github-installation-id-dev --data-file=- --project=your-gcp-project-dev
cat github-private-key.pem | gcloud secrets create github-private-key-dev --data-file=- --project=your-gcp-project-dev

# Production
echo -n "YOUR_APP_ID" | gcloud secrets create github-app-id-prd --data-file=- --project=your-gcp-project-prd
echo -n "YOUR_INSTALLATION_ID" | gcloud secrets create github-installation-id-prd --data-file=- --project=your-gcp-project-prd
cat github-private-key.pem | gcloud secrets create github-private-key-prd --data-file=- --project=your-gcp-project-prd
```

## 🚫 What NOT to Commit

**NEVER commit these files:**

- `*.tfvars` (except `*.tfvars.example`)
- `backend.tfvars` (except `backend.tfvars.example`)
- Service account keys (`*-sa-key.json`)
- Private keys (`*.pem`)
- `.env` files
- GitHub tokens
- Any file containing passwords, API keys, or credentials

## ✅ Verification Checklist

Before deploying, verify:

- [ ] All `.tfvars` files are created from examples
- [ ] `.gitignore` excludes all sensitive files
- [ ] No secrets are hardcoded in the code
- [ ] GitHub secrets are configured
- [ ] Google Secret Manager secrets are created
- [ ] Service accounts have correct permissions
- [ ] Backend bucket for Terraform state exists

## 📚 Additional Resources

- [Google Cloud Secret Manager](https://cloud.google.com/secret-manager/docs)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)

## 🆘 Support

If you need help configuring the project, please refer to:
- `README.md` - Main project documentation
- `DEPLOYMENT.md` - Deployment guide
- `docs/runbooks/` - Operational runbooks

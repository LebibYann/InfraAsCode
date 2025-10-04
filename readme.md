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

## OIDC Setup for CI
> Only do this step if the CI does not work

### Google Cloud Console


### 1. Ensure all these services are enabled:
> Make sure to replace `your_gcp_project_id` with your actual GCP project ID.
```
gcloud services enable iamcredentials.googleapis.com sts.googleapis.com iam.googleapis.com --project your_gcp_project_id
```

#### 2. Create the workload identity pool:
```
gcloud iam workload-identity-pools create "github-pool-ci" --location="global" --display-name="GitHub OIDC Pool CI"
```
#### 2.1. To check if the pool has been created:
```
gcloud iam workload-identity-pools describe "github-pool-ci" --location="global"
```

#### 3. Create the OIDC provider
> (You must change the value for `assertion.repository_owner` (can be an organisation or a user) in `--attribute-condition` parameter):
```
gcloud iam workload-identity-pools providers create-oidc "github-provider-ci" --workload-identity-pool="github-pool-ci" --location="global" --display-name="GitHub Provider CI" --issuer-uri="https://token.actions.githubusercontent.com" --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref,attribute.actor=assertion.actor" --attribute-condition="assertion.repository_owner=='your-orga-or-user'"
```
#### 3.1 To check if the provider has been created:
```
gcloud iam workload-identity-pools providers list --workload-identity-pool="github-pool-ci" --location="global"
```

#### 4. Create the service account:
```
gcloud iam service-accounts create terraform-ci-dev --display-name="Terraform CI (dev)"
```
#### 4.1 To check its been created
> (Must show an address called `terraform-ci-dev@your_gcp_project_id.iam.gserviceaccount.com`):
```
gcloud iam service-accounts list --project your_gcp_project_id
```

#### 5. Grant the necessary roles to the service account:
> Make sure to replace `your_gcp_project_id` with your actual GCP project ID.
```
gcloud projects add-iam-policy-binding your_gcp_project_id --member="serviceAccount:terraform-ci-dev@your_gcp_project_id.iam.gserviceaccount.com" --role="roles/editor"
```

#### 6. Allowing Github to endorse its service account:
> Make sure to replace `<OWNER>` and `<REPO>` with the actual owner and repository name as well as `your_gcp_project_id` with your actual GCP project ID and `your-pool-name-that-you-can-get-with-2.1-command` with your actual pool name.
```
gcloud iam service-accounts add-iam-policy-binding terraform-ci-dev@your_gcp_project_id.iam.gserviceaccount.com --role="roles/iam.workloadIdentityUser" --member="principalSet://iam.googleapis.com/your-pool-name-that-you-can-get-with-2.1-command/attribute.repository/<OWNER>/<REPO>"
```

#### 7 Configure the GitHub Actions workflow
```yml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: your-provider-name-that-you-can-get-with-3.1-command
    service_account: your-service-account-that-you-can-get-with-4.1-command

- name: Setup gcloud CLI
  uses: google-github-actions/setup-gcloud@v2
  with:
    project_id: your_gcp_project_id
```
# Troubleshooting Guide

## Common issues

### 1. Terraform

#### Error: API not enabled

```
Error: Error creating Instance: googleapi: Error 403: Compute Engine API has not been used
```

**Solution:**
```bash
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
```

#### Error: State lock

```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# Identify the lock
gsutil ls gs://lenny-iac-tfstates-bucket/terraform/state/dev/

# Force unlock (use with caution!)
terraform force-unlock LOCK_ID
```

#### Error: Backend configuration

```
Error: Backend initialization required
```

**Solution:**
```bash
terraform init -reconfigure -backend-config=environments/dev/backend.tfvars
```

### 2. GKE

#### Pods in CrashLoopBackOff

```bash
# Check logs
kubectl logs -n iac POD_NAME

# Describe the pod to see events
kubectl describe pod -n iac POD_NAME

# Common causes:
# - Misconfiguration (environment variables)
# - Failed database connection
# - Corrupted Docker image
```

#### Can't connect to the cluster

```bash
# Check credentials
gcloud container clusters list

# Retrieve credentials again
gcloud container clusters get-credentials iac-cluster \
  --region europe-west1 \
  --project infra-as-code-tek

# Verify the connection
kubectl cluster-info
kubectl get nodes
```

#### Service not accessible

```bash
# Check the service
kubectl get svc -n iac

# Check endpoints
kubectl get endpoints -n iac

# Check firewall rules
gcloud compute firewall-rules list

# For NodePort, verify the port is open
# For LoadBalancer, wait for the external IP
kubectl get svc -n iac -w
```

### 3. Cloud SQL

#### Can't connect to the database

```bash
# Verify the instance is running
gcloud sql instances list

# Verify private connection
gcloud sql instances describe postgres-instance

# Test connection from a pod
kubectl run -it --rm debug \
  --image=postgres:15 \
  --restart=Never \
  -- psql -h PRIVATE_IP -U app_user -d app_database
```

#### Connect via Cloud SQL Proxy

```bash
# Download the proxy
wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy
chmod +x cloud_sql_proxy

# Connect
./cloud_sql_proxy -instances=PROJECT_ID:REGION:INSTANCE_NAME=tcp:5432

# In another terminal
psql -h 127.0.0.1 -U app_user -d app_database
```

### 4. IAM permissions

#### Error: Permission denied

```bash
# Check current permissions
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:YOUR_EMAIL"

# Add a permission (example)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:YOUR_EMAIL" \
  --role="roles/container.admin"
```

### 5. Network

#### NAT Gateway not working

```bash
# Check NAT
gcloud compute routers nats list --router=nat-router --region=europe-west1

# Check NAT logs
gcloud logging read "resource.type=nat_gateway" --limit=50
```

#### VPC Peering issue

```bash
# Check peering
gcloud compute networks peerings list

# Check reserved IP range
gcloud compute addresses list --global --filter="purpose=VPC_PEERING"
```

## Diagnostic commands

### Logs

```bash
# Terraform logs
export TF_LOG=DEBUG
terraform plan -var-file=environments/dev/terraform.tfvars

# Kubernetes logs
kubectl logs -n iac -l app=iac --tail=100 -f

# Cloud SQL logs
gcloud sql operations list --instance=postgres-instance

# GKE logs
gcloud logging read "resource.type=k8s_cluster" --limit=50
```

### Resource state

```bash
# Terraform
terraform state list
terraform show

# Kubernetes
kubectl get all -n iac
kubectl get events -n iac --sort-by='.lastTimestamp'

# GCP
gcloud compute instances list
gcloud sql instances list
gcloud container clusters list
```

## Contacts and escalation

For unresolved issues:

1. Check Google Cloud documentation
2. Review detailed logs
3. Contact GCP support if needed

## Useful resources

- [Terraform GCP Provider Docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Troubleshooting](https://cloud.google.com/kubernetes-engine/docs/troubleshooting)
- [Cloud SQL Troubleshooting](https://cloud.google.com/sql/docs/postgres/troubleshooting)

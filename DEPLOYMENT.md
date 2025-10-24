# IAO - Infrastructure Deployment Guide

## 📋 Table des matières

- [Scripts locaux](#scripts-locaux)
- [GitHub Actions Workflows](#github-actions-workflows)
- [Environnements](#environnements)
- [Prérequis](#prérequis)

---

## 🖥️ Scripts locaux

### Déploiement

Le script `deploy.sh` permet de déployer l'infrastructure localement.

```bash
# Déployer dev
./deploy.sh dev

# Déployer dev sans confirmation
./deploy.sh dev --auto-approve

# Déployer production
./deploy.sh prd

# Déployer production sans confirmation
./deploy.sh prd --auto-approve
```

**Étapes du script :**
1. ✅ Validation de la configuration Terraform
2. 🔧 Initialisation avec le backend approprié
3. 📊 Création du plan d'exécution
4. 🚀 Application des changements

### Destruction

Le script `destroy.sh` permet de détruire l'infrastructure.

```bash
# Détruire dev
./destroy.sh dev

# Détruire dev sans confirmation
./destroy.sh dev --auto-approve

# Détruire production (nécessite confirmation manuelle)
./destroy.sh prd
```

**⚠️ Attention :** La destruction de production requiert de taper `destroy-production` pour confirmer.

---

## 🤖 GitHub Actions Workflows

### Workflow de Déploiement (`terraform.yml`)

**Déclencheurs :**
- Push sur `main` (paths: `terraform/**`, `.github/workflows/terraform.yml`)
- Pull Request vers `main`

**Jobs :**

#### 1. `terraform-plan` (Matrix: dev + prd)
Exécuté sur tous les push et PR :
- Initialise Terraform
- Valide la configuration
- Crée un plan d'exécution
- Upload le plan en artifact

#### 2. `terraform-apply-dev`
Exécuté uniquement sur push vers `main` :
- Télécharge le plan dev
- Applique les changements sur l'environnement dev
- Utilise l'environment GitHub `dev`

#### 3. `terraform-apply-prd`
Exécuté uniquement sur push vers `main` :
- Télécharge le plan prd
- Applique les changements sur l'environnement production
- Utilise l'environment GitHub `prd` (peut nécessiter une approbation)

**Configuration des environments GitHub :**
```yaml
# Settings → Environments → dev
# - Aucune protection requise (déploiement automatique)

# Settings → Environments → prd
# - Required reviewers: Activer et ajouter des reviewers
# - Deployment branches: Only protected branches
```

### Workflow de Destruction (`destroy.yml`)

**Déclencheur :** Manuel via `workflow_dispatch`

**Inputs requis :**
- `environment`: Choix entre `dev` ou `prd`
- `confirm`: Doit taper `destroy` pour confirmer

**Utilisation :**
1. Aller sur GitHub → Actions → "Terraform Destroy"
2. Cliquer "Run workflow"
3. Sélectionner l'environnement
4. Taper `destroy` dans le champ de confirmation
5. Cliquer "Run workflow"

**Jobs :**

#### 1. `validate-confirmation`
- Vérifie que la confirmation est correcte
- Affiche un warning pour la production

#### 2. `terraform-destroy`
- Initialise Terraform
- Refresh l'état
- Crée un plan de destruction
- Détruit l'infrastructure
- Nettoie les fichiers de plan

---

## 🌍 Environnements

### Dev (`infra-as-code-tek`)

**Configuration :**
- Project ID: `infra-as-code-tek`
- Region: `europe-west1`
- VPC: `vpc-network`
- Public Subnet: `10.20.0.0/24`
- Private Subnet: `10.10.0.0/16`
- GKE Nodes: 1-2 (e2-standard-4)
- Runners: 0-2 (e2-standard-2, 50GB)
- Cloud SQL: `db-f1-micro`

**Runners Labels:**
```
[self-hosted, kubernetes, gke, linux, x64, dev]
```

### Prd (`lenny-iac-prd`)

**Configuration :**
- Project ID: `lenny-iac-prd`
- Region: `europe-west1`
- VPC: `student-vpc`
- Public Subnet: `10.30.0.0/24`
- Private Subnet: `10.20.0.0/16`
- GKE Nodes: 2-4 (e2-standard-4)
- Runners: 0-3 (e2-standard-4, 100GB)
- Cloud SQL: `db-g1-small`

**Runners Labels:**
```
[self-hosted, kubernetes, gke, linux, x64, prd]
```

---

## 📦 Prérequis

### Pour les scripts locaux

1. **Terraform** >= 1.9.0
   ```bash
   terraform version
   ```

2. **gcloud CLI** configuré
   ```bash
   gcloud auth login
   gcloud config set project <project-id>
   ```

3. **kubectl** installé
   ```bash
   kubectl version --client
   ```

4. **Accès GCP** avec les permissions nécessaires :
   - Compute Admin
   - Kubernetes Engine Admin
   - Cloud SQL Admin
   - Storage Admin
   - Secret Manager Admin
   - Service Account Admin

### Pour GitHub Actions

1. **Workload Identity Federation** configuré
   - Pool: `github-pool-ci` (dev) / `github-pool-prd` (prd)
   - Provider: `github-provider-ci` / `github-provider-prd`

2. **Service Accounts**
   - Dev: `terraform-ci-dev@infra-as-code-tek.iam.gserviceaccount.com`
   - Prd: À configurer dans le workflow

3. **GitHub Secrets** (si nécessaire)
   - Configurés via Workload Identity (recommandé)
   - Ou via secrets traditionnels

4. **Self-hosted runners** déployés
   - Labels: `[self-hosted, kubernetes, gke, linux, x64]`
   - Namespace: `github-runners`

---

## 🔐 Secrets GitHub App (pour les runners)

Les secrets suivants doivent être créés dans Google Secret Manager :

### Dev
- `github-app-id-dev`
- `github-installation-id-dev`
- `github-private-key-dev`

### Prd
- `github-app-id-prd`
- `github-installation-id-prd`
- `github-private-key-prd`

---

## 🚀 Workflow typique

### Développement
```bash
# 1. Faire des changements dans terraform/
vim terraform/main.tf

# 2. Tester localement
./deploy.sh dev

# 3. Vérifier l'infrastructure
kubectl get pods -n iac
curl http://<app-url>/api/v1/health

# 4. Commit et push
git add .
git commit -m "feat: update infrastructure"
git push origin feature-branch

# 5. Créer une PR
# GitHub Actions exécutera terraform-plan pour dev et prd

# 6. Merger dans main
# GitHub Actions déploiera automatiquement dev et prd
```

### Production
```bash
# Le déploiement prd est automatique sur merge dans main
# Mais peut nécessiter une approbation selon la config de l'environment GitHub

# Pour détruire (attention !) :
# 1. Aller sur GitHub Actions
# 2. Workflow "Terraform Destroy"
# 3. Run workflow → prd → destroy → Run
```

---

## 📊 Monitoring

### Vérifier l'infrastructure

```bash
# Cluster GKE
kubectl get nodes
kubectl get pods -A

# Application
kubectl get pods -n iac
kubectl get svc -n iac
kubectl logs -n iac -l app=iac

# Runners
kubectl get pods -n github-runners
kubectl get pods -n actions-runner-system

# Cloud SQL
gcloud sql instances list
gcloud sql databases list --instance=postgres-instance
```

### Outputs Terraform

```bash
cd terraform
terraform output app_url
terraform output gke_cluster_name
terraform output cloudsql_connection_name
```

---

## 🆘 Troubleshooting

### Erreur de lock Terraform
```bash
cd terraform
terraform force-unlock <LOCK_ID>
```

### Cluster non accessible
```bash
gcloud container clusters get-credentials iac-cluster \
  --region=europe-west1 \
  --project=<project-id>
```

### Runners ne démarrent pas
```bash
# Vérifier les secrets
gcloud secrets versions access latest --secret=github-app-id-dev

# Vérifier les pods
kubectl get pods -n github-runners
kubectl describe pod <pod-name> -n github-runners
kubectl logs <pod-name> -n github-runners
```

### IP mismatch
```bash
# Vérifier l'IP du LoadBalancer
kubectl get svc iac-service -n iac

# Mettre à jour les outputs
cd terraform
terraform refresh -var-file=environments/dev/terraform.tfvars
terraform output app_url
```

---

## 📚 Documentation supplémentaire

- [Architecture](docs/architecture.md)
- [Deployment Guide](docs/runbooks/deployment.md)
- [Troubleshooting](docs/runbooks/troubleshooting.md)
- [Terraform Modules](terraform/README.md)

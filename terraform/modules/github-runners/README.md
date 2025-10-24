# GitHub Runners Module

Ce module Terraform crée un node pool dédié pour les GitHub self-hosted runners dans GKE avec authentification via GitHub App.

## 🏗️ Architecture

Les runners s'exécutent dans un node pool séparé avec :
- **Node pool dédié** avec taints `workload-type=github-runners:NoSchedule` pour isolation
- **Autoscaling** du nombre de nœuds (1-5 par défaut)
- **Namespace Kubernetes** dédié (`github-runners`)
- **RBAC** configuré pour les runners
- **GitHub App authentication** (recommandé) - secrets dans Secret Manager
- **Workload Identity** pour accès sécurisé aux secrets

## 🔐 Authentification

### GitHub App (recommandé) ✅

Les secrets sont stockés dans **Google Secret Manager** :
- `github-app-id-{env}` : App ID de la GitHub App
- `github-installation-id-{env}` : Installation ID
- `github-private-key-{env}` : Private key (.pem)

**Avantages** :
- ✅ Identité indépendante (comme un Service Account)
- ✅ Permissions granulaires
- ✅ Tokens auto-renouvelés (1h)
- ✅ Survit aux changements d'équipe

Voir le guide complet : [`/SETUP-GITHUB-RUNNERS.md`](/SETUP-GITHUB-RUNNERS.md)

## 📦 Variables

### Requises

| Nom | Description |
|-----|-------------|
| `cluster_name` | Nom du cluster GKE |
| `region` | Région GCP |
| `service_account` | Service account email pour les nœuds |
| `project_id` | ID du projet GCP |

### GitHub App (recommandé)

| Nom | Description | Exemple |
|-----|-------------|---------|
| `github_app_id_secret` | Nom du secret Secret Manager (App ID) | `github-app-id-dev` |
| `github_installation_id_secret` | Nom du secret Secret Manager (Installation ID) | `github-installation-id-dev` |
| `github_private_key_secret` | Nom du secret Secret Manager (Private Key) | `github-private-key-dev` |

### Configuration du node pool

| Nom | Description | Défaut |
|-----|-------------|--------|
| `runner_machine_type` | Type de machine | `e2-standard-2` |
| `runner_disk_size` | Taille du disque (GB) | `50` |
| `min_runner_nodes` | Minimum de nœuds | `1` |
| `max_runner_nodes` | Maximum de nœuds | `5` |

## 📤 Outputs

- `node_pool_name` : Nom du node pool créé
- `namespace` : Namespace Kubernetes (`github-runners`)
- `service_account_name` : Service account Kubernetes pour les runners

## 🚀 Usage

```hcl
module "github_runners" {
  source = "./modules/github-runners"

  cluster_name    = module.gke.cluster_name
  region          = var.region
  service_account = module.iam.gke_sa_email
  project_id      = var.project_id

  # GitHub App Authentication
  github_app_id_secret         = "github-app-id-dev"
  github_installation_id_secret = "github-installation-id-dev"
  github_private_key_secret    = "github-private-key-dev"

  min_runner_nodes = 1
  max_runner_nodes = 5
}
```

## 📋 Setup

1. **Créer la GitHub App** (voir `/SETUP-GITHUB-RUNNERS.md`)
2. **Stocker les secrets** dans Secret Manager
3. **Déployer avec Terraform**

```bash
terraform apply -var-file=environments/dev/terraform.tfvars
```

## 🔍 Vérification

```bash
# Vérifier les runners sur GitHub
# Organisation → Settings → Actions → Runners

# Vérifier les pods
kubectl get pods -n github-runners
kubectl logs -n github-runners -l app=github-runner
```

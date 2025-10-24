# Module Secrets

Ce module gère les secrets sensibles via Google Secret Manager.

## Description

Ce module Terraform crée et configure les secrets dans Google Secret Manager pour l'infrastructure. Il ne stocke **jamais** les valeurs des secrets dans le code Terraform - seule la structure des secrets est gérée.

## Secrets gérés

- **`cloudsql-{env}-password`** : Mot de passe pour la base de données Cloud SQL PostgreSQL

## Utilisation

```hcl
module "secrets" {
  source      = "./modules/secrets"
  project_id  = var.project_id
  environment = var.environment
  
  gke_service_account       = module.iam.gke_sa_email
  terraform_service_account = ""  # Optionnel
  cloudsql_service_account  = ""  # Cloud SQL utilise un SA géré
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | GCP Project ID | string | - | yes |
| environment | Environment name (dev, prd) | string | - | yes |
| gke_service_account | Service account email for GKE nodes | string | "" | no |
| terraform_service_account | Service account email for Terraform | string | "" | no |
| cloudsql_service_account | Service account email for Cloud SQL | string | "" | no |

## Outputs

| Name | Description |
|------|-------------|
| db_password_secret_id | Secret ID for database password |
| db_password_secret_name | Full secret name |
| db_password_secret_version | Path to the latest version of the secret |

## Gestion des valeurs de secrets

⚠️ **Important** : Ce module crée uniquement le **conteneur** du secret, pas sa valeur.

### Ajouter une valeur au secret

Utilisez le script helper fourni :

```bash
cd terraform/
./manage-secrets.sh add dev
```

Ou manuellement avec gcloud :

```bash
gcloud secrets versions add cloudsql-dev-password --data-file=-
# Tapez le mot de passe puis Ctrl+D
```

### Voir la documentation complète

Consultez [docs/SECRET_MANAGER.md](../../docs/SECRET_MANAGER.md) pour :
- Guide complet d'utilisation
- Rotation des secrets
- Dépannage
- Bonnes pratiques

## Permissions IAM

Le module configure automatiquement les permissions suivantes :

- **GKE Service Account** : `roles/secretmanager.secretAccessor` (lecture)
- **Terraform SA** (si fourni) : `roles/secretmanager.admin` (gestion)
- **Cloud SQL** : Utilise le service account géré par Google

## Sécurité

✅ Aucune valeur de secret stockée dans Terraform  
✅ Audit automatique via Cloud Audit Logs  
✅ Versioning des secrets  
✅ Contrôle d'accès IAM granulaire  
✅ Réplication automatique pour haute disponibilité  

## Notes

- Les secrets sont créés avec une réplication automatique
- Les labels sont ajoutés pour faciliter la gestion
- Les anciennes versions peuvent être désactivées (pas supprimées)

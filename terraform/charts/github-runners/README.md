# GitHub Runners Helm Chart

Chart Helm pour déployer des GitHub self-hosted runners sur Kubernetes avec support Docker-in-Docker.

## Description

Ce chart déploie des GitHub self-hosted runners dans Kubernetes avec :
- **Autoscaling** via HPA (CPU et mémoire)
- **Docker-in-Docker** pour builds Docker dans les runners
- **Persistent volumes** pour workspaces et cache Docker
- **Isolation** via node selector et tolerations
- **Sécurité** avec service accounts et RBAC

## Installation

### Prérequis

1. Cluster Kubernetes fonctionnel
2. Helm 3.x installé
3. GitHub Personal Access Token avec les scopes nécessaires
4. Node pool avec label `workload-type=github-runners` (optionnel mais recommandé)

### Créer le secret GitHub

```bash
kubectl create namespace github-runners

kubectl create secret generic github-token \
  --from-literal=github_token=ghp_votre_token \
  -n github-runners
```

### Installation basique

```bash
helm install github-runners ./github-runners \
  --namespace github-runners \
  --set github.url=https://github.com/owner/repo \
  --set github.tokenSecret=github-token
```

### Installation avec values.yaml personnalisé

```bash
# Créer un fichier my-values.yaml
cat > my-values.yaml <<EOF
```yaml
github:
  url: "https://github.com/your-org/your-repo"
  tokenSecret: "github-token"

replicaCount: 3

resources:
  requests:
    cpu: "1000m"
    memory: "1Gi"
  limits:
    cpu: "2000m"
    memory: "2Gi"

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10

runnerLabels:
  - "self-hosted"
  - "kubernetes"
  - "gke"
  - "custom-label"
EOF

# Installer
helm install github-runners ./github-runners \
  --namespace github-runners \
  --values my-values.yaml
```

## Configuration

### Paramètres principaux

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| `github.url` | URL du repo/org GitHub | `https://github.com/owner/repo` |
| `github.token` | Token GitHub (direct) | `""` |
| `github.tokenSecret` | Nom du secret contenant le token | `github-token` |
| `replicaCount` | Nombre de runners | `2` |
| `image.repository` | Image des runners | `ghcr.io/actions/actions-runner` |
| `image.tag` | Tag de l'image | `2.311.0` |

### Ressources

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| `resources.requests.cpu` | CPU demandé | `500m` |
| `resources.requests.memory` | Mémoire demandée | `512Mi` |
| `resources.limits.cpu` | CPU max | `2000m` |
| `resources.limits.memory` | Mémoire max | `2Gi` |

### Autoscaling

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| `autoscaling.enabled` | Activer l'HPA | `true` |
| `autoscaling.minReplicas` | Min runners | `1` |
| `autoscaling.maxReplicas` | Max runners | `10` |
| `autoscaling.targetCPUUtilizationPercentage` | Cible CPU | `70` |
| `autoscaling.targetMemoryUtilizationPercentage` | Cible mémoire | `80` |

### Docker-in-Docker

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| `docker.enabled` | Activer DinD | `true` |
| `docker.image.repository` | Image Docker | `docker` |
| `docker.image.tag` | Tag Docker | `24-dind` |
| `docker.persistence.size` | Taille PVC Docker | `20Gi` |

### Node Affinity

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| `nodeSelector` | Sélecteur de nœuds | `{workload-type: github-runners}` |
| `tolerations` | Tolerations pour taints | Voir values.yaml |

### Labels des runners

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| `runnerLabels` | Labels GitHub du runner | `["self-hosted", "kubernetes", ...]` |
| `runnerGroup` | Groupe du runner | `default` |

### Persistence

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| `persistence.enabled` | Activer PVC pour workspace | `true` |
| `persistence.size` | Taille du PVC | `10Gi` |
| `persistence.storageClassName` | Classe de stockage | `standard-rwo` |

## Exemples d'utilisation

### 1. Runner pour une organisation

```yaml
github:
  url: "https://github.com/my-organization"
  tokenSecret: "github-token"

runnerLabels:
  - "self-hosted"
  - "kubernetes"
  - "production"
  - "docker"
```

### 2. Runners avec ressources élevées

```yaml
resources:
  requests:
    cpu: "2000m"
    memory: "4Gi"
  limits:
    cpu: "4000m"
    memory: "8Gi"

docker:
  enabled: true
  resources:
    requests:
      cpu: "1000m"
      memory: "2Gi"
    limits:
      cpu: "2000m"
      memory: "4Gi"
```

### 3. Scaling agressif

```yaml
autoscaling:
  enabled: true
  minReplicas: 5
  maxReplicas: 50
  targetCPUUtilizationPercentage: 60
  targetMemoryUtilizationPercentage: 70
```

### 4. Sans node pool dédié

```yaml
nodeSelector: {}
tolerations: []
```

## Commandes utiles

### Vérifier le déploiement

```bash
# Status de la release
helm status github-runners -n github-runners

# Lister les runners
kubectl get pods -n github-runners -l app.kubernetes.io/name=github-runners

# Logs d'un runner
kubectl logs -n github-runners <pod-name> -f

# Status HPA
kubectl get hpa -n github-runners
```

### Mise à jour

```bash
# Mettre à jour avec de nouvelles valeurs
helm upgrade github-runners ./github-runners \
  --namespace github-runners \
  --values my-values.yaml

# Rollback si problème
helm rollback github-runners -n github-runners
```

### Désinstallation

```bash
# Supprimer la release
helm uninstall github-runners -n github-runners

# Supprimer le namespace
kubectl delete namespace github-runners
```

## Troubleshooting

### Runners ne s'enregistrent pas

```bash
# Vérifier les logs
kubectl logs -n github-runners <pod-name>

# Vérifier le secret
kubectl get secret github-token -n github-runners -o yaml

# Vérifier la connexion à GitHub
kubectl exec -it -n github-runners <pod-name> -- curl -I https://api.github.com
```

### Problèmes de scheduling

```bash
# Vérifier les events
kubectl describe pod -n github-runners <pod-name>

# Vérifier les nœuds disponibles
kubectl get nodes -l workload-type=github-runners

# Vérifier les taints
kubectl get nodes -o json | jq '.items[].spec.taints'
```

### Docker ne fonctionne pas

```bash
# Logs du conteneur DinD
kubectl logs -n github-runners <pod-name> -c dind

# Tester Docker dans le runner
kubectl exec -it -n github-runners <pod-name> -- docker ps
```

## Architecture

```
┌─────────────────────────────────────────────┐
│         Deployment (github-runners)         │
│                                             │
│  ┌────────────────────────────────────┐   │
│  │            Pod Template             │   │
│  │                                     │   │
│  │  ┌──────────────┐  ┌────────────┐ │   │
│  │  │    Runner    │  │    DinD    │ │   │
│  │  │  Container   │  │ Container  │ │   │
│  │  │              │  │            │ │   │
│  │  │ • Register   │  │ • Docker   │ │   │
│  │  │ • Execute    │  │ • Build    │ │   │
│  │  │ • Cleanup    │  │ • Cache    │ │   │
│  │  └──────────────┘  └────────────┘ │   │
│  │         │                  │       │   │
│  │         └──────┬───────────┘       │   │
│  │                │                   │   │
│  │         ┌──────▼──────┐           │   │
│  │         │  Volumes    │           │   │
│  │         │ • Work PVC  │           │   │
│  │         │ • Docker PVC│           │   │
│  │         └─────────────┘           │   │
│  └────────────────────────────────────┘   │
│                                             │
│  HPA ◄──────► Metrics                     │
└─────────────────────────────────────────────┘
         │
         └──► GitHub API (registration)
```

## Sécurité

### Service Account

Le chart crée/utilise un ServiceAccount avec les permissions minimales nécessaires.

### Secrets

Le token GitHub est stocké dans un Secret Kubernetes et injecté via une variable d'environnement.

### Network Policies

Pour restreindre le trafic réseau :

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: github-runners
  namespace: github-runners
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: github-runners
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
  - to:
    - podSelector: {}
  - ports:
    - port: 443
      protocol: TCP
  - ports:
    - port: 80
      protocol: TCP
```

## Contribuer

Pour contribuer à ce chart :

1. Fork le repository
2. Créer une branche feature
3. Tester les changements
4. Soumettre une Pull Request

## Licence

MIT

## Support

Pour obtenir de l'aide :
- Consulter la documentation : `/GITHUB_RUNNERS_DEPLOYMENT.md`
- Ouvrir une issue sur le repository
- Consulter les logs : `kubectl logs -n github-runners <pod-name>`

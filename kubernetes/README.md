# ☸️ Kubernetes Manifests

Kubernetes manifests organized with Kustomize.

## Structure

```
kubernetes/
├── base/                   # Base configuration
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   └── kustomization.yaml
├── overlays/              # Environment-specific overlays
│   ├── dev/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   └── prd/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── kustomization.yaml
└── monitoring/            # Monitoring tools
    └── prometheus.yaml
```

## Using Kustomize

### Development

```bash
# Preview rendered manifests
kubectl kustomize kubernetes/overlays/dev/

# Apply
kubectl apply -k kubernetes/overlays/dev/

# Verify
kubectl get all -n iac
```

### Production

```bash
# Preview rendered manifests
kubectl kustomize kubernetes/overlays/prd/

# Apply
kubectl apply -k kubernetes/overlays/prd/

# Verify
kubectl get all -n iac
```

## Why Kustomize

- **DRY**: Shared base configuration
- **Environments**: Overlays per environment
- **Built-in**: Integrated into kubectl
- **No templating**: Plain YAML, easy to understand

## Per-environment customization

| Resource | Dev | Production |
|----------|-----|------------|
| Replicas | 2   | 3          |
| Service Type | NodePort | LoadBalancer |
| Resources | Minimal | Optimized |
| Image Tag | dev | latest |

## Secrets

⚠️ **Important**: Secrets must NOT be committed to Git!

Use:
- Google Secret Manager
- Sealed Secrets
- External Secrets Operator
- CI/CD environment variables

## Useful commands

```bash
# Rollout
kubectl rollout restart deployment/iac -n iac
kubectl rollout status deployment/iac -n iac
kubectl rollout history deployment/iac -n iac

# Logs
kubectl logs -n iac -l app=iac --tail=100 -f

# Debug
kubectl describe pod -n iac POD_NAME
kubectl exec -it -n iac POD_NAME -- /bin/sh
```

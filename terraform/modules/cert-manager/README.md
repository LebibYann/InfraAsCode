# Cert-Manager Module

Ce module installe cert-manager dans le cluster GKE via Helm.

## Description

Cert-manager est un gestionnaire de certificats TLS pour Kubernetes. Il est **requis** pour Actions Runner Controller (ARC) car ARC utilise des webhooks qui nécessitent des certificats TLS.

## Ce qui est installé

- Namespace `cert-manager`
- Helm chart `cert-manager` (version 1.13.2)
- CRDs (Custom Resource Definitions) pour cert-manager
- Pods cert-manager (webhook, cainjector, controller)

## Utilisation

```hcl
module "cert_manager" {
  source = "./modules/cert-manager"

  depends_on = [module.gke]
}
```

## Outputs

- `namespace` : Nom du namespace cert-manager
- `release_name` : Nom du Helm release
- `release_status` : Statut du déploiement

## Dépendances

Ce module doit être déployé **après** :
- Le cluster GKE doit être créé et accessible

## Vérifie l'installation

```bash
kubectl get pods -n cert-manager
kubectl get crd | grep cert-manager
```

## Version

- Chart version: v1.13.2
- Compatible avec Kubernetes 1.22+

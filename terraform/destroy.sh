#!/bin/bash

# Script de destruction complète de l'infrastructure
# Gère automatiquement l'ordre de destruction pour éviter les erreurs

set -e

ENV=${1:-dev}
TFVARS_FILE="environments/$ENV/terraform.tfvars"

if [ ! -f "$TFVARS_FILE" ]; then
    echo "❌ Fichier $TFVARS_FILE introuvable"
    exit 1
fi

echo "🔥 Destruction de l'infrastructure ($ENV)"
echo "=========================================="

# Étape 1 : Détruire CloudSQL en premier (utilise le VPC peering)
echo ""
echo "📦 Étape 1/5 : Destruction de CloudSQL..."
terraform destroy -target=module.cloudsql -var-file="$TFVARS_FILE" -auto-approve

# Étape 2 : Détruire GKE (utilise le réseau)
echo ""
echo "📦 Étape 2/5 : Destruction de GKE..."
terraform destroy -target=module.gke -var-file="$TFVARS_FILE" -auto-approve

# Étape 3 : Détruire NAT Gateway
echo ""
echo "📦 Étape 3/5 : Destruction du NAT Gateway..."
terraform destroy -target=module.nat -var-file="$TFVARS_FILE" -auto-approve

# Étape 4 : Détruire la connexion VPC peering (avec contournement si nécessaire)
echo ""
echo "📦 Étape 4/5 : Destruction du VPC peering..."
if ! terraform destroy \
    -target=google_service_networking_connection.private_vpc_connection \
    -target=google_compute_global_address.private_services_ip \
    -var-file="$TFVARS_FILE" \
    -auto-approve; then
    
    echo "⚠️  Erreur lors de la destruction du VPC peering (attendu)"
    echo "🔧 Application du contournement : suppression manuelle du peering..."
    
    # Supprimer le peering manuellement
    gcloud compute networks peerings delete servicenetworking-googleapis-com \
        --network=vpc-network \
        --project=infra-as-code-tek \
        --quiet 2>/dev/null || true
    
    # Retirer la ressource de l'état Terraform
    terraform state rm google_service_networking_connection.private_vpc_connection 2>/dev/null || true
    
    echo "✅ Contournement appliqué"
fi

# Étape 5 : Détruire le reste (Network, Storage, IAM, Services)
echo ""
echo "📦 Étape 5/5 : Destruction du reste de l'infrastructure..."
terraform destroy -var-file="$TFVARS_FILE" -auto-approve

echo ""
echo "✅ Destruction complète terminée !"
echo ""
echo "Vérification des ressources restantes..."
echo "=========================================="

# Vérifier qu'il ne reste rien
PROJECT_ID=$(terraform output -raw project_id 2>/dev/null || echo "")

if [ -n "$PROJECT_ID" ]; then
    echo "Vérification du projet: $PROJECT_ID"
    
    # Vérifier CloudSQL
    SQL_COUNT=$(gcloud sql instances list --project="$PROJECT_ID" --format="value(name)" 2>/dev/null | wc -l)
    echo "  - Instances CloudSQL: $SQL_COUNT"
    
    # Vérifier GKE
    GKE_COUNT=$(gcloud container clusters list --project="$PROJECT_ID" --format="value(name)" 2>/dev/null | wc -l)
    echo "  - Clusters GKE: $GKE_COUNT"
    
    # Vérifier VPC
    VPC_COUNT=$(gcloud compute networks list --project="$PROJECT_ID" --format="value(name)" --filter="name!=default" 2>/dev/null | wc -l)
    echo "  - Réseaux VPC: $VPC_COUNT"
fi

echo ""
echo "✨ Terminé !"

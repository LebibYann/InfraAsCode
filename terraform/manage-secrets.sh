#!/bin/bash

# Script helper pour gérer les secrets avec Google Secret Manager
# Usage: ./manage-secrets.sh [command] [environment] [secret-name]

set -e

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'aide
function show_help() {
    cat << EOF
${BLUE}╔════════════════════════════════════════════════════════════╗
║          Secret Manager Helper Script                     ║
╚════════════════════════════════════════════════════════════╝${NC}

${GREEN}Usage:${NC}
  ./manage-secrets.sh [command] [environment]

${GREEN}Commands:${NC}
  list                  - Liste tous les secrets
  create [env]          - Crée le secret de DB pour l'environnement
  add [env]             - Ajoute une nouvelle version du mot de passe DB
  show [env]            - Affiche le mot de passe actuel (si autorisé)
  rotate [env]          - Rotation du mot de passe (génère un nouveau)
  versions [env]        - Liste les versions d'un secret
  disable [env] [ver]   - Désactive une version spécifique
  
${GREEN}Environments:${NC}
  dev                   - Environnement de développement
  prd                   - Environnement de production

${GREEN}Examples:${NC}
  ./manage-secrets.sh list
  ./manage-secrets.sh create dev
  ./manage-secrets.sh add dev
  ./manage-secrets.sh show dev
  ./manage-secrets.sh rotate prd
  ./manage-secrets.sh versions dev
  ./manage-secrets.sh disable dev 1

${YELLOW}Note:${NC} Assurez-vous d'avoir configuré gcloud et d'avoir les permissions nécessaires.

EOF
}

# Vérifier que gcloud est installé
function check_gcloud() {
    if ! command -v gcloud &> /dev/null; then
        echo -e "${RED}❌ Erreur: gcloud CLI n'est pas installé${NC}"
        echo "Installation: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
}

# Récupérer le project ID
function get_project_id() {
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$PROJECT_ID" ]; then
        echo -e "${RED}❌ Erreur: Aucun projet GCP configuré${NC}"
        echo "Utilisez: gcloud config set project YOUR_PROJECT_ID"
        exit 1
    fi
    echo -e "${BLUE}📁 Projet actuel: ${GREEN}$PROJECT_ID${NC}"
}

# Lister tous les secrets
function list_secrets() {
    echo -e "${BLUE}🔍 Liste des secrets dans le projet...${NC}\n"
    gcloud secrets list --format="table(name,createTime,replication.automatic)" || {
        echo -e "${YELLOW}⚠️  Aucun secret trouvé ou permission refusée${NC}"
    }
}

# Créer un secret (sans valeur)
function create_secret() {
    local ENV=$1
    local SECRET_NAME="cloudsql-${ENV}-password"
    
    echo -e "${BLUE}🔐 Création du secret: ${GREEN}${SECRET_NAME}${NC}"
    
    if gcloud secrets describe "$SECRET_NAME" &>/dev/null; then
        echo -e "${YELLOW}⚠️  Le secret ${SECRET_NAME} existe déjà${NC}"
        return 0
    fi
    
    gcloud secrets create "$SECRET_NAME" \
        --replication-policy="automatic" \
        --labels="environment=${ENV},managed-by=terraform,purpose=cloudsql"
    
    echo -e "${GREEN}✅ Secret créé avec succès${NC}"
    echo -e "${YELLOW}⚠️  N'oubliez pas d'ajouter une version avec une valeur !${NC}"
}

# Ajouter une version au secret
function add_version() {
    local ENV=$1
    local SECRET_NAME="cloudsql-${ENV}-password"
    
    echo -e "${BLUE}🔐 Ajout d'une nouvelle version pour: ${GREEN}${SECRET_NAME}${NC}"
    echo -e "${YELLOW}⚠️  Le mot de passe sera lu depuis stdin${NC}"
    echo -e "Tapez votre mot de passe et appuyez sur Ctrl+D :\n"
    
    gcloud secrets versions add "$SECRET_NAME" --data-file=- && {
        echo -e "\n${GREEN}✅ Nouvelle version du secret ajoutée${NC}"
        echo -e "${BLUE}ℹ️  N'oubliez pas de lancer terraform apply pour mettre à jour Cloud SQL${NC}"
    } || {
        echo -e "\n${RED}❌ Erreur lors de l'ajout de la version${NC}"
        exit 1
    }
}

# Générer et ajouter un mot de passe aléatoire
function rotate_password() {
    local ENV=$1
    local SECRET_NAME="cloudsql-${ENV}-password"
    
    echo -e "${BLUE}🔄 Rotation du mot de passe pour: ${GREEN}${SECRET_NAME}${NC}"
    
    # Générer un mot de passe fort (32 caractères)
    NEW_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    
    echo -e "${YELLOW}⚠️  Nouveau mot de passe généré (32 caractères aléatoires)${NC}"
    echo -e "${BLUE}Ajout de la nouvelle version...${NC}"
    
    echo "$NEW_PASSWORD" | gcloud secrets versions add "$SECRET_NAME" --data-file=- && {
        echo -e "${GREEN}✅ Mot de passe roté avec succès${NC}"
        echo -e "${BLUE}ℹ️  Nouveau mot de passe:${NC} ${GREEN}${NEW_PASSWORD}${NC}"
        echo -e "${YELLOW}⚠️  Notez ce mot de passe dans un endroit sûr si nécessaire${NC}"
        echo -e "${BLUE}ℹ️  Lancez terraform apply pour mettre à jour Cloud SQL${NC}"
    } || {
        echo -e "${RED}❌ Erreur lors de la rotation${NC}"
        exit 1
    }
}

# Afficher la valeur actuelle
function show_secret() {
    local ENV=$1
    local SECRET_NAME="cloudsql-${ENV}-password"
    
    echo -e "${BLUE}👀 Récupération du secret: ${GREEN}${SECRET_NAME}${NC}\n"
    
    gcloud secrets versions access latest --secret="$SECRET_NAME" 2>/dev/null && {
        echo -e "\n${GREEN}✅ Secret récupéré${NC}"
    } || {
        echo -e "${RED}❌ Impossible de lire le secret (permission refusée ou secret inexistant)${NC}"
        exit 1
    }
}

# Lister les versions
function list_versions() {
    local ENV=$1
    local SECRET_NAME="cloudsql-${ENV}-password"
    
    echo -e "${BLUE}📋 Versions du secret: ${GREEN}${SECRET_NAME}${NC}\n"
    
    gcloud secrets versions list "$SECRET_NAME" --format="table(name,state,createTime)" || {
        echo -e "${RED}❌ Erreur lors de la récupération des versions${NC}"
        exit 1
    }
}

# Désactiver une version
function disable_version() {
    local ENV=$1
    local VERSION=$2
    local SECRET_NAME="cloudsql-${ENV}-password"
    
    if [ -z "$VERSION" ]; then
        echo -e "${RED}❌ Erreur: Vous devez spécifier un numéro de version${NC}"
        echo "Usage: ./manage-secrets.sh disable $ENV <version_number>"
        exit 1
    fi
    
    echo -e "${BLUE}🔒 Désactivation de la version ${VERSION} pour: ${GREEN}${SECRET_NAME}${NC}"
    
    gcloud secrets versions disable "$VERSION" --secret="$SECRET_NAME" && {
        echo -e "${GREEN}✅ Version ${VERSION} désactivée${NC}"
    } || {
        echo -e "${RED}❌ Erreur lors de la désactivation${NC}"
        exit 1
    }
}

# Validation de l'environnement
function validate_env() {
    local ENV=$1
    if [[ ! "$ENV" =~ ^(dev|prd)$ ]]; then
        echo -e "${RED}❌ Erreur: Environnement invalide '${ENV}'${NC}"
        echo "Environnements valides: dev, prd"
        exit 1
    fi
}

# Main
COMMAND=${1:-}
ENV=${2:-}

check_gcloud
get_project_id

case "$COMMAND" in
    list)
        list_secrets
        ;;
    create)
        validate_env "$ENV"
        create_secret "$ENV"
        ;;
    add)
        validate_env "$ENV"
        add_version "$ENV"
        ;;
    show)
        validate_env "$ENV"
        show_secret "$ENV"
        ;;
    rotate)
        validate_env "$ENV"
        rotate_password "$ENV"
        ;;
    versions)
        validate_env "$ENV"
        list_versions "$ENV"
        ;;
    disable)
        validate_env "$ENV"
        disable_version "$ENV" "$3"
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Commande inconnue: ${COMMAND}${NC}\n"
        show_help
        exit 1
        ;;
esac

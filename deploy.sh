#!/bin/bash

################################################################################
# IAC Infrastructure Deployment Script
# Usage: ./deploy.sh [dev|prd] [--auto-approve]
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse arguments
ENV=${1:-dev}
AUTO_APPROVE=""

if [[ "$2" == "--auto-approve" ]]; then
    AUTO_APPROVE="-auto-approve"
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       IAC Infrastructure Deployment Script                 ║${NC}"
echo -e "${BLUE}║       Environment: ${ENV^^}                                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Validate environment
if [[ "$ENV" != "dev" && "$ENV" != "prd" ]]; then
    echo -e "${RED}❌ Error: Invalid environment. Use 'dev' or 'prd'${NC}"
    exit 1
fi

# Warning for production
if [[ "$ENV" == "prd" && -z "$AUTO_APPROVE" ]]; then
    echo -e "${YELLOW}⚠️  WARNING: You are deploying to PRODUCTION!${NC}"
    echo -e "${YELLOW}This will create/modify resources that may incur costs.${NC}"
    echo ""
    echo -e "${CYAN}Press Enter to continue, or Ctrl+C to cancel...${NC}"
    read -r
fi

# Change to terraform directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/terraform"

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📋 Step 1/4: Validating Terraform configuration${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
terraform validate
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Configuration is valid${NC}"
else
    echo -e "${RED}❌ Configuration validation failed${NC}"
    exit 1
fi
echo ""

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔧 Step 2/4: Initializing Terraform with ${ENV} backend${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
terraform init \
    -backend-config="environments/${ENV}/backend.tfvars" \
    -reconfigure
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Terraform initialized${NC}"
else
    echo -e "${RED}❌ Terraform initialization failed${NC}"
    exit 1
fi
echo ""

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📊 Step 3/4: Planning infrastructure changes${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
terraform plan \
    -var-file="environments/${ENV}/terraform.tfvars" \
    -out="environments/${ENV}/output.tfplan"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Plan created successfully${NC}"
else
    echo -e "${RED}❌ Planning failed${NC}"
    exit 1
fi
echo ""

if [[ -z "$AUTO_APPROVE" ]]; then
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}⏸️  Review the plan above carefully${NC}"
    echo -e "${CYAN}Press Enter to apply changes, or Ctrl+C to cancel...${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    read -r
fi

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🚀 Step 4/4: Applying infrastructure changes${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
terraform apply "environments/${ENV}/output.tfplan"
APPLY_STATUS=$?

echo ""
if [ $APPLY_STATUS -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              ✅ Deployment Complete!                        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Display important outputs
    echo -e "${BLUE}📊 Infrastructure Details:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e "${CYAN}🌐 Application:${NC}"
    APP_URL=$(terraform output -raw app_url 2>/dev/null || echo "N/A")
    echo -e "   URL: ${GREEN}${APP_URL}${NC}"
    
    echo ""
    echo -e "${CYAN}🔧 GKE Cluster:${NC}"
    CLUSTER_NAME=$(terraform output -raw gke_cluster_name 2>/dev/null || echo "N/A")
    echo -e "   Name: ${GREEN}${CLUSTER_NAME}${NC}"
    
    echo ""
    echo -e "${CYAN}🏃 GitHub Runners:${NC}"
    echo -e "   Status: ${GREEN}Deployed${NC}"
    echo -e "   Namespace: github-runners"
    echo -e "   Node Pool: github-runners-pool"
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📝 Next steps:${NC}"
    echo -e "   1. Configure kubectl:"
    echo -e "      ${CYAN}gcloud container clusters get-credentials ${CLUSTER_NAME} --region=europe-west1${NC}"
    echo ""
    echo -e "   2. Check application health:"
    echo -e "      ${CYAN}curl ${APP_URL}/api/v1/health${NC}"
    echo ""
    echo -e "   3. Monitor runners:"
    echo -e "      ${CYAN}kubectl get pods -n github-runners${NC}"
    echo ""
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║              ❌ Deployment Failed!                          ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Please check the error messages above and try again.${NC}"
    exit 1
fi

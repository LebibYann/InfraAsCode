#!/bin/bash

################################################################################
# IAC Infrastructure Destroy Script
# Usage: ./destroy.sh [dev|prd] [--auto-approve]
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

echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║       ⚠️  IAC Infrastructure Destroy Script  ⚠️            ║${NC}"
echo -e "${RED}║       Environment: ${ENV^^}                                      ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Validate environment
if [[ "$ENV" != "dev" && "$ENV" != "prd" ]]; then
    echo -e "${RED}❌ Error: Invalid environment. Use 'dev' or 'prd'${NC}"
    exit 1
fi

# Strong warning for production
if [[ "$ENV" == "prd" ]]; then
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                    ⚠️  DANGER ZONE ⚠️                      ║${NC}"
    echo -e "${RED}║                                                            ║${NC}"
    echo -e "${RED}║  You are about to destroy PRODUCTION infrastructure!      ║${NC}"
    echo -e "${RED}║  This action is IRREVERSIBLE and will delete:             ║${NC}"
    echo -e "${RED}║    • GKE Cluster and all workloads                        ║${NC}"
    echo -e "${RED}║    • Cloud SQL database and ALL DATA                      ║${NC}"
    echo -e "${RED}║    • Storage buckets and their contents                   ║${NC}"
    echo -e "${RED}║    • All networking resources                             ║${NC}"
    echo -e "${RED}║    • All IAM bindings                                     ║${NC}"
    echo -e "${RED}║                                                            ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ -z "$AUTO_APPROVE" ]]; then
        echo -e "${YELLOW}Type '${RED}destroy-production${YELLOW}' to confirm destruction:${NC} "
        read -r confirmation
        if [[ "$confirmation" != "destroy-production" ]]; then
            echo -e "${GREEN}✅ Destruction cancelled. Infrastructure preserved.${NC}"
            exit 0
        fi
    fi
fi

# Warning for dev
if [[ "$ENV" == "dev" && -z "$AUTO_APPROVE" ]]; then
    echo -e "${YELLOW}⚠️  WARNING: You are about to destroy ${ENV^^} infrastructure!${NC}"
    echo -e "${YELLOW}This will delete:${NC}"
    echo -e "${YELLOW}  • GKE Cluster${NC}"
    echo -e "${YELLOW}  • Cloud SQL database and data${NC}"
    echo -e "${YELLOW}  • Storage bucket${NC}"
    echo -e "${YELLOW}  • All networking resources${NC}"
    echo ""
    echo -e "${CYAN}Press Enter to continue, or Ctrl+C to cancel...${NC}"
    read -r
fi

# Change to terraform directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/terraform"

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🔧 Step 1/4: Initializing Terraform with ${ENV} backend${NC}"
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
echo -e "${CYAN}🔄 Step 2/4: Refreshing state${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
terraform refresh \
    -var-file="environments/${ENV}/terraform.tfvars"
echo ""

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📊 Step 3/4: Planning destruction${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
terraform plan \
    -destroy \
    -var-file="environments/${ENV}/terraform.tfvars" \
    -out="environments/${ENV}/destroy.tfplan"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Destroy plan created${NC}"
else
    echo -e "${RED}❌ Planning failed${NC}"
    exit 1
fi
echo ""

if [[ -z "$AUTO_APPROVE" ]]; then
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}⚠️  LAST CHANCE: Review the destruction plan above${NC}"
    echo -e "${CYAN}Press Enter to DESTROY, or Ctrl+C to cancel...${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    read -r
fi

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${RED}💥 Step 4/4: Destroying infrastructure${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
terraform apply "environments/${ENV}/destroy.tfplan"
DESTROY_STATUS=$?

echo ""
if [ $DESTROY_STATUS -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          ✅ Infrastructure Destroyed Successfully!          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Clean up plan files
    echo -e "${CYAN}🧹 Cleaning up plan files...${NC}"
    rm -f "environments/${ENV}/output.tfplan"
    rm -f "environments/${ENV}/destroy.tfplan"
    echo -e "${GREEN}✅ Cleanup complete${NC}"
    echo ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📝 Post-destruction checklist:${NC}"
    echo ""
    echo -e "${CYAN}1. Verify no orphaned resources:${NC}"
    echo -e "   ${CYAN}gcloud compute instances list --project=\$(terraform output -raw project_id 2>/dev/null || echo 'your-project')${NC}"
    echo ""
    echo -e "${CYAN}2. Check for lingering disks:${NC}"
    echo -e "   ${CYAN}gcloud compute disks list --project=\$(terraform output -raw project_id 2>/dev/null || echo 'your-project')${NC}"
    echo ""
    echo -e "${CYAN}3. Review storage buckets:${NC}"
    echo -e "   ${CYAN}gcloud storage buckets list --project=\$(terraform output -raw project_id 2>/dev/null || echo 'your-project')${NC}"
    echo ""
    echo -e "${CYAN}4. Verify firewall rules:${NC}"
    echo -e "   ${CYAN}gcloud compute firewall-rules list --project=\$(terraform output -raw project_id 2>/dev/null || echo 'your-project')${NC}"
    echo ""
    echo -e "${GREEN}All infrastructure for ${ENV^^} has been removed.${NC}"
    echo ""
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║              ❌ Destruction Failed!                         ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Some resources may have dependencies or protection enabled.${NC}"
    echo -e "${YELLOW}Please check the error messages above.${NC}"
    echo ""
    echo -e "${YELLOW}You may need to:${NC}"
    echo -e "  1. Manually remove some resources via GCP Console"
    echo -e "  2. Run the destroy command again"
    echo -e "  3. Use: ${CYAN}./destroy.sh ${ENV} --auto-approve${NC}"
    echo ""
    exit 1
fi

#!/bin/bash

################################################################################
# Security Check Script - Verify no sensitive data before publishing
# Usage: ./check-sensitive-data.sh
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Security Check - Sensitive Data Scanner             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

ISSUES_FOUND=0

# Function to check for pattern
check_pattern() {
    local pattern=$1
    local description=$2
    
    echo -e "${YELLOW}Checking for: ${description}${NC}"
    
    # Exclude certain directories and file types
    results=$(grep -r "$pattern" . \
        --exclude-dir=.git \
        --exclude-dir=node_modules \
        --exclude-dir=.terraform \
        --exclude="*.example" \
        --exclude="CLEANUP_GUIDE.md" \
        --exclude="check-sensitive-data.sh" \
        --exclude="package-lock.json" \
        2>/dev/null || true)
    
    if [ -n "$results" ]; then
        echo -e "${RED}❌ FOUND in:${NC}"
        echo "$results"
        echo ""
        ((ISSUES_FOUND++))
    else
        echo -e "${GREEN}✅ Not found${NC}"
    fi
    echo ""
}

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📋 Checking for Project IDs${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"

check_pattern "infra-as-code-tek" "GCP Project: infra-as-code-tek"
check_pattern "lenny-iac-prd" "GCP Project: lenny-iac-prd"

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📋 Checking for Bucket Names${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"

check_pattern "lenny-iac-bucket" "Bucket: lenny-iac-bucket"
check_pattern "lenny-iac-tfstates-bucket" "TF State Bucket: lenny-iac-tfstates-bucket"

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📋 Checking for GitHub Usernames${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"

check_pattern "Linnchoeuh" "GitHub User: Linnchoeuh"
check_pattern "lenny-vigeon-dev" "GitHub Org: lenny-vigeon-dev"
check_pattern "lenny-vigeon" "GitHub User: lenny-vigeon"

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📋 Checking for Email Addresses${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"

check_pattern "lenny.vigeon" "Email: lenny.vigeon"
check_pattern "celian.friedrich" "Email: celian.friedrich"
check_pattern "florentmanidou" "Email: florentmanidou"
check_pattern "lebib.yann" "Email: lebib.yann"
check_pattern "jeremie@jjaouen" "Email: jeremie@jjaouen"

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📋 Checking for Service Accounts${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"

check_pattern "terraform-ci-dev@infra-as-code-tek" "Service Account: terraform-ci-dev@infra-as-code-tek"

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📋 Checking for Sensitive Files in Git${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"

SENSITIVE_FILES=(
    "terraform/environments/dev/terraform.tfvars"
    "terraform/environments/prd/terraform.tfvars"
    "terraform/environments/dev/backend.tfvars"
    "terraform/environments/prd/backend.tfvars"
    "terraform/stacks/iam-gcp/dev.tfvars"
    "terraform/stacks/iam-gcp/prd.tfvars"
    "terraform/stacks/iam-github/common.tfvars"
)

for file in "${SENSITIVE_FILES[@]}"; do
    if git ls-files --error-unmatch "$file" &>/dev/null; then
        echo -e "${RED}❌ FOUND in git: $file${NC}"
        ((ISSUES_FOUND++))
    else
        echo -e "${GREEN}✅ Not in git: $file${NC}"
    fi
done

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📋 Checking for Example Files${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"

EXAMPLE_FILES=(
    "terraform/environments/dev/terraform.tfvars.example"
    "terraform/environments/prd/terraform.tfvars.example"
    "terraform/environments/dev/backend.tfvars.example"
    "terraform/environments/prd/backend.tfvars.example"
    "terraform/stacks/iam-gcp/dev.tfvars.example"
    "terraform/stacks/iam-gcp/prd.tfvars.example"
    "terraform/stacks/iam-github/common.tfvars.example"
    "SECURITY.md"
    "CLEANUP_GUIDE.md"
)

for file in "${EXAMPLE_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ Exists: $file${NC}"
    else
        echo -e "${RED}❌ Missing: $file${NC}"
        ((ISSUES_FOUND++))
    fi
done

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📋 Final Result${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          ✅ No Sensitive Data Found!                        ║${NC}"
    echo -e "${GREEN}║          Repository is safe to publish                     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║          ❌ Found $ISSUES_FOUND Issue(s)!                          ║${NC}"
    echo -e "${RED}║          DO NOT publish until resolved                     ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Please review the issues above and:${NC}"
    echo -e "  1. Remove or replace sensitive data with placeholders"
    echo -e "  2. Ensure sensitive files are in .gitignore"
    echo -e "  3. Run this script again to verify"
    echo -e "  4. See CLEANUP_GUIDE.md for detailed instructions"
    exit 1
fi

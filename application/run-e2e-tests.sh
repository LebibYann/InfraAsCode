#!/bin/bash

################################################################################
# E2E Test Runner Script
#
# This script:
# 1. Starts Docker Compose services
# 2. Waits for the API to be healthy
# 3. Runs e2e tests
# 4. Cleans up Docker Compose services
#
# Usage:
#   ./run-e2e-tests.sh                                    # Use defaults
#   ./run-e2e-tests.sh --url http://localhost:5000/api/v1 # Custom URL
#   ./run-e2e-tests.sh --concurrency 1000                 # Custom concurrency
#   ./run-e2e-tests.sh --url <url> --concurrency 1000    # Both custom
################################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
API_URL="http://localhost:3000/api/v1"
CONCURRENCY=""
MAX_HEALTH_CHECKS=30
HEALTH_CHECK_INTERVAL=2

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --url)
      API_URL="$2"
      shift 2
      ;;
    --concurrency)
      CONCURRENCY="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: $0 [--url <api-url>] [--concurrency <number>]"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         E2E Test Runner for Task Manager API              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo -e "  API URL: ${GREEN}${API_URL}${NC}"
if [ -n "$CONCURRENCY" ]; then
  echo -e "  Concurrency: ${GREEN}${CONCURRENCY}${NC}"
else
  echo -e "  Concurrency: ${GREEN}500 (default)${NC}"
fi
echo ""

# Function to cleanup on exit
cleanup() {
  EXIT_CODE=$?
  echo ""
  echo -e "${YELLOW}Cleaning up...${NC}"

  echo -e "${BLUE}Stopping Docker Compose services...${NC}"
  docker-compose down -v 2>/dev/null || true

  if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ Tests completed successfully and cleanup done!${NC}"
  else
    echo -e "${RED}✗ Tests failed or were interrupted. Cleanup done.${NC}"
  fi

  exit $EXIT_CODE
}

# Set trap to cleanup on script exit
trap cleanup EXIT INT TERM

# Step 1: Start Docker Compose
echo -e "${BLUE}Step 1: Starting Docker Compose services...${NC}"
docker-compose up -d

if [ $? -ne 0 ]; then
  echo -e "${RED}✗ Failed to start Docker Compose services${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Docker Compose services started${NC}"
echo ""

# Step 2: Wait for API to be healthy
echo -e "${BLUE}Step 2: Waiting for API to be healthy...${NC}"
echo -e "  Health check URL: ${API_URL}/health"

HEALTH_CHECK_COUNT=0
API_HEALTHY=false

while [ $HEALTH_CHECK_COUNT -lt $MAX_HEALTH_CHECKS ]; do
  HEALTH_CHECK_COUNT=$((HEALTH_CHECK_COUNT + 1))

  echo -ne "  Attempt ${HEALTH_CHECK_COUNT}/${MAX_HEALTH_CHECKS}... "

  # Try to curl the health endpoint
  HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${API_URL}/health" 2>/dev/null || echo "000")

  if [ "$HEALTH_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ API is healthy!${NC}"
    API_HEALTHY=true
    break
  else
    echo -e "${YELLOW}waiting (HTTP ${HEALTH_RESPONSE})${NC}"
    sleep $HEALTH_CHECK_INTERVAL
  fi
done

if [ "$API_HEALTHY" = false ]; then
  echo -e "${RED}✗ API did not become healthy within the timeout period${NC}"
  echo -e "${RED}Please check Docker logs: docker-compose logs${NC}"
  exit 1
fi

echo ""

# Step 3: Run E2E Tests
echo -e "${BLUE}Step 3: Running E2E tests...${NC}"
echo ""

# Build test command with optional parameters
if [ -n "$CONCURRENCY" ]; then
  TEST_CONCURRENCY=$CONCURRENCY npm run test:e2e
else
  npm run test:e2e
fi

TEST_EXIT_CODE=$?

echo ""
if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║              ✓ ALL E2E TESTS PASSED!                      ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
else
  echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║              ✗ SOME E2E TESTS FAILED                      ║${NC}"
  echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
fi

exit $TEST_EXIT_CODE

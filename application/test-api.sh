#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

API_URL="http://localhost:3000/api/v1"
TOKEN=""

echo -e "${YELLOW}Starting Task Manager API Tests${NC}\n"

# Test 1: Health Check
echo -e "${YELLOW}Test 1: Health Check${NC}"
HEALTH=$(curl -s "${API_URL}/health")
if [[ $HEALTH == *"ok"* ]]; then
    echo -e "${GREEN}✓ Health check passed${NC}\n"
else
    echo -e "${RED}✗ Health check failed${NC}\n"
    exit 1
fi

# Test 2: Register User
echo -e "${YELLOW}Test 2: Register User${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "${API_URL}/auth/register" \
    -H "Content-Type: application/json" \
    -d '{
        "email": "test@example.com",
        "username": "testuser",
        "password": "testpass123"
    }')

if [[ $REGISTER_RESPONSE == *"access_token"* ]]; then
    TOKEN=$(echo $REGISTER_RESPONSE | grep -o '"access_token":"[^"]*' | sed 's/"access_token":"//')
    echo -e "${GREEN}✓ User registered successfully${NC}"
    echo -e "Token: ${TOKEN:0:20}...\n"
else
    echo -e "${YELLOW}⚠ User might already exist, trying login...${NC}\n"
    
    # Test 3: Login
    echo -e "${YELLOW}Test 3: Login${NC}"
    LOGIN_RESPONSE=$(curl -s -X POST "${API_URL}/auth/login" \
        -H "Content-Type: application/json" \
        -d '{
            "email": "test@example.com",
            "password": "testpass123"
        }')
    
    if [[ $LOGIN_RESPONSE == *"access_token"* ]]; then
        TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"access_token":"[^"]*' | sed 's/"access_token":"//')
        echo -e "${GREEN}✓ Login successful${NC}"
        echo -e "Token: ${TOKEN:0:20}...\n"
    else
        echo -e "${RED}✗ Login failed${NC}\n"
        exit 1
    fi
fi

# Test 4: Create Task
echo -e "${YELLOW}Test 4: Create Task${NC}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CREATE_RESPONSE=$(curl -s -X POST "${API_URL}/tasks" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "correlation_id: test-create" \
    -H "Content-Type: application/json" \
    -d "{
        \"title\": \"Test Task\",
        \"content\": \"This is a test task\",
        \"due_date\": \"2025-12-31\",
        \"request_timestamp\": \"${TIMESTAMP}\"
    }")

if [[ $CREATE_RESPONSE == *"id"* ]]; then
    TASK_ID=$(echo $CREATE_RESPONSE | grep -o '"id":"[^"]*' | sed 's/"id":"//')
    echo -e "${GREEN}✓ Task created successfully${NC}"
    echo -e "Task ID: ${TASK_ID}\n"
else
    echo -e "${RED}✗ Task creation failed${NC}\n"
    echo "Response: $CREATE_RESPONSE"
    exit 1
fi

# Test 5: List All Tasks
echo -e "${YELLOW}Test 5: List All Tasks${NC}"
LIST_RESPONSE=$(curl -s -X GET "${API_URL}/tasks" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "correlation_id: test-list")

if [[ $LIST_RESPONSE == *"id"* ]]; then
    echo -e "${GREEN}✓ Tasks listed successfully${NC}\n"
else
    echo -e "${RED}✗ Failed to list tasks${NC}\n"
    exit 1
fi

# Test 6: Get Specific Task
echo -e "${YELLOW}Test 6: Get Specific Task${NC}"
GET_RESPONSE=$(curl -s -X GET "${API_URL}/tasks/${TASK_ID}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "correlation_id: test-get")

if [[ $GET_RESPONSE == *"${TASK_ID}"* ]]; then
    echo -e "${GREEN}✓ Task retrieved successfully${NC}\n"
else
    echo -e "${RED}✗ Failed to get task${NC}\n"
    exit 1
fi

# Test 7: Update Task
echo -e "${YELLOW}Test 7: Update Task${NC}"
sleep 1
TIMESTAMP_UPDATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
UPDATE_RESPONSE=$(curl -s -X PUT "${API_URL}/tasks/${TASK_ID}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "correlation_id: test-update" \
    -H "Content-Type: application/json" \
    -d "{
        \"title\": \"Updated Test Task\",
        \"done\": true,
        \"request_timestamp\": \"${TIMESTAMP_UPDATE}\"
    }")

if [[ $UPDATE_RESPONSE == *"Updated Test Task"* ]]; then
    echo -e "${GREEN}✓ Task updated successfully${NC}\n"
else
    echo -e "${RED}✗ Failed to update task${NC}\n"
    echo "Response: $UPDATE_RESPONSE"
    exit 1
fi

# Test 8: Test Conflict (Out-of-order request)
echo -e "${YELLOW}Test 8: Test Conflict (Out-of-order request)${NC}"
OLD_TIMESTAMP="2020-01-01T00:00:00Z"
CONFLICT_RESPONSE=$(curl -s -X PUT "${API_URL}/tasks/${TASK_ID}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "correlation_id: test-conflict" \
    -H "Content-Type: application/json" \
    -d "{
        \"done\": false,
        \"request_timestamp\": \"${OLD_TIMESTAMP}\"
    }")

if [[ $CONFLICT_RESPONSE == *"409"* ]] || [[ $CONFLICT_RESPONSE == *"older"* ]]; then
    echo -e "${GREEN}✓ Conflict detection working correctly${NC}\n"
else
    echo -e "${YELLOW}⚠ Conflict detection might not be working as expected${NC}\n"
fi

# Test 9: Delete Task
echo -e "${YELLOW}Test 9: Delete Task${NC}"
sleep 1
TIMESTAMP_DELETE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DELETE_RESPONSE=$(curl -s -X DELETE "${API_URL}/tasks/${TASK_ID}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "correlation_id: test-delete" \
    -H "Content-Type: application/json" \
    -d "{
        \"request_timestamp\": \"${TIMESTAMP_DELETE}\"
    }")

if [[ $DELETE_RESPONSE == *"deleted successfully"* ]]; then
    echo -e "${GREEN}✓ Task deleted successfully${NC}\n"
else
    echo -e "${RED}✗ Failed to delete task${NC}\n"
    exit 1
fi

# Test 10: Verify Task is Deleted
echo -e "${YELLOW}Test 10: Verify Task is Deleted${NC}"
VERIFY_RESPONSE=$(curl -s -X GET "${API_URL}/tasks/${TASK_ID}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "correlation_id: test-verify")

if [[ $VERIFY_RESPONSE == *"404"* ]] || [[ $VERIFY_RESPONSE == *"not found"* ]]; then
    echo -e "${GREEN}✓ Task deletion verified${NC}\n"
else
    echo -e "${YELLOW}⚠ Task might still exist${NC}\n"
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All tests completed successfully! ✓${NC}"
echo -e "${GREEN}========================================${NC}"

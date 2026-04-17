#!/bin/bash
# =============================================================================
# AliyunProvider Integration Test (Bash Version)
# =============================================================================
#
# Tests AliyunProvider functionality against a real ECS instance.
# This script validates all operations that AliyunProvider performs.
#
# Usage: ./bootstrap/test-aliyun.sh
#
# =============================================================================

# Don't exit on error - we handle errors manually
set +e

ECS_HOST="aliyun-gz"
DOCKER_NETWORK="kai-net"
TEST_IMAGE="alpine:latest"

# Suppress locale warnings
export LC_ALL=C

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${CYAN}═══ $1 ═══${NC}"; }

# Remote execution with locale suppression
remote_exec() {
    ssh "${ECS_HOST}" "LC_ALL=C $1"
}

# Remote execution with output capture (suppress stderr)
remote_exec_capture() {
    ssh "${ECS_HOST}" "LC_ALL=C $1" 2>/dev/null
}

# Check result
check_result() {
    local exit_code=$1
    local test_name=$2

    if [ $exit_code -eq 0 ]; then
        log_success "$test_name"
        return 0
    else
        log_error "$test_name"
        return 1
    fi
}

# Main
log_section "AliyunProvider Integration Test"
log_info "Target: ${ECS_HOST}"
log_info "Network: ${DOCKER_NETWORK}"
echo ""

PASSED=0
FAILED=0
TIMESTAMP=$(date +%s)

# Test 1: SSH Connection
log_section "Test 1: SSH Connection"
log_info "Testing SSH connectivity..."

if ssh -o ConnectTimeout=5 "${ECS_HOST}" "LC_ALL=C echo 'Connected'" &>/dev/null; then
    log_success "SSH connection established"
    ((PASSED++))
else
    log_error "SSH connection failed"
    ((FAILED++))
    exit 1
fi

# Test 2: Docker Available
log_section "Test 2: Docker Available"
log_info "Checking Docker installation..."

DOCKER_VER=$(remote_exec "docker --version")
if check_result $? "Docker installed (${DOCKER_VER})"; then
    ((PASSED++))
else
    log_error "Docker not available"
    ((FAILED++))
    exit 1
fi

# Test 3: Docker Network Exists
log_section "Test 3: Docker Network"
log_info "Checking network '${DOCKER_NETWORK}'..."

NETWORK_EXISTS=$(remote_exec "docker network ls -q -f name=${DOCKER_NETWORK}")
if [ -n "$NETWORK_EXISTS" ]; then
    log_success "Network '${DOCKER_NETWORK}' exists"
    ((PASSED++))
else
    log_error "Network '${DOCKER_NETWORK}' not found"
    ((FAILED++))
fi

# Test 4: Create Container (AliyunProvider doesn't have this, but we test the operations it does)
log_section "Test 4: Create Test Container"
CONTAINER_NAME="test-sandbox-${TIMESTAMP}"

log_info "Creating container '${CONTAINER_NAME}'..."
CREATE_OUTPUT=$(remote_exec "docker run -d --name ${CONTAINER_NAME} --network ${DOCKER_NETWORK} ${TEST_IMAGE} sleep 3600")
CREATE_EXIT=$?

if [ $CREATE_EXIT -eq 0 ] && [ -n "$CREATE_OUTPUT" ]; then
    CONTAINER_ID=$(echo "$CREATE_OUTPUT" | tr -d '\n\r' | awk '{print $1}')
    log_success "Container created: ${CONTAINER_ID:0:12}"
    ((PASSED++))
else
    log_error "Failed to create container"
    log_error "Output: $CREATE_OUTPUT"
    ((FAILED++))
    exit 1
fi

# Test 5: List Sandboxes
log_section "Test 5: List Sandboxes"
log_info "Simulating listSandboxes()..."

LIST_OUTPUT=$(remote_exec "docker ps -a --format '{{json .}}' | grep ${CONTAINER_ID:0:12}")
if [ -n "$LIST_OUTPUT" ]; then
    log_success "Container found in list"
    ((PASSED++))
else
    log_error "Container not found in list"
    ((FAILED++))
fi

# Test 6: Get Sandbox Status
log_section "Test 6: Get Sandbox Status"
log_info "Simulating getSandboxStatus()..."

STATUS_OUTPUT=$(remote_exec "docker inspect ${CONTAINER_ID} --format '{{.State.Status}}'")
if check_result $? "Status retrieved: ${STATUS_OUTPUT}"; then
    ((PASSED++))
else
    ((FAILED++))
fi

# Test 7: Get Container IP
log_section "Test 7: Get Container IP"
log_info "Retrieving container IP address..."

IP_OUTPUT=$(remote_exec "docker inspect ${CONTAINER_ID} --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'")
if [ -n "$IP_OUTPUT" ]; then
    log_success "IP address: ${IP_OUTPUT}"
    ((PASSED++))
else
    log_error "No IP address found"
    ((FAILED++))
fi

# Test 8: Execute Command
log_section "Test 8: Execute Command"
log_info "Simulating execCommand()..."

EXEC_OUTPUT=$(remote_exec "docker exec ${CONTAINER_ID} echo 'Hello from ECS'")
if echo "$EXEC_OUTPUT" | grep -q "Hello from ECS"; then
    log_success "Command executed: ${EXEC_OUTPUT}"
    ((PASSED++))
else
    log_error "Command execution failed"
    ((FAILED++))
fi

# Test 9: Get Logs
log_section "Test 9: Get Logs"
log_info "Simulating getLogs()..."

LOGS_OUTPUT=$(remote_exec "docker logs --tail 10 ${CONTAINER_ID}")
if check_result $? "Logs retrieved"; then
    ((PASSED++))
else
    ((FAILED++))
fi

# Test 10: Stop Container
log_section "Test 10: Stop Container"
log_info "Simulating stopSandbox()..."

STOP_OUTPUT=$(remote_exec "docker stop ${CONTAINER_ID}")
if check_result $? "Container stopped"; then
    ((PASSED++))
else
    ((FAILED++))
fi

# Verify stopped status
sleep 1
STATUS_AFTER_STOP=$(remote_exec "docker inspect ${CONTAINER_ID} --format '{{.State.Status}}'")
if echo "$STATUS_AFTER_STOP" | grep -qi "exited"; then
    log_success "Status confirmed: ${STATUS_AFTER_STOP}"
    ((PASSED++))
else
    log_error "Status not updated: ${STATUS_AFTER_STOP}"
    ((FAILED++))
fi

# Test 11: Restart Container
log_section "Test 11: Restart Container"
log_info "Simulating restartSandbox()..."

RESTART_OUTPUT=$(remote_exec "docker start ${CONTAINER_ID}")
if check_result $? "Container restarted"; then
    ((PASSED++))
else
    ((FAILED++))
fi

# Verify running status
sleep 1
STATUS_AFTER_RESTART=$(remote_exec "docker inspect ${CONTAINER_ID} --format '{{.State.Status}}'")
if echo "$STATUS_AFTER_RESTART" | grep -qi "running"; then
    log_success "Status confirmed: ${STATUS_AFTER_RESTART}"
    ((PASSED++))
else
    log_error "Status not updated: ${STATUS_AFTER_RESTART}"
    ((FAILED++))
fi

# Test 12: Delete Container
log_section "Test 12: Delete Container"
log_info "Simulating deleteSandbox()..."

DELETE_OUTPUT=$(remote_exec "docker rm -f ${CONTAINER_ID}")
if check_result $? "Container deleted"; then
    ((PASSED++))
else
    ((FAILED++))
fi

# Verify deletion
EXISTS_AFTER_DELETE=$(remote_exec "docker ps -a -q -f id=${CONTAINER_ID}")
if [ -z "$EXISTS_AFTER_DELETE" ]; then
    log_success "Deletion verified: container no longer exists"
    ((PASSED++))
else
    log_error "Container still exists after deletion"
    ((FAILED++))
fi

# Summary
log_section "Test Summary"
TOTAL=$((PASSED + FAILED))
echo "Total tests: ${TOTAL}"
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n🎉 ${GREEN}All tests passed!${NC}"
    echo ""
    echo "Your Aliyun ECS is ready for use with CE Orchestrator!"
    echo ""
    echo "Next steps:"
    echo "  1. Configure providers.yaml with your ECS details"
    echo "  2. Test the AliyunProvider in your application"
    exit 0
else
    echo -e "\n⚠️ ${YELLOW}Some tests failed.${NC}"
    exit 1
fi

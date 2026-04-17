#!/bin/bash
# =============================================================================
# AliyunProvider - Container Creation Test
# =============================================================================
#
# Tests container creation functionality on remote ECS.
# This validates the createSandbox() operation.
#
# Usage: ./project/tests/e2e/aliyun-provider/bash/test-create-sandbox.sh
#
# =============================================================================

set +e

ECS_HOST="aliyun-gz"
DOCKER_NETWORK="kai-net"
# Use alpine for faster testing in CI/CD
# Change to flexy-sandbox image for production testing
TEST_IMAGE="${TEST_IMAGE:-alpine:latest}"
FLEXY_IMAGE="ghcr.io/misterlex223/flexy-sandbox:latest"

# Suppress locale warnings
export LC_ALL=C

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${CYAN}═══ $1 ═══${NC}"; }
log_file() { echo -e "${YELLOW}[FILE]${NC} $1"; }

# Remote execution
remote_exec() {
    ssh "${ECS_HOST}" "LC_ALL=C $1"
}

# Main
log_section "AliyunProvider Container Creation Test"
log_info "Target: ${ECS_HOST}"
log_info "Network: ${DOCKER_NETWORK}"
log_info "Image: ${TEST_IMAGE}"
echo ""

PASSED=0
FAILED=0
TIMESTAMP=$(date +%s)

# =============================================================================
# Test 1: Basic Container Creation
# =============================================================================

log_section "Test 1: Basic Container Creation"
CONTAINER_NAME="flexy-test-${TIMESTAMP}"

log_info "Creating container with default configuration..."
log_info "  Name: ${CONTAINER_NAME}"
log_info "  Image: ${TEST_IMAGE}"
log_info "  Network: ${DOCKER_NETWORK}"

# Basic docker run command (what createSandbox would do)
CREATE_OUTPUT=$(remote_exec "docker run -d \
  --name ${CONTAINER_NAME} \
  --network ${DOCKER_NETWORK} \
  --restart unless-stopped \
  -e ENABLE_WEBTTY=true \
  -e DOCKER_NETWORK=${DOCKER_NETWORK} \
  ${TEST_IMAGE}" 2>&1)

CREATE_EXIT=$?

if [ $CREATE_EXIT -eq 0 ] && [ -n "$CREATE_OUTPUT" ]; then
    CONTAINER_ID=$(echo "$CREATE_OUTPUT" | tr -d '\n\r')
    log_success "Container created: ${CONTAINER_ID:0:12}"
    ((PASSED++))
else
    log_error "Failed to create container"
    log_error "Output: $CREATE_OUTPUT"
    ((FAILED++))
    exit 1
fi

# Verify container is running
log_info "Verifying container status..."
STATUS_OUTPUT=$(remote_exec "docker inspect ${CONTAINER_ID} --format '{{.State.Status}}'")
if [ "$STATUS_OUTPUT" = "running" ]; then
    log_success "Container status: running"
    ((PASSED++))
else
    log_error "Container status: ${STATUS_OUTPUT}"
    ((FAILED++))
fi

# Verify network attachment
log_info "Verifying network attachment..."
NETWORK_CHECK=$(remote_exec "docker inspect ${CONTAINER_ID} --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'")
if [ -n "$NETWORK_CHECK" ]; then
    log_success "Network IP: ${NETWORK_CHECK}"
    ((PASSED++))
else
    log_error "Not attached to ${DOCKER_NETWORK} network"
    ((FAILED++))
fi

# =============================================================================
# Test 2: Container Creation with Custom Environment Variables
# =============================================================================

log_section "Test 2: Container Creation with Environment Variables"
CONTAINER_NAME_ENV="flexy-test-env-${TIMESTAMP}"

log_info "Creating container with custom environment variables..."

CREATE_OUTPUT=$(remote_exec "docker run -d \
  --name ${CONTAINER_NAME_ENV} \
  --network ${DOCKER_NETWORK} \
  -e TEST_VAR_1=test_value_1 \
  -e TEST_VAR_2=test_value_2 \
  -e CUSTOM_CONFIG=enabled \
  ${TEST_IMAGE} \
  sleep 3600" 2>&1)

if [ $? -eq 0 ]; then
    CONTAINER_ID_ENV=$(echo "$CREATE_OUTPUT" | tr -d '\n\r')
    log_success "Container created: ${CONTAINER_ID_ENV:0:12}"

    # Verify environment variables
    log_info "Verifying environment variables..."
    ENV_CHECK=$(remote_exec "docker exec ${CONTAINER_ID_ENV} printenv | grep TEST_VAR_1")
    if echo "$ENV_CHECK" | grep -q "test_value_1"; then
        log_success "Environment variables set correctly"
        ((PASSED++))
    else
        log_error "Environment variables not set"
        ((FAILED++))
    fi

    # Cleanup
    remote_exec "docker rm -f ${CONTAINER_ID_ENV}" &>/dev/null
else
    log_error "Failed to create container with env vars"
    ((FAILED++))
fi

# =============================================================================
# Test 3: Container Creation with Port Mappings
# =============================================================================

log_section "Test 3: Container Creation with Port Mappings"
CONTAINER_NAME_PORT="flexy-test-port-${TIMESTAMP}"

log_info "Creating container with port mappings..."
log_info "  Port 8080:8080"
log_info "  Port 9090:9090"

CREATE_OUTPUT=$(remote_exec "docker run -d \
  --name ${CONTAINER_NAME_PORT} \
  --network ${DOCKER_NETWORK} \
  -p 8080:8080 \
  -p 9090:9090 \
  ${TEST_IMAGE} \
  sleep 3600" 2>&1)

if [ $? -eq 0 ]; then
    CONTAINER_ID_PORT=$(echo "$CREATE_OUTPUT" | tr -d '\n\r')
    log_success "Container created: ${CONTAINER_ID_PORT:0:12}"

    # Verify port mappings (use inspect for unbound ports)
    log_info "Verifying port mappings in container config..."
    PORT_CONFIG=$(remote_exec "docker inspect ${CONTAINER_ID_PORT} --format '{{json .HostConfig.PortBindings}}'")
    if echo "$PORT_CONFIG" | grep -q "8080" && echo "$PORT_CONFIG" | grep -q "9090"; then
        log_success "Port mappings configured in HostConfig"
        ((PASSED++))
    else
        log_error "Port mappings not found in HostConfig"
        ((FAILED++))
    fi

    # Cleanup
    remote_exec "docker rm -f ${CONTAINER_ID_PORT}" &>/dev/null
else
    log_error "Failed to create container with port mappings"
    ((FAILED++))
fi

# =============================================================================
# Test 4: Container Creation with Volume Mounts
# =============================================================================

log_section "Test 4: Container Creation with Volume Mounts"
CONTAINER_NAME_VOL="flexy-test-vol-${TIMESTAMP}"

# Create a test directory on ECS
remote_exec "mkdir -p /tmp/test-mount-${TIMESTAMP}"
echo "Test data $(date)" | remote_exec "cat > /tmp/test-mount-${TIMESTAMP}/test.txt"

log_info "Creating container with volume mount..."
log_info "  Mount: /tmp/test-mount-${TIMESTAMP}:/data"

CREATE_OUTPUT=$(remote_exec "docker run -d \
  --name ${CONTAINER_NAME_VOL} \
  --network ${DOCKER_NETWORK} \
  -v /tmp/test-mount-${TIMESTAMP}:/data \
  ${TEST_IMAGE} \
  sleep 3600" 2>&1)

if [ $? -eq 0 ]; then
    CONTAINER_ID_VOL=$(echo "$CREATE_OUTPUT" | tr -d '\n\r')
    log_success "Container created: ${CONTAINER_ID_VOL:0:12}"

    # Verify volume mount
    log_info "Verifying volume mount..."
    VOL_CHECK=$(remote_exec "docker exec ${CONTAINER_ID_VOL} cat /data/test.txt")
    if echo "$VOL_CHECK" | grep -q "Test data"; then
        log_success "Volume mounted and accessible"
        ((PASSED++))
    else
        log_error "Volume not accessible"
        ((FAILED++))
    fi

    # Cleanup
    remote_exec "docker rm -f ${CONTAINER_ID_VOL}" &>/dev/null
    remote_exec "rm -rf /tmp/test-mount-${TIMESTAMP}" &>/dev/null
else
    log_error "Failed to create container with volume"
    ((FAILED++))
fi

# =============================================================================
# Test 5: Container Creation with Working Directory
# =============================================================================

log_section "Test 5: Container Creation with Working Directory"
CONTAINER_NAME_WORK="flexy-test-work-${TIMESTAMP}"

log_info "Creating container with working directory..."
log_info "  Working directory: /workspace"

CREATE_OUTPUT=$(remote_exec "docker run -d \
  --name ${CONTAINER_NAME_WORK} \
  --network ${DOCKER_NETWORK} \
  -w /workspace \
  ${TEST_IMAGE} \
  sleep 3600" 2>&1)

if [ $? -eq 0 ]; then
    CONTAINER_ID_WORK=$(echo "$CREATE_OUTPUT" | tr -d '\n\r')
    log_success "Container created: ${CONTAINER_ID_WORK:0:12}"

    # Verify working directory
    log_info "Verifying working directory..."
    WORK_DIR=$(remote_exec "docker exec ${CONTAINER_ID_WORK} pwd")
    if [ "$WORK_DIR" = "/workspace" ]; then
        log_success "Working directory set correctly"
        ((PASSED++))
    else
        log_error "Working directory: ${WORK_DIR} (expected /workspace)"
        ((FAILED++))
    fi

    # Cleanup
    remote_exec "docker rm -f ${CONTAINER_ID_WORK}" &>/dev/null
else
    log_error "Failed to create container with working directory"
    ((FAILED++))
fi

# =============================================================================
# Test 6: Container Creation with Command
# =============================================================================

log_section "Test 6: Container Creation with Custom Command"
CONTAINER_NAME_CMD="flexy-test-cmd-${TIMESTAMP}"

log_info "Creating container with sleep command..."

CREATE_OUTPUT=$(remote_exec "docker run -d \
  --name ${CONTAINER_NAME_CMD} \
  --network ${DOCKER_NETWORK} \
  ${TEST_IMAGE} \
  sleep 3600" 2>&1)

if [ $? -eq 0 ]; then
    CONTAINER_ID_CMD=$(echo "$CREATE_OUTPUT" | tr -d '\n\r')
    log_success "Container created: ${CONTAINER_ID_CMD:0:12}"

    # Verify command
    log_info "Verifying container command..."
    CMD_OUTPUT=$(remote_exec "docker inspect ${CONTAINER_ID_CMD} --format '{{.Config.Cmd}}'")
    if echo "$CMD_OUTPUT" | grep -q "sleep"; then
        log_success "Command set correctly"
        ((PASSED++))
    else
        log_error "Command not set: ${CMD_OUTPUT}"
        ((FAILED++))
    fi

    # Cleanup
    remote_exec "docker rm -f ${CONTAINER_ID_CMD}" &>/dev/null
else
    log_error "Failed to create container with command"
    ((FAILED++))
fi

# =============================================================================
# Test 7: Duplicate Container Name Handling
# =============================================================================

log_section "Test 7: Duplicate Container Name (Error Case)"

log_info "Attempting to create container with duplicate name..."
log_info "  Using existing name: ${CONTAINER_NAME}"

DUPLICATE_OUTPUT=$(remote_exec "docker run -d \
  --name ${CONTAINER_NAME} \
  --network ${DOCKER_NETWORK} \
  ${TEST_IMAGE}" 2>&1)

if [ $? -ne 0 ]; then
    log_success "Duplicate name error detected correctly"
    ((PASSED++))
else
    log_error "Should have failed for duplicate name"
    ((FAILED++))
fi

# =============================================================================
# Test 8: Invalid Image Handling
# =============================================================================

log_section "Test 8: Invalid Image (Error Case)"

log_info "Attempting to create container with invalid image..."

INVALID_OUTPUT=$(remote_exec "docker run -d \
  --name flexy-test-invalid-${TIMESTAMP} \
  --network ${DOCKER_NETWORK} \
  nonexistent/image:latest \
  sleep 1" 2>&1)

if [ $? -ne 0 ]; then
    log_success "Invalid image error detected correctly"
    ((PASSED++))
else
    log_error "Should have failed for invalid image"
    ((FAILED++))
    # Cleanup if somehow created
    remote_exec "docker rm -f flexy-test-invalid-${TIMESTAMP}" &>/dev/null
fi

# =============================================================================
# Cleanup
# =============================================================================

log_section "Cleanup"

log_info "Removing test container..."
remote_exec "docker rm -f ${CONTAINER_ID}" &>/dev/null
log_success "Test container removed"

# =============================================================================
# Summary
# =============================================================================

log_section "Test Summary"
TOTAL=$((PASSED + FAILED))
echo "Total tests: ${TOTAL}"
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n🎉 ${GREEN}All container creation tests passed!${NC}"
    echo ""
    echo "Tested operations:"
    echo "  ✓ Basic container creation"
    echo "  ✓ Environment variables"
    echo "  ✓ Port mappings"
    echo "  ✓ Volume mounts"
    echo "  ✓ Working directory"
    echo "  ✓ Custom command"
    echo "  ✓ Error handling (duplicate name)"
    echo "  ✓ Error handling (invalid image)"
    exit 0
else
    echo -e "\n⚠️ ${YELLOW}Some tests failed.${NC}"
    exit 1
fi

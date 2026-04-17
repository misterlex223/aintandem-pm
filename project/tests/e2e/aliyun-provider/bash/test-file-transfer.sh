#!/bin/bash
# =============================================================================
# AliyunProvider - File Transfer Test
# =============================================================================
#
# Tests uploadFile and downloadFile functionality.
# These operations use SFTP + docker cp combination.
#
# Usage: ./bootstrap/test-file-transfer.sh
#
# =============================================================================

set +e

ECS_HOST="aliyun-gz"
DOCKER_NETWORK="kai-net"
TEST_IMAGE="alpine:latest"

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
log_section "AliyunProvider File Transfer Test"
log_info "Target: ${ECS_HOST}"
echo ""

PASSED=0
FAILED=0
TIMESTAMP=$(date +%s)

# Create local test directory
TEST_DIR="./bootstrap/test-data-${TIMESTAMP}"
mkdir -p "${TEST_DIR}"

# Setup: Create test container
log_section "Setup: Create Test Container"
CONTAINER_NAME="test-sandbox-${TIMESTAMP}"

log_info "Creating container '${CONTAINER_NAME}'..."
CONTAINER_ID=$(remote_exec "docker run -d --name ${CONTAINER_NAME} --network ${DOCKER_NETWORK} ${TEST_IMAGE} sleep 3600")

if [ $? -eq 0 ] && [ -n "$CONTAINER_ID" ]; then
    log_success "Container created: ${CONTAINER_ID:0:12}"
else
    log_error "Failed to create container"
    exit 1
fi

# =============================================================================
# Test 1: Upload Text File
# =============================================================================

log_section "Test 1: Upload Text File"

# Create a test file locally
TEST_FILE_1="${TEST_DIR}/test-input.txt"
cat > "${TEST_FILE_1}" << EOF
Hello from AInTandem CE Orchestrator!
This is a test file for AliyunProvider uploadFile() method.

Created: $(date)
Timestamp: ${TIMESTAMP}

Testing special characters: @#$%^&*()
Testing Chinese: 你好世界
Testing multiline:
Line 1
Line 2
Line 3
EOF

log_file "Created local file: ${TEST_FILE_1}"

# Upload to remote
REMOTE_PATH_1="/tmp/test-uploaded.txt"

log_info "Simulating uploadFile()..."
log_info "  Local: ${TEST_FILE_1}"
log_info "  Remote in container: ${REMOTE_PATH_1}"

# AliyunProvider.uploadFile implementation:
# 1. SFTP upload to /tmp/filename
# 2. docker cp /tmp/filename container:remotePath
# 3. rm /tmp/filename

TEMP_FILENAME=$(basename "${REMOTE_PATH_1}")
scp "${TEST_FILE_1}" "${ECS_HOST}:/tmp/${TEMP_FILENAME}" &>/dev/null
remote_exec "docker cp /tmp/${TEMP_FILENAME} ${CONTAINER_ID}:${REMOTE_PATH_1}"
remote_exec "rm -f /tmp/${TEMP_FILENAME}"

# Verify upload
log_info "Verifying upload..."
UPLOADED_CONTENT=$(remote_exec "docker exec ${CONTAINER_ID} cat ${REMOTE_PATH_1}")

if [ -n "$UPLOADED_CONTENT" ]; then
    # Compare content (ignoring date line which may differ)
    if echo "$UPLOADED_CONTENT" | grep -q "Hello from AInTandem CE Orchestrator!"; then
        log_success "File uploaded successfully"
        log_file "Content preview:"
        echo "$UPLOADED_CONTENT" | head -5 | sed 's/^/  /'
        ((PASSED++))
    else
        log_error "Uploaded content mismatch"
        ((FAILED++))
    fi
else
    log_error "Failed to read uploaded file"
    ((FAILED++))
fi

# =============================================================================
# Test 2: Download File
# =============================================================================

log_section "Test 2: Download File"

# Create a file in the container first
REMOTE_FILE_2="/tmp/test-download.txt"
DOWNLOADED_FILE="${TEST_DIR}/test-downloaded.txt"

log_info "Creating file in container: ${REMOTE_FILE_2}"
remote_exec "docker exec ${CONTAINER_ID} sh -c 'cat > ${REMOTE_FILE_2} << EOF
Downloaded from Aliyun ECS!
This file was created inside the container.

Container: ${CONTAINER_NAME}
Container ID: ${CONTAINER_ID}
Timestamp: ${TIMESTAMP}
EOF'"

# Verify file exists in container
FILE_EXISTS=$(remote_exec "docker exec ${CONTAINER_ID} test -f ${REMOTE_FILE_2} && echo yes")
if [ "$FILE_EXISTS" = "yes" ]; then
    log_success "Test file created in container"
else
    log_error "Failed to create test file in container"
    ((FAILED++))
fi

# Download from container
log_info "Simulating downloadFile()..."
log_info "  Remote in container: ${REMOTE_FILE_2}"
log_info "  Local: ${DOWNLOADED_FILE}"

# AliyunProvider.downloadFile implementation:
# 1. docker cp container:remotePath /tmp/filename
# 2. SFTP download /tmp/filename
# 3. rm /tmp/filename

TEMP_FILENAME=$(basename "${REMOTE_FILE_2}")
remote_exec "docker cp ${CONTAINER_ID}:${REMOTE_FILE_2} /tmp/${TEMP_FILENAME}"
scp "${ECS_HOST}:/tmp/${TEMP_FILENAME}" "${DOWNLOADED_FILE}" &>/dev/null
remote_exec "rm -f /tmp/${TEMP_FILENAME}"

# Verify download
if [ -f "${DOWNLOADED_FILE}" ]; then
    DOWNLOADED_CONTENT=$(cat "${DOWNLOADED_FILE}")
    if echo "$DOWNLOADED_CONTENT" | grep -q "Downloaded from Aliyun ECS!"; then
        log_success "File downloaded successfully"
        log_file "Content preview:"
        head -5 "${DOWNLOADED_FILE}" | sed 's/^/  /'
        ((PASSED++))
    else
        log_error "Downloaded content mismatch"
        ((FAILED++))
    fi
else
    log_error "Failed to download file"
    ((FAILED++))
fi

# =============================================================================
# Test 3: Upload Binary File
# =============================================================================

log_section "Test 3: Upload Binary File"

# Create a small binary file
TEST_FILE_3="${TEST_DIR}/test-binary.dat"
log_info "Creating binary test file..."
dd if=/dev/urandom of="${TEST_FILE_3}" bs=1024 count=10 &>/dev/null

ORIGINAL_MD5=$(md5sum "${TEST_FILE_3}" | awk '{print $1}')
log_file "Created binary file: ${TEST_FILE_3} (10KB, MD5: ${ORIGINAL_MD5})"

REMOTE_PATH_3="/tmp/test-binary.dat"

log_info "Uploading binary file..."
TEMP_FILENAME=$(basename "${REMOTE_PATH_3}")
scp "${TEST_FILE_3}" "${ECS_HOST}:/tmp/${TEMP_FILENAME}" &>/dev/null
remote_exec "docker cp /tmp/${TEMP_FILENAME} ${CONTAINER_ID}:${REMOTE_PATH_3}"
remote_exec "rm -f /tmp/${TEMP_FILENAME}"

# Verify binary upload
log_info "Verifying binary upload..."
remote_exec "docker exec ${CONTAINER_ID} cat ${REMOTE_PATH_3}" > "${TEST_DIR}/downloaded-binary.dat"
DOWNLOADED_MD5=$(md5sum "${TEST_DIR}/downloaded-binary.dat" | awk '{print $1}')

if [ "${ORIGINAL_MD5}" = "${DOWNLOADED_MD5}" ]; then
    log_success "Binary file uploaded successfully (MD5 match)"
    ((PASSED++))
else
    log_error "Binary file corrupted during upload"
    log_error "  Original: ${ORIGINAL_MD5}"
    log_error "  After: ${DOWNLOADED_MD5}"
    ((FAILED++))
fi

# =============================================================================
# Test 4: Upload to Nested Path
# =============================================================================

log_section "Test 4: Upload to Nested Path"

TEST_FILE_4="${TEST_DIR}/test-nested.txt"
echo "Nested path test" > "${TEST_FILE_4}"

REMOTE_PATH_4="/opt/app/config/test.txt"  # Nested path

log_info "Uploading to nested path: ${REMOTE_PATH_4}"
log_info "Note: docker cp requires parent directory to exist"

# First create the directory in container
remote_exec "docker exec ${CONTAINER_ID} mkdir -p /opt/app/config"

TEMP_FILENAME=$(basename "${REMOTE_PATH_4}")
scp "${TEST_FILE_4}" "${ECS_HOST}:/tmp/${TEMP_FILENAME}" &>/dev/null
remote_exec "docker cp /tmp/${TEMP_FILENAME} ${CONTAINER_ID}:${REMOTE_PATH_4}"
remote_exec "rm -f /tmp/${TEMP_FILENAME}"

# Verify
NESTED_CONTENT=$(remote_exec "docker exec ${CONTAINER_ID} cat ${REMOTE_PATH_4}")
if echo "$NESTED_CONTENT" | grep -q "Nested path test"; then
    log_success "Upload to nested path successful (with pre-created directory)"
    ((PASSED++))
else
    log_error "Failed to upload to nested path"
    ((FAILED++))
fi

# Test 4b: Upload to nested path WITHOUT creating directory (should fail)
log_section "Test 4b: Upload to Non-existent Nested Path (Error Case)"

TEST_FILE_4B="${TEST_DIR}/test-nested-error.txt"
echo "This should fail" > "${TEST_FILE_4B}"

REMOTE_PATH_4B="/opt/new/path/test.txt"  # Non-existent directory

log_info "Attempting upload to non-existent path: ${REMOTE_PATH_4B}"

TEMP_FILENAME=$(basename "${REMOTE_PATH_4B}")
scp "${TEST_FILE_4B}" "${ECS_HOST}:/tmp/${TEMP_FILENAME}" &>/dev/null
remote_exec "docker cp /tmp/${TEMP_FILENAME} ${CONTAINER_ID}:${REMOTE_PATH_4B}" 2>/dev/null
CP_EXIT=$?
remote_exec "rm -f /tmp/${TEMP_FILENAME}"

if [ $CP_EXIT -ne 0 ]; then
    log_success "Error correctly detected for non-existent nested path"
    log_info "⚠️  AliyunProvider may need to create directories before docker cp"
    ((PASSED++))
else
    log_error "Upload succeeded unexpectedly"
    ((FAILED++))
fi

# =============================================================================
# Test 5: Download from Nested Path
# =============================================================================

log_section "Test 5: Download from Nested Path"

DOWNLOADED_NESTED="${TEST_DIR}/test-nested-downloaded.txt"

log_info "Downloading from nested path: ${REMOTE_PATH_4}"

TEMP_FILENAME=$(basename "${REMOTE_PATH_4}")
remote_exec "docker cp ${CONTAINER_ID}:${REMOTE_PATH_4} /tmp/${TEMP_FILENAME}"
scp "${ECS_HOST}:/tmp/${TEMP_FILENAME}" "${DOWNLOADED_NESTED}" &>/dev/null
remote_exec "rm -f /tmp/${TEMP_FILENAME}"

if [ -f "${DOWNLOADED_NESTED}" ] && grep -q "Nested path test" "${DOWNLOADED_NESTED}"; then
    log_success "Download from nested path successful"
    ((PASSED++))
else
    log_error "Failed to download from nested path"
    ((FAILED++))
fi

# =============================================================================
# Test 6: Large File Transfer
# =============================================================================

log_section "Test 6: Large File Transfer (100KB)"

TEST_FILE_6="${TEST_DIR}/test-large.txt"
log_info "Creating large test file (100KB)..."
dd if=/dev/urandom of="${TEST_FILE_6}" bs=1024 count=100 &>/dev/null

LARGE_FILE_SIZE=$(wc -c < "${TEST_FILE_6}")
log_file "Created file: ${LARGE_FILE_SIZE} bytes"

REMOTE_PATH_6="/tmp/test-large.txt"

log_info "Uploading large file..."
TEMP_FILENAME=$(basename "${REMOTE_PATH_6}")
scp "${TEST_FILE_6}" "${ECS_HOST}:/tmp/${TEMP_FILENAME}" &>/dev/null
remote_exec "docker cp /tmp/${TEMP_FILENAME} ${CONTAINER_ID}:${REMOTE_PATH_6}"
remote_exec "rm -f /tmp/${TEMP_FILENAME}"

# Verify size inside container
REMOTE_SIZE=$(remote_exec "docker exec ${CONTAINER_ID} stat -c%s ${REMOTE_PATH_6}")

if [ "${REMOTE_SIZE}" = "${LARGE_FILE_SIZE}" ]; then
    log_success "Large file uploaded successfully (size match)"
    ((PASSED++))
else
    log_error "Large file size mismatch"
    log_error "  Local: ${LARGE_FILE_SIZE} bytes"
    log_error "  Remote: ${REMOTE_SIZE} bytes"
    ((FAILED++))
fi

# =============================================================================
# Test 7: Error Handling - Non-existent Remote File
# =============================================================================

log_section "Test 7: Error Handling - Non-existent Remote File"

DOWNLOADED_ERROR="${TEST_DIR}/test-error.txt"

log_info "Attempting to download non-existent file..."

# This should fail gracefully
TEMP_FILENAME="nonexistent.txt"
remote_exec "docker cp ${CONTAINER_ID}:/tmp/nonexistent.txt /tmp/${TEMP_FILENAME}" 2>/dev/null
DOWNLOAD_EXIT=$?

if [ $DOWNLOAD_EXIT -ne 0 ]; then
    log_success "Error handled correctly (non-existent file)"
    ((PASSED++))
else
    log_error "Should have failed for non-existent file"
    ((FAILED++))
fi

# =============================================================================
# Cleanup
# =============================================================================

log_section "Cleanup"

# Clean up container
log_info "Removing test container..."
remote_exec "docker rm -f ${CONTAINER_ID}" &>/dev/null
log_success "Container removed"

# Clean up local test files
log_info "Removing local test files..."
rm -rf "${TEST_DIR}"
log_success "Local files cleaned up"

# =============================================================================
# Summary
# =============================================================================

log_section "Test Summary"
TOTAL=$((PASSED + FAILED))
echo "Total tests: ${TOTAL}"
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n🎉 ${GREEN}All file transfer tests passed!${NC}"
    echo ""
    echo "Tested operations:"
    echo "  ✓ uploadFile() - text files"
    echo "  ✓ downloadFile() - text files"
    echo "  ✓ uploadFile() - binary files (MD5 verified)"
    echo "  ✓ uploadFile() - nested paths (with pre-created directory)"
    echo "  ✓ uploadFile() - error detection for non-existent paths"
    echo "  ✓ downloadFile() - nested paths"
    echo "  ✓ Large file transfers (100KB)"
    echo "  ✓ Error handling for non-existent files"
    exit 0
else
    echo -e "\n⚠️ ${YELLOW}Some tests failed.${NC}"
    exit 1
fi

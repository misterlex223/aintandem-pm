#!/bin/bash
# =============================================================================
# AInTandem CE Orchestrator - Aliyun ECS Initialization Script
# =============================================================================
#
# This script initializes an Aliyun ECS instance for use with the CE Orchestrator.
# It installs Docker, creates the required network, and configures the system.
#
# Usage:
#   ./bootstrap/init-ecs.sh [host]
#
# Arguments:
#   host    - SSH hostname (default: aliyun-gz)
#
# Example:
#   ./bootstrap/init-ecs.sh aliyun-gz
#   ./bootstrap/init-ecs.sh 8.134.76.139
#
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ECS_HOST="${1:-aliyun-gz}"
DOCKER_NETWORK="kai-net"
BASE_ROOT="/data"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if host is reachable
check_host() {
    log_info "Checking connectivity to ${ECS_HOST}..."

    if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "${ECS_HOST}" "echo 'Connection successful'" 2>/dev/null; then
        log_error "Cannot connect to ${ECS_HOST}. Please check:"
        echo "  - SSH config in ~/.ssh/config"
        echo "  - Network connectivity"
        echo "  - SSH key permissions"
        exit 1
    fi

    log_success "Connection to ${ECS_HOST} established"
}

# Execute command on remote host
remote_exec() {
    ssh "${ECS_HOST}" "$1"
}

# Copy file to remote host
remote_copy() {
    scp "$1" "${ECS_HOST}:$2"
}

# Main initialization process
main() {
    log_info "=========================================="
    log_info "AInTandem CE - ECS Initialization"
    log_info "Target: ${ECS_HOST}"
    log_info "=========================================="
    echo ""

    # Check connectivity
    check_host
    echo ""

    # Get OS information
    log_info "Detecting OS..."
    OS_INFO=$(remote_exec "cat /etc/os-release | grep PRETTY_NAME")
    log_success "OS: ${OS_INFO}"
    echo ""

    # Check if running as root (need sudo)
    log_info "Checking sudo access..."
    if ! remote_exec "sudo -n true" 2>/dev/null; then
        log_warning "Sudo requires password. You may be prompted during installation."
    else
        log_success "Sudo access confirmed"
    fi
    echo ""

    # Update system packages
    log_info "Updating system packages..."
    remote_exec "sudo yum update -y || sudo apt-get update -y"
    log_success "System packages updated"
    echo ""

    # Install Docker
    log_info "Checking Docker installation..."
    DOCKER_VERSION=$(remote_exec "docker --version 2>/dev/null" || echo "")

    if [ -z "$DOCKER_VERSION" ]; then
        log_info "Docker not found. Installing Docker..."

        # Detect OS family and install accordingly
        if remote_exec "cat /etc/os-release | grep -i 'centos\|rhel\|almalinux' &>/dev/null"; then
            log_info "Installing Docker on RHEL/CentOS/AlmaLinux..."
            remote_exec "sudo yum install -y yum-utils && \
                        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && \
                        sudo yum install -y docker-ce docker-ce-cli containerd.io"
        elif remote_exec "cat /etc/os-release | grep -i 'ubuntu\|debian' &>/dev/null"; then
            log_info "Installing Docker on Ubuntu/Debian..."
            remote_exec "sudo apt-get update && \
                        sudo apt-get install -y ca-certificates curl gnupg && \
                        sudo install -m 0755 -d /etc/apt/keyrings && \
                        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
                        sudo chmod a+r /etc/apt/keyrings/docker.gpg && \
                        echo \"deb [arch=\"\$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(. /etc/os-release && echo \"\$VERSION_CODENAME\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
                        sudo apt-get update && \
                        sudo apt-get install -y docker-ce docker-ce-cli containerd.io"
        fi

        log_success "Docker installed"
    else
        log_success "Docker already installed: ${DOCKER_VERSION}"
    fi
    echo ""

    # Start and enable Docker service
    log_info "Starting Docker service..."
    remote_exec "sudo systemctl start docker || sudo service docker start"
    remote_exec "sudo systemctl enable docker || true"
    log_success "Docker service started"
    echo ""

    # Create Docker network
    log_info "Creating Docker network '${DOCKER_NETWORK}'..."
    NETWORK_EXISTS=$(remote_exec "docker network ls -q -f name=${DOCKER_NETWORK}" || echo "")

    if [ -z "$NETWORK_EXISTS" ]; then
        remote_exec "sudo docker network create ${DOCKER_NETWORK}"
        log_success "Docker network '${DOCKER_NETWORK}' created"
    else
        log_success "Docker network '${DOCKER_NETWORK}' already exists"
    fi
    echo ""

    # Create base root directory
    log_info "Creating base root directory '${BASE_ROOT}'..."
    remote_exec "sudo mkdir -p ${BASE_ROOT} && sudo chmod 777 ${BASE_ROOT}"
    log_success "Base root directory created"
    echo ""

    # Verify installation
    log_info "Verifying installation..."
    DOCKER_VER=$(remote_exec "docker --version")
    NETWORKS=$(remote_exec "docker network ls | grep ${DOCKER_NETWORK} || true")
    BASE_ROOT_EXISTS=$(remote_exec "test -d ${BASE_ROOT} && echo 'exists'")

    echo ""
    log_info "=========================================="
    log_success "ECS Initialization Complete!"
    log_info "=========================================="
    echo ""
    echo "Summary:"
    echo "  Host: ${ECS_HOST}"
    echo "  Docker: ${DOCKER_VER}"
    echo "  Network: ${DOCKER_NETWORK}"
    echo "  Base Root: ${BASE_ROOT} (${BASE_ROOT_EXISTS})"
    echo ""
    log_info "Your ECS is ready for use with CE Orchestrator!"
    echo ""
    log_info "Next steps:"
    echo "  1. Configure providers.yaml with your ECS details"
    echo "  2. Test connection: pnpm test:unit -- -t 'AliyunProvider.*testConnection'"
    echo ""
}

# Run main function
main "$@"

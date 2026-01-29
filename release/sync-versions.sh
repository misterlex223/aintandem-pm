#!/bin/bash
# sync-versions.sh - Version synchronization script for AInTandem meta repo
#
# Usage:
#   ./sync-versions.sh check      # Check version consistency
#   ./sync-versions.sh status     # Show current version status
#   ./sync-versions.sh help       # Show help

set -e

REPOS_DIR="$(dirname "$0")/../repos"
CORE_REPO="ce-orchestrator"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

get_version() {
    local repo=$1
    local pkg_json="$REPOS_DIR/$repo/package.json"
    if [ -f "$pkg_json" ]; then
        grep '"version"' "$pkg_json" | head -1 | sed 's/.*"version": "\(.*\)".*/\1/'
    else
        echo "N/A"
    fi
}

check_versions() {
    echo -e "${BLUE}=== Version Consistency Check ===${NC}\n"

    local core_version=$(get_version "$CORE_REPO")
    echo -e "Core version: ${GREEN}$core_version${NC} ($CORE_REPO)"
    echo

    printf "%-20s %-12s %s\n" "Repo" "Version" "Status"
    printf "%-20s %-12s %s\n" "----" "-------" "------"

    for repo in "$REPOS_DIR"/*; do
        repo_name=$(basename "$repo")
        version=$(get_version "$repo_name")

        if [ "$repo_name" = "aintandem-org" ]; then
            printf "%-20s %-12s %s\n" "$repo_name" "$version" "${BLUE}➖ Independent${NC}"
        elif [ "$version" = "$core_version" ]; then
            printf "%-20s %-12s %s\n" "$repo_name" "$version" "${GREEN}✓ Match${NC}"
        else
            printf "%-20s %-12s %s\n" "$repo_name" "$version" "${RED}✗ Mismatch${NC}"
        fi
    done
}

show_status() {
    echo -e "${BLUE}=== Submodule Status ===${NC}\n"

    git submodule status

    echo
    echo -e "${BLUE}=== Version Summary ===${NC}\n"

    for repo in "$REPOS_DIR"/*; do
        repo_name=$(basename "$repo")
        version=$(get_version "$repo_name")
        printf "%-20s %s\n" "$repo_name:" "$version"
    done
}

show_help() {
    cat << EOF
sync-versions.sh - AInTandem version synchronization tool

Usage:
    ./sync-versions.sh check      Check version consistency across repos
    ./sync-versions.sh status     Show submodule and version status
    ./sync-versions.sh help       Show this help message

Meta Repo Structure:
    repos/
    ├── ce-orchestrator/    # Core (reference version)
    ├── ce-console/         # Follows core
    ├── ce-desktop/         # Follows core
    ├── orchestrator-sdk/    # Follows core
    └── aintandem-org/       # Independent
EOF
}

case "${1:-help}" in
    check)
        check_versions
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac

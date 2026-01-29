#!/bin/bash
# sync-versions.sh - Version synchronization script for AInTandem meta repo
#
# Usage:
#   ./sync-versions.sh check      # Check version consistency
#   ./sync-versions.sh status     # Show current version status
#   ./sync-versions.sh sync VERSION  # Sync all repos to VERSION
#   ./sync-versions.sh help       # Show help

set -e

REPOS_DIR="$(cd "$(dirname "$0")" && pwd)/../repos"
CORE_REPO="ce-orchestrator"
VERSION_STATE_FILE=".claude/version-state.json"

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
    local GIT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
    echo -e "${BLUE}=== Submodule Status ===${NC}\n"

    cd "$GIT_ROOT"
    git submodule status 2>&1 | grep -v "fatal" || echo "無法獲取 submodule 狀態"

    echo
    echo -e "${BLUE}=== Version Summary ===${NC}\n"

    for repo in "$REPOS_DIR"/*; do
        repo_name=$(basename "$repo")
        version=$(get_version "$repo_name")
        printf "%-20s %s\n" "$repo_name:" "$version"
    done
}

sync_versions() {
    local target_version="$1"

    if [ -z "$target_version" ]; then
        echo -e "${RED}錯誤: 請指定目標版本號${NC}"
        echo "用法: ./sync-versions.sh sync VERSION"
        exit 1
    fi

    echo -e "${BLUE}=== 同步版本到 $target_version ===${NC}\n"

    # 更新各 submodule 的 package.json
    for repo_path in "$REPOS_DIR"/*; do
        repo_name=$(basename "$repo_path")

        if [ "$repo_name" = "aintandem-org" ]; then
            echo -e "${BLUE}跳過${NC} $repo_name (獨立版本)"
            continue
        fi

        local pkg_json="$repo_path/package.json"
        if [ ! -f "$pkg_json" ]; then
            echo -e "${YELLOW}跳過${NC} $repo_name (沒有 package.json)"
            continue
        fi

        echo -e "更新 ${GREEN}$repo_name${NC} -> $target_version"

        # 使用 jq 更新版本號
        jq --arg v "$target_version" '.version = $v' "$pkg_json" > "$pkg_json.tmp"
        mv "$pkg_json.tmp" "$pkg_json"
    done

    # 更新 version-state.json
    if [ -f "$VERSION_STATE_FILE" ]; then
        echo -e "\n更新 version-state.json"
        jq --arg v "$target_version" \
            '.metaRepo.currentVersion = $v | .metaRepo.nextVersion = $v |
            .submodules | to_entries[] | select(.value.syncStrategy == "follow") | .value.currentVersion = $v | .value.targetVersion = $v' \
            "$VERSION_STATE_FILE" > "$VERSION_STATE_FILE.tmp"
        mv "$VERSION_STATE_FILE.tmp" "$VERSION_STATE_FILE"
    fi

    echo -e "\n${GREEN}✓ 版本同步完成${NC}"
    echo ""
    echo "下一步："
    echo "  1. 檢查變更: git status"
    echo "  2. 提交變更: git add . && git commit -m \"chore: sync versions to $target_version\""
    echo "  3. 建立標籤: git tag -a v$target_version -m \"Release v$target_version\""
}

show_help() {
    cat << EOF
sync-versions.sh - AInTandem version synchronization tool

Usage:
    ./sync-versions.sh check      Check version consistency across repos
    ./sync-versions.sh status     Show submodule and version status
    ./sync-versions.sh sync VER   Sync all repos to VERSION
    ./sync-versions.sh help       Show this help message

Meta Repo Structure:
    repos/
    ├── ce-orchestrator/    # Core (reference version)
    ├── ce-console/         # Follows core
    ├── ce-desktop/         # Follows core
    ├── orchestrator-sdk/    # Follows core
    └── aintandem-org/       # Independent

Version Strategy:
    - ce-orchestrator sets the core version
    - ce-console, ce-desktop, orchestrator-sdk follow core
    - aintandem-org maintains independent version
EOF
}

case "${1:-help}" in
    check)
        check_versions
        ;;
    status)
        show_status
        ;;
    sync)
        sync_versions "$2"
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

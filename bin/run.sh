#!/bin/bash
# =============================================================================
# run.sh - Run stego-toolkit Docker containers
# Part of stego-toolkit (2025 refresh)
# =============================================================================
# Usage:
#   ./run.sh              # Run full image (default)
#   ./run.sh --cli        # Run CLI-only image
#   ./run.sh --gpu        # Run GPU-accelerated image
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/shared.sh"

PROJECT_ROOT="$(abspath "${SCRIPT_DIR}/..")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [-- COMMAND]

Run stego-toolkit Docker container.

Options:
    -h, --help      Show this help message
    --full          Run full image with GUI support (default)
    --cli           Run CLI-only lightweight image
    --gpu           Run GPU-accelerated image (requires NVIDIA)
    --root          Run as root user instead of stego
    --no-mount      Don't mount local directories

Examples:
    $(basename "$0")                          # Interactive shell in full image
    $(basename "$0") --cli                    # Interactive shell in CLI image
    $(basename "$0") --gpu                    # Interactive shell with GPU
    $(basename "$0") -- check_jpg.sh test.jpg # Run specific command
    $(basename "$0") --cli -- stegseek img.jpg wordlist.txt
EOF
    exit 0
}

# Defaults
IMAGE_TAG="latest"
RUN_AS_ROOT=0
MOUNT_DIRS=1
GPU_MODE=0

# Parse arguments
EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        --full)
            IMAGE_TAG="latest"
            shift
            ;;
        --cli)
            IMAGE_TAG="cli"
            shift
            ;;
        --gpu)
            IMAGE_TAG="gpu"
            GPU_MODE=1
            shift
            ;;
        --root)
            RUN_AS_ROOT=1
            shift
            ;;
        --no-mount)
            MOUNT_DIRS=0
            shift
            ;;
        --)
            shift
            EXTRA_ARGS=("$@")
            break
            ;;
        *)
            EXTRA_ARGS+=("$1")
            shift
            ;;
    esac
done

IMAGE_NAME="stego-toolkit:${IMAGE_TAG}"

echo -e "${BLUE}Starting stego-toolkit container...${NC}"
echo "Image: ${IMAGE_NAME}"
echo ""

# Build docker run command
DOCKER_ARGS=("-it" "--rm")

# GPU support
if [[ $GPU_MODE -eq 1 ]]; then
    DOCKER_ARGS+=("--gpus" "all")
    echo -e "${YELLOW}GPU mode enabled${NC}"
fi

# Port mappings (only for full image)
if [[ "$IMAGE_TAG" == "latest" ]]; then
    DOCKER_ARGS+=("-p" "127.0.0.1:22:22")
    DOCKER_ARGS+=("-p" "127.0.0.1:5901:5901")
    DOCKER_ARGS+=("-p" "127.0.0.1:6901:6901")
    echo "Exposed ports: 22 (SSH), 5901 (VNC), 6901 (noVNC)"
fi

# Volume mounts
if [[ $MOUNT_DIRS -eq 1 ]]; then
    DOCKER_ARGS+=("-v" "${PROJECT_ROOT}/data:/data")
    DOCKER_ARGS+=("-v" "${PROJECT_ROOT}/scripts:/opt/scripts")
    DOCKER_ARGS+=("-v" "${PROJECT_ROOT}/examples:/examples")
    echo "Mounted: data/, scripts/, examples/"
fi

# User
if [[ $RUN_AS_ROOT -eq 1 ]]; then
    DOCKER_ARGS+=("-u" "root")
    echo -e "${YELLOW}Running as root${NC}"
fi

echo ""

# Run container
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
    docker run "${DOCKER_ARGS[@]}" "${IMAGE_NAME}" "${EXTRA_ARGS[@]}"
else
    docker run "${DOCKER_ARGS[@]}" "${IMAGE_NAME}" /bin/bash
fi

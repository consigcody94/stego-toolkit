#!/bin/bash
# =============================================================================
# build.sh - Build stego-toolkit Docker images
# Part of stego-toolkit (2025 refresh)
# =============================================================================
# Usage:
#   ./build.sh              # Build full image (default)
#   ./build.sh --cli        # Build CLI-only (lightweight)
#   ./build.sh --gpu        # Build GPU-accelerated image
#   ./build.sh --all        # Build all variants
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
Usage: $(basename "$0") [OPTIONS]

Build stego-toolkit Docker images.

Options:
    -h, --help      Show this help message
    --full          Build full image with GUI support (default)
    --cli           Build CLI-only lightweight image
    --gpu           Build GPU-accelerated image (requires NVIDIA)
    --all           Build all image variants
    --no-cache      Build without using cache

Image Variants:
    full    ~2.5GB  Full image with GUI tools (VNC, X11)
    cli     ~1.5GB  CLI-only, no GUI dependencies
    gpu     ~8GB    GPU-accelerated with CUDA, hashcat, PyTorch

Examples:
    $(basename "$0")              # Build full image
    $(basename "$0") --cli        # Build lightweight CLI image
    $(basename "$0") --gpu        # Build GPU image
    $(basename "$0") --all        # Build all variants
EOF
    exit 0
}

build_image() {
    local variant="$1"
    local dockerfile="$2"
    local tag="$3"

    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Building: stego-toolkit:${tag}${NC}"
    echo -e "${BLUE}  Dockerfile: ${dockerfile}${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    local cache_arg=""
    if [[ "${NO_CACHE:-0}" == "1" ]]; then
        cache_arg="--no-cache"
    fi

    if docker build \
        -f "${PROJECT_ROOT}/${dockerfile}" \
        -t "stego-toolkit:${tag}" \
        ${cache_arg} \
        "${PROJECT_ROOT}"; then
        echo ""
        echo -e "${GREEN}[SUCCESS]${NC} stego-toolkit:${tag} built successfully"
    else
        echo ""
        echo -e "${RED}[FAILED]${NC} Failed to build stego-toolkit:${tag}"
        return 1
    fi
}

# Parse arguments
BUILD_FULL=0
BUILD_CLI=0
BUILD_GPU=0
NO_CACHE=0

if [[ $# -eq 0 ]]; then
    BUILD_FULL=1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        --full)
            BUILD_FULL=1
            shift
            ;;
        --cli)
            BUILD_CLI=1
            shift
            ;;
        --gpu)
            BUILD_GPU=1
            shift
            ;;
        --all)
            BUILD_FULL=1
            BUILD_CLI=1
            BUILD_GPU=1
            shift
            ;;
        --no-cache)
            NO_CACHE=1
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

echo ""
echo -e "${BLUE}Stego-Toolkit Docker Image Builder${NC}"
echo "Project root: ${PROJECT_ROOT}"
echo ""

# Build requested variants
BUILT=0
FAILED=0

if [[ $BUILD_FULL -eq 1 ]]; then
    if build_image "full" "Dockerfile" "latest"; then
        ((BUILT++))
    else
        ((FAILED++))
    fi
    echo ""
fi

if [[ $BUILD_CLI -eq 1 ]]; then
    if build_image "cli" "Dockerfile.cli" "cli"; then
        ((BUILT++))
    else
        ((FAILED++))
    fi
    echo ""
fi

if [[ $BUILD_GPU -eq 1 ]]; then
    echo -e "${YELLOW}Note: GPU image requires NVIDIA drivers and nvidia-container-toolkit${NC}"
    if build_image "gpu" "Dockerfile.gpu" "gpu"; then
        ((BUILT++))
    else
        ((FAILED++))
    fi
    echo ""
fi

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Build Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}Built: ${BUILT}${NC}"
echo -e "  ${RED}Failed: ${FAILED}${NC}"
echo ""

if [[ $BUILD_FULL -eq 1 ]]; then
    echo "Run full image:  docker run -it --rm -v \$(pwd)/data:/data stego-toolkit:latest"
fi
if [[ $BUILD_CLI -eq 1 ]]; then
    echo "Run CLI image:   docker run -it --rm -v \$(pwd)/data:/data stego-toolkit:cli"
fi
if [[ $BUILD_GPU -eq 1 ]]; then
    echo "Run GPU image:   docker run --gpus all -it --rm -v \$(pwd)/data:/data stego-toolkit:gpu"
fi
echo ""

exit $FAILED

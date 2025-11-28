#!/bin/bash
# =============================================================================
# build.sh - Build the stego-toolkit Docker image
# Part of stego-toolkit (2025 refresh)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/shared.sh"

PROJECT_ROOT="$(abspath "${SCRIPT_DIR}/..")"

echo "Building stego-toolkit Docker image..."
echo "Image name: ${IMAGE_NAME}"
echo "Project root: ${PROJECT_ROOT}"
echo ""

docker build \
    -f "${PROJECT_ROOT}/Dockerfile" \
    -t "${IMAGE_NAME}" \
    "${PROJECT_ROOT}"

echo ""
echo "Build complete!"
echo "Run with: ${SCRIPT_DIR}/run.sh"
echo "Or: docker run -it --rm -v \$(pwd)/data:/data ${IMAGE_NAME}"

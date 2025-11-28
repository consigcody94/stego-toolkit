#!/bin/bash
# =============================================================================
# run.sh - Run the stego-toolkit Docker container
# Part of stego-toolkit (2025 refresh)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/shared.sh"

PROJECT_ROOT="$(abspath "${SCRIPT_DIR}/..")"

echo "Starting stego-toolkit container..."
echo "Image: ${IMAGE_NAME}"
echo ""
echo "Mounted volumes:"
echo "  - ${PROJECT_ROOT}/data -> /data"
echo "  - ${PROJECT_ROOT}/scripts -> /opt/scripts"
echo "  - ${PROJECT_ROOT}/examples -> /examples"
echo ""
echo "Exposed ports:"
echo "  - 22 (SSH with X11 forwarding)"
echo "  - 5901 (VNC)"
echo "  - 6901 (noVNC web interface)"
echo ""

docker run -it \
    --rm \
    -p 127.0.0.1:22:22 \
    -p 127.0.0.1:5901:5901 \
    -p 127.0.0.1:6901:6901 \
    -v "${PROJECT_ROOT}/data:/data" \
    -v "${PROJECT_ROOT}/scripts:/opt/scripts" \
    -v "${PROJECT_ROOT}/examples:/examples" \
    "${IMAGE_NAME}" \
    /bin/bash

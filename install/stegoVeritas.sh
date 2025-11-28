#!/bin/bash
# =============================================================================
# Install stegoveritas - Multi-tool stego analyzer
# https://github.com/bannsec/stegoVeritas
# =============================================================================
set -e

echo "Installing stegoveritas..."

# Install via pip (already done in Dockerfile, but keeping for standalone use)
pip3 install --break-system-packages --no-cache-dir stegoveritas

# Install dependencies (may require user interaction in some cases)
echo "Installing stegoveritas dependencies..."
stegoveritas_install_deps || true

# Verify installation
if command -v stegoveritas &> /dev/null; then
    echo "stegoveritas installed successfully"
else
    echo "Warning: stegoveritas installation may have failed"
fi

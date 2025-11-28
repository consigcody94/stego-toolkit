#!/bin/bash
# =============================================================================
# Install stegcracker - Steganography brute-force utility
# https://github.com/Paradoxis/StegCracker
# =============================================================================
set -e

echo "Installing stegcracker..."

# Install via pip
pip3 install --break-system-packages --no-cache-dir stegcracker

# Verify installation
if command -v stegcracker &> /dev/null; then
    echo "stegcracker installed successfully: $(stegcracker --version 2>&1 | head -1 || echo 'version check unavailable')"
else
    echo "Warning: stegcracker installation may have failed"
fi

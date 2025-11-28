#!/bin/bash
# =============================================================================
# Install Stegano - Python steganography module
# https://github.com/cedricbonhomme/Stegano
# =============================================================================
set -e

echo "Installing Stegano..."

# Install via pip (modern approach, provides CLI tools automatically)
pip3 install --break-system-packages --no-cache-dir stegano

# Verify installation
if command -v stegano-lsb &> /dev/null; then
    echo "Stegano installed successfully"
    echo "Available commands: stegano-lsb, stegano-lsb-set, stegano-red"
else
    echo "Warning: Stegano installation may have failed"
fi

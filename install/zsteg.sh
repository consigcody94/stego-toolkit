#!/bin/bash
# =============================================================================
# Install zsteg - PNG/BMP LSB steganography detector
# https://github.com/zed-0xff/zsteg
# =============================================================================
set -e

echo "Installing zsteg..."

# Install via gem (already done in Dockerfile, but keeping for standalone use)
gem install zsteg --no-document

# Verify installation
if command -v zsteg &> /dev/null; then
    echo "zsteg installed successfully: $(zsteg --version 2>&1 || echo 'version check unavailable')"
else
    echo "Warning: zsteg installation may have failed"
fi

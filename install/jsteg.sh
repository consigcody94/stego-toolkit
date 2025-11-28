#!/bin/bash
# =============================================================================
# Install jsteg - LSB steganography tool for JPEG images
# https://github.com/lukechampine/jsteg
# =============================================================================
set -e

echo "Installing jsteg..."

ARCH=$(dpkg --print-architecture)

case $ARCH in
    amd64)
        JSTEG_ARCH="amd64"
        ;;
    arm64)
        JSTEG_ARCH="arm64"
        ;;
    *)
        echo "Warning: jsteg may not support architecture: $ARCH"
        JSTEG_ARCH="amd64"
        ;;
esac

# Install jsteg
wget -q -O /usr/local/bin/jsteg "https://github.com/lukechampine/jsteg/releases/download/v0.3.0/jsteg-linux-${JSTEG_ARCH}"
chmod +x /usr/local/bin/jsteg

# Install slink (related tool for PNG)
wget -q -O /usr/local/bin/slink "https://github.com/lukechampine/jsteg/releases/download/v0.3.0/slink-linux-${JSTEG_ARCH}"
chmod +x /usr/local/bin/slink

# Verify installation
if command -v jsteg &> /dev/null; then
    echo "jsteg installed successfully"
else
    echo "Warning: jsteg installation may have failed"
fi

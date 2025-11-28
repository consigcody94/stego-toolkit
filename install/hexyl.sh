#!/bin/bash
# =============================================================================
# Install hexyl - A modern hex viewer with colored output
# https://github.com/sharkdp/hexyl
# =============================================================================
set -e

echo "Installing hexyl..."

# Try to install from apt first (available in newer Debian/Ubuntu)
if apt-get install -y -qq hexyl 2>/dev/null; then
    echo "hexyl installed from apt"
else
    # Fall back to downloading from GitHub releases
    echo "Installing hexyl from GitHub releases..."
    HEXYL_VERSION="0.14.0"
    ARCH=$(dpkg --print-architecture)

    case $ARCH in
        amd64)
            HEXYL_ARCH="x86_64"
            ;;
        arm64)
            HEXYL_ARCH="aarch64"
            ;;
        *)
            echo "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    HEXYL_URL="https://github.com/sharkdp/hexyl/releases/download/v${HEXYL_VERSION}/hexyl-v${HEXYL_VERSION}-${HEXYL_ARCH}-unknown-linux-gnu.tar.gz"

    cd /tmp
    wget -q "${HEXYL_URL}" -O hexyl.tar.gz
    tar -xzf hexyl.tar.gz
    mv hexyl-*/hexyl /usr/local/bin/
    rm -rf hexyl.tar.gz hexyl-*
fi

# Verify installation
if command -v hexyl &> /dev/null; then
    echo "hexyl installed successfully: $(hexyl --version 2>&1)"
else
    echo "Warning: hexyl installation may have failed"
fi

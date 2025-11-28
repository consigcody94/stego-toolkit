#!/bin/bash
# =============================================================================
# Install stegseek - Lightning fast steghide cracker
# https://github.com/RickdeJager/stegseek
# =============================================================================
set -e

echo "Installing stegseek..."

# Get the latest release version
STEGSEEK_VERSION="0.6"
STEGSEEK_DEB="stegseek_${STEGSEEK_VERSION}-1.deb"
STEGSEEK_URL="https://github.com/RickdeJager/stegseek/releases/download/v${STEGSEEK_VERSION}/${STEGSEEK_DEB}"

# Download and install the .deb package
cd /tmp
wget -q "${STEGSEEK_URL}" -O "${STEGSEEK_DEB}"
apt-get update -qq
apt-get install -y -qq "./${STEGSEEK_DEB}"
rm -f "${STEGSEEK_DEB}"

# Verify installation
if command -v stegseek &> /dev/null; then
    echo "stegseek installed successfully: $(stegseek --version 2>&1 | head -1)"
else
    echo "Warning: stegseek installation may have failed"
fi

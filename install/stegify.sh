#!/bin/bash
# =============================================================================
# stegify - Go-based LSB steganography tool (1253+ GitHub stars)
# Fast and simple LSB steganography for hiding files in images
# https://github.com/DimitarPetrov/stegify
# =============================================================================
set -euo pipefail

echo "=== Installing stegify ==="

# Determine architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH_NAME="amd64" ;;
    aarch64) ARCH_NAME="arm64" ;;
    armv7l)  ARCH_NAME="arm" ;;
    *)       ARCH_NAME="amd64" ;;
esac

# Get latest release version
STEGIFY_VERSION=$(curl -s https://api.github.com/repos/DimitarPetrov/stegify/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' || echo "v1.2.0")

# Download URL
STEGIFY_URL="https://github.com/DimitarPetrov/stegify/releases/download/${STEGIFY_VERSION}/stegify_Linux_${ARCH_NAME}.tar.gz"

echo "Downloading stegify ${STEGIFY_VERSION} for ${ARCH_NAME}..."
if wget -q -O /tmp/stegify.tar.gz "$STEGIFY_URL"; then
    tar -xzf /tmp/stegify.tar.gz -C /tmp/
    mv /tmp/stegify /usr/local/bin/stegify
    chmod +x /usr/local/bin/stegify
    rm -f /tmp/stegify.tar.gz
    echo "stegify installed successfully"
else
    echo "Warning: Could not download pre-built binary"
    echo "Attempting to build from source..."

    # Install Go if not present
    if ! command -v go &> /dev/null; then
        apt-get update -qq
        apt-get install -y -qq golang-go
    fi

    # Build from source
    go install github.com/DimitarPetrov/stegify@latest
    cp ~/go/bin/stegify /usr/local/bin/ 2>/dev/null || true
fi

# Create help wrapper
cat << 'EOF' > /usr/local/bin/stegify-help
#!/bin/bash
echo "stegify - Go-based LSB Steganography Tool"
echo ""
echo "Hide any file inside a PNG/JPEG/GIF/BMP image using LSB steganography."
echo ""
echo "Usage:"
echo "  Encode (hide file):"
echo "    stegify encode --carrier cover.png --data secret.zip --result stego.png"
echo ""
echo "  Decode (extract file):"
echo "    stegify decode --carrier stego.png --result extracted.zip"
echo ""
echo "Options:"
echo "  --carrier    The carrier image file"
echo "  --data       The file to hide (encode only)"
echo "  --result     The output file"
echo ""
echo "Supported formats: PNG, JPEG, GIF, BMP"
echo ""
echo "Note: No password protection - purely LSB-based hiding"
echo "      Great for quickly hiding files in images"
echo ""
echo "GitHub: https://github.com/DimitarPetrov/stegify"
EOF
chmod +x /usr/local/bin/stegify-help

echo "=== stegify installed ==="
stegify --help 2>/dev/null | head -5 || echo "stegify ready"

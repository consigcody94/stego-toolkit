#!/bin/bash
# =============================================================================
# Steganabara - Image steganography analyzer (Java GUI)
# Updated for 2025 - modern download handling
# =============================================================================
set -euo pipefail

echo "=== Installing Steganabara ==="

# Check for Java
if ! command -v java &> /dev/null; then
    echo "Warning: Java is required for Steganabara"
    apt-get install -y --no-install-recommends default-jre-headless || true
fi

# Download Steganabara
STEGANABARA_URL="http://www.caesum.com/handbook/steganabara-1.1.1.tar.gz"
echo "Downloading Steganabara..."
if wget -q -O /tmp/steganabara.tar.gz "$STEGANABARA_URL" 2>/dev/null; then
    mkdir -p /opt/steganabara
    tar -xf /tmp/steganabara.tar.gz -C /opt/steganabara
    rm /tmp/steganabara.tar.gz
    echo "Steganabara downloaded and extracted"
else
    echo "Warning: Could not download Steganabara"
    echo "You may need to download it manually from: http://www.caesum.com/handbook/stego.htm"
fi

# Create wrapper script
cat << 'EOF' > /usr/local/bin/steganabara
#!/bin/bash
# Steganabara - Image steganography analyzer
# Requires Java and X11 display
set -euo pipefail

STEGANABARA_DIR="/opt/steganabara/Steganabara"

if ! command -v java &> /dev/null; then
    echo "Error: Java is required for Steganabara"
    exit 1
fi

if [[ -d "$STEGANABARA_DIR/bin" ]]; then
    java -cp "$STEGANABARA_DIR/bin" steganabara.Steganabara "$@"
else
    echo "Error: Steganabara not found"
    echo "Please reinstall from: http://www.caesum.com/handbook/stego.htm"
    exit 1
fi
EOF
chmod +x /usr/local/bin/steganabara

# Create help
cat << 'EOF' > /usr/local/bin/steganabara-help
#!/bin/bash
echo "Steganabara - Image Steganography Analyzer"
echo ""
echo "Steganabara analyzes images for hidden data using:"
echo "  - Bit plane viewer"
echo "  - Color channel separation"
echo "  - Color map manipulation"
echo "  - Visual attacks on LSB steganography"
echo ""
echo "Usage: steganabara [image.png]"
echo ""
echo "Supported formats: PNG, BMP, GIF, JPG"
echo ""
echo "Note: Requires Java and X11 display"
echo "      (VNC or X11 forwarding)"
EOF
chmod +x /usr/local/bin/steganabara-help

echo "=== Steganabara installed ==="

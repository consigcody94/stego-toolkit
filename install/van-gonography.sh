#!/bin/bash
# =============================================================================
# van-gonography - Hide any file type inside images (444+ stars)
# Simple Python tool for file-in-image steganography
# https://github.com/JoshuaKasa/van-gonography
# =============================================================================
set -euo pipefail

echo "=== Installing van-gonography ==="

# Install via pip
pip3 install --break-system-packages --no-cache-dir van-gonography || {
    echo "pip install failed, trying from source..."

    git clone --depth 1 https://github.com/JoshuaKasa/van-gonography.git /tmp/van-gonography
    cd /tmp/van-gonography
    pip3 install --break-system-packages --no-cache-dir .
    rm -rf /tmp/van-gonography
}

# Create wrapper if not in path
if ! command -v van-gonography &> /dev/null; then
    # Try to find the installed script
    VANGO_PATH=$(find /usr -name "van-gonography" -type f 2>/dev/null | head -1)
    if [[ -n "$VANGO_PATH" ]]; then
        ln -sf "$VANGO_PATH" /usr/local/bin/van-gonography
    fi
fi

# Create help wrapper
cat << 'EOF' > /usr/local/bin/van-gonography-help
#!/bin/bash
echo "van-gonography - Hide Files Inside Images"
echo ""
echo "Simple tool to hide any file type inside PNG images."
echo "Named after Van Gogh - hiding art within art!"
echo ""
echo "Usage:"
echo "  Hide a file:"
echo "    van-gonography hide -c cover.png -f secret.zip -o stego.png"
echo ""
echo "  Extract a file:"
echo "    van-gonography reveal -i stego.png -o extracted.zip"
echo ""
echo "Options:"
echo "  -c, --cover     Cover image (PNG)"
echo "  -f, --file      File to hide"
echo "  -o, --output    Output file"
echo "  -i, --image     Stego image to extract from"
echo ""
echo "Features:"
echo "  - Hide any file type (zip, exe, pdf, etc.)"
echo "  - Uses LSB steganography"
echo "  - Simple CLI interface"
echo ""
echo "GitHub: https://github.com/JoshuaKasa/van-gonography"
EOF
chmod +x /usr/local/bin/van-gonography-help

echo "=== van-gonography installed ==="

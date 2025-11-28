#!/bin/bash
# =============================================================================
# stegpy - Simple Python steganography tool
# Updated for 2025 - with proper pip flags
# =============================================================================
set -euo pipefail

echo "=== Installing stegpy ==="

pip3 install --break-system-packages --no-cache-dir stegpy

# Create help wrapper
cat << 'EOF' > /usr/local/bin/stegpy-help
#!/bin/bash
echo "stegpy - Simple Python Steganography"
echo ""
echo "Usage:"
echo "  Hide data:    stegpy secret.txt cover.png"
echo "  Extract data: stegpy stego.png"
echo ""
echo "Supported formats: PNG, BMP, GIF, WebP"
echo ""
echo "Options:"
echo "  -p PASSWORD   Use password encryption"
echo ""
echo "Examples:"
echo "  stegpy 'secret message' image.png"
echo "  stegpy -p mypassword secret.txt image.png"
echo "  stegpy stego.png -p mypassword"
EOF
chmod +x /usr/local/bin/stegpy-help

echo "=== stegpy installed ==="
stegpy --help 2>/dev/null | head -5 || echo "stegpy installed"

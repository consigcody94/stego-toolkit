#!/bin/bash
# =============================================================================
# F5 Steganography - JPEG steganography using F5 algorithm
# Updated for 2025 - Python 3 compatible
# =============================================================================
set -euo pipefail

echo "=== Installing F5 Steganography ==="

mkdir -p /opt/f5

# Clone the Python implementation
git clone --depth 1 https://github.com/jackfengji/f5-steganography.git /opt/f5/python

# Install Python dependencies
pip3 install --break-system-packages --no-cache-dir \
    pillow \
    numpy || true

# Create wrapper script with Python 3 compatibility
cat << 'EOF' > /usr/local/bin/f5
#!/bin/bash
# F5 Steganography wrapper
# Usage:
#   f5 -t e -i cover.jpg -o stego.jpg -d 'secret message'  # embed
#   f5 -t x -i stego.jpg                                    # extract
set -euo pipefail

cd /opt/f5/python
python3 utity.py "$@"
EOF
chmod +x /usr/local/bin/f5

# Create help command
cat << 'EOF' > /usr/local/bin/f5-help
#!/bin/bash
echo "F5 Steganography - JPEG steganography using F5 algorithm"
echo ""
echo "Usage:"
echo "  Embed: f5 -t e -i cover.jpg -o stego.jpg -d 'secret message'"
echo "  Extract: f5 -t x -i stego.jpg"
echo ""
echo "Options:"
echo "  -t e    Embed mode"
echo "  -t x    Extract mode"
echo "  -i      Input file"
echo "  -o      Output file (embed mode)"
echo "  -d      Data to embed"
EOF
chmod +x /usr/local/bin/f5-help

echo "=== F5 Steganography installed ==="

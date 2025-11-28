#!/bin/bash
# =============================================================================
# cloaked-pixel - LSB steganography with encryption
# Updated for 2025 - Python 3 compatible
# =============================================================================
set -euo pipefail

echo "=== Installing cloaked-pixel ==="

# Clone the repository
git clone --depth 1 https://github.com/livz/cloacked-pixel.git /opt/cloaked_pixel

# Install Python dependencies
pip3 install --break-system-packages --no-cache-dir \
    numpy \
    matplotlib \
    pillow \
    pycryptodome || true

# Create wrapper script for Python 3
cat << 'EOF' > /usr/local/bin/cloackedpixel
#!/bin/bash
# cloaked-pixel wrapper - LSB steganography with AES encryption
set -euo pipefail

cd /opt/cloaked_pixel
python3 lsb.py "$@"
EOF
chmod +x /usr/local/bin/cloackedpixel

# Create analyse wrapper
cat << 'EOF' > /usr/local/bin/cloackedpixel-analyse
#!/bin/bash
# cloaked-pixel analysis wrapper
set -euo pipefail

cd /opt/cloaked_pixel
python3 lsb.py analyse "$@"
EOF
chmod +x /usr/local/bin/cloackedpixel-analyse

# Create help wrapper
cat << 'EOF' > /usr/local/bin/cloackedpixel-help
#!/bin/bash
echo "cloaked-pixel - LSB Steganography with AES Encryption"
echo ""
echo "Hide data:"
echo "  cloackedpixel hide cover.png secret.txt password"
echo ""
echo "Extract data:"
echo "  cloackedpixel extract stego.png output.txt password"
echo ""
echo "Analyse image for hidden data:"
echo "  cloackedpixel-analyse image.png"
echo ""
echo "This tool hides data using LSB steganography and"
echo "encrypts it with AES before embedding."
EOF
chmod +x /usr/local/bin/cloackedpixel-help

echo "=== cloaked-pixel installed ==="

#!/bin/bash
# =============================================================================
# jphide/jpseek - JPEG steganography tools
# Updated for 2025 - with error handling and verification
# =============================================================================
set -euo pipefail

echo "=== Installing jphide/jpseek ==="

# URLs for the binaries
JPHIDE_URL="https://github.com/mmayfield1/SSAK/raw/master/programs/64/jphide"
JPSEEK_URL="https://github.com/mmayfield1/SSAK/raw/master/programs/64/jpseek"

# Download jphide
echo "Downloading jphide..."
if wget -q -O /usr/local/bin/jphide "$JPHIDE_URL"; then
    chmod +x /usr/local/bin/jphide
    echo "jphide installed successfully"
else
    echo "Warning: Failed to download jphide"
fi

# Download jpseek
echo "Downloading jpseek..."
if wget -q -O /usr/local/bin/jpseek "$JPSEEK_URL"; then
    chmod +x /usr/local/bin/jpseek
    echo "jpseek installed successfully"
else
    echo "Warning: Failed to download jpseek"
fi

# Create help wrapper
cat << 'EOF' > /usr/local/bin/jphide-help
#!/bin/bash
echo "jphide/jpseek - JPEG Steganography Tools"
echo ""
echo "jphide - Hide data in JPEG images:"
echo "  Usage: jphide cover.jpg stego.jpg secret.txt"
echo "  You will be prompted for a passphrase"
echo ""
echo "jpseek - Extract hidden data from JPEG images:"
echo "  Usage: jpseek stego.jpg output.txt"
echo "  You will be prompted for the passphrase"
echo ""
echo "Note: These tools use the JPHIDE algorithm which is"
echo "      different from other JPEG stego tools"
EOF
chmod +x /usr/local/bin/jphide-help

echo "=== jphide/jpseek installed ==="

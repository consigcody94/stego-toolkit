#!/bin/bash
# =============================================================================
# outguess-0.13 - Older version of Outguess steganography tool
# Updated for 2025 - with error handling
# =============================================================================
set -euo pipefail

echo "=== Installing outguess-0.13 ==="

# URL for the binary
OUTGUESS_URL="https://github.com/mmayfield1/SSAK/raw/master/programs/64/outguess_0.13"

# Download outguess-0.13
echo "Downloading outguess-0.13..."
if wget -q -O /usr/local/bin/outguess-0.13 "$OUTGUESS_URL"; then
    chmod +x /usr/local/bin/outguess-0.13
    echo "outguess-0.13 installed successfully"
else
    echo "Warning: Failed to download outguess-0.13"
    echo "The newer outguess (from apt) is still available"
fi

# Create help wrapper
cat << 'EOF' > /usr/local/bin/outguess-0.13-help
#!/bin/bash
echo "outguess-0.13 - Older version of Outguess"
echo ""
echo "Note: This is the older 0.13 version of Outguess."
echo "The newer version (outguess) is also installed."
echo ""
echo "Usage:"
echo "  Hide data:"
echo "    outguess-0.13 -k password -d secret.txt cover.jpg stego.jpg"
echo ""
echo "  Extract data:"
echo "    outguess-0.13 -r -k password stego.jpg output.txt"
echo ""
echo "This older version may be needed for some CTF challenges"
echo "that specifically use outguess 0.13 format."
EOF
chmod +x /usr/local/bin/outguess-0.13-help

echo "=== outguess-0.13 installed ==="

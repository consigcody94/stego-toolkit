#!/bin/bash
# =============================================================================
# steg - Simple steganography tool by Fabio Nett
# Updated for 2025 - modern handling
# =============================================================================
set -euo pipefail

echo "=== Installing steg ==="

# Note: Original tool was hosted on Google Drive and is no longer easily accessible
# This script creates a placeholder or downloads from alternative source

STEG_FILE="/tmp/install/files/steg"

if [[ -f "$STEG_FILE" ]]; then
    # Original installation method if file exists
    cp "$STEG_FILE" /usr/local/bin/steg
    chmod +x /usr/local/bin/steg
    echo "steg installed from bundled file"
else
    # Create info script since original is unavailable
    cat << 'EOF' > /usr/local/bin/steg
#!/bin/bash
echo "steg - Simple Steganography Tool"
echo ""
echo "The original 'steg' tool by Fabio Nett is no longer easily available."
echo "It was a simple GUI tool for basic image steganography."
echo ""
echo "Recommended alternatives:"
echo "  - stegano-lsb (Python, CLI): stegano-lsb hide --input cover.png -f secret.txt -o stego.png"
echo "  - steghide (CLI): steghide embed -cf cover.jpg -ef secret.txt"
echo "  - openstego (Java GUI): openstego"
echo "  - stegsolve (Java GUI): stegsolve"
echo ""
echo "For LSB steganography analysis, use:"
echo "  - zsteg stego.png"
echo "  - stegoveritas stego.png"
EOF
    chmod +x /usr/local/bin/steg
    echo "steg placeholder installed (original tool unavailable)"
fi

# Create help
cat << 'EOF' > /usr/local/bin/steg-help
#!/bin/bash
echo "steg - Simple Steganography Tool (Original by Fabio Nett)"
echo ""
echo "Note: The original tool may not be available."
echo "See 'steg' for alternative tools."
echo ""
echo "Original functionality:"
echo "  - Hide text in images"
echo "  - Extract hidden text from images"
echo "  - Basic LSB steganography"
EOF
chmod +x /usr/local/bin/steg-help

echo "=== steg installation complete ==="

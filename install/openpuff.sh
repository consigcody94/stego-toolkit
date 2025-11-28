#!/bin/bash
# =============================================================================
# OpenPuff - Multi-format steganography tool (Windows, requires Wine)
# Updated for 2025 - modern handling and fallbacks
# =============================================================================
set -euo pipefail

echo "=== Installing OpenPuff ==="

# Check for Wine
if ! command -v wine &> /dev/null; then
    echo "Warning: Wine is required for OpenPuff"
    echo "Run wine.sh first to install Wine"
fi

# Download OpenPuff
OPENPUFF_URL="http://embeddedsw.net/zip/OpenPuff_release.zip"
echo "Downloading OpenPuff..."
if wget -q -O /tmp/openpuff.zip "$OPENPUFF_URL" 2>/dev/null; then
    mkdir -p /opt/openpuff
    unzip -q -o /tmp/openpuff.zip -d /opt/openpuff
    rm /tmp/openpuff.zip
    echo "OpenPuff downloaded and extracted"
else
    echo "Warning: Could not download OpenPuff"
    echo "You may need to download it manually from: http://embeddedsw.net/OpenPuff_Steganography_Home.html"
fi

# Create wrapper script
cat << 'EOF' > /usr/local/bin/openpuff
#!/bin/bash
# OpenPuff - Professional steganography tool
# Requires Wine and X11 display
set -euo pipefail

OPENPUFF_EXE="/opt/openpuff/OpenPuff_release/OpenPuff.exe"

if ! command -v wine &> /dev/null; then
    echo "Error: Wine is required for OpenPuff"
    exit 1
fi

if [[ -f "$OPENPUFF_EXE" ]]; then
    echo "Starting OpenPuff..."
    wine "$OPENPUFF_EXE" "$@"
else
    echo "Error: OpenPuff not found at $OPENPUFF_EXE"
    echo "Please reinstall from: http://embeddedsw.net/OpenPuff_Steganography_Home.html"
    exit 1
fi
EOF
chmod +x /usr/local/bin/openpuff

# Create help
cat << 'EOF' > /usr/local/bin/openpuff-help
#!/bin/bash
echo "OpenPuff - Professional Steganography Tool"
echo ""
echo "OpenPuff can hide data in many file formats:"
echo "  - Images: BMP, JPG, PNG, TGA"
echo "  - Audio: AIFF, MP3, WAV"
echo "  - Video: 3GP, FLV, MP4, SWF, VOB"
echo "  - Flash: SWF, FLV"
echo "  - PDF files"
echo ""
echo "Features:"
echo "  - Multi-carrier support (split data across files)"
echo "  - Three levels of password protection"
echo "  - Deniable steganography (decoy data)"
echo ""
echo "Usage: openpuff"
echo ""
echo "Note: This is a Windows application that runs via Wine"
echo "      Requires X11 display (VNC or X11 forwarding)"
EOF
chmod +x /usr/local/bin/openpuff-help

echo "=== OpenPuff installed ==="

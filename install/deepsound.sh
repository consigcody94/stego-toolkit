#!/bin/bash
# =============================================================================
# DeepSound - Audio steganography tool (Windows, requires Wine)
# Updated for 2025 - modern download handling
# =============================================================================
set -euo pipefail

echo "=== Installing DeepSound ==="

# Check for Wine
if ! command -v wine &> /dev/null; then
    echo "Warning: Wine is required for DeepSound"
    echo "Run wine.sh first to install Wine"
fi

# Download DeepSound installer
DEEPSOUND_URL="http://jpinsoft.net/DeepSound/Download.aspx?Download=LastVersion"
echo "Downloading DeepSound..."
if wget -q -O /tmp/deepsound.msi "$DEEPSOUND_URL" 2>/dev/null; then
    echo "DeepSound installer downloaded"
else
    echo "Warning: Could not download DeepSound"
    echo "You may need to download it manually from: http://jpinsoft.net/DeepSound/"
fi

# Create wrapper script
cat << 'EOF' > /usr/local/bin/deepsound
#!/bin/bash
# DeepSound - Audio steganography tool
# Requires Wine and X11 display
set -euo pipefail

DEEPSOUND_EXECUTABLE="/root/.wine/drive_c/Program Files/DeepSound 2.0/DeepSound.exe"

if ! command -v wine &> /dev/null; then
    echo "Error: Wine is required for DeepSound"
    exit 1
fi

if [[ -f "$DEEPSOUND_EXECUTABLE" ]]; then
    echo "Starting DeepSound..."
    echo "Note: MP3 may require additional codecs"
    wine explorer /desktop=deepsound,1024x768 "$DEEPSOUND_EXECUTABLE" "$@"
else
    echo "DeepSound not installed yet!"
    if [[ -f /tmp/deepsound.msi ]]; then
        echo "Installing DeepSound to default location..."
        wine msiexec /i /tmp/deepsound.msi
    else
        echo "Please download DeepSound from: http://jpinsoft.net/DeepSound/"
    fi
fi
EOF
chmod +x /usr/local/bin/deepsound

# Create help
cat << 'EOF' > /usr/local/bin/deepsound-help
#!/bin/bash
echo "DeepSound - Audio Steganography Tool"
echo ""
echo "DeepSound can hide data in audio files (WAV, FLAC, APE, WMA)"
echo ""
echo "Usage: deepsound"
echo ""
echo "Features:"
echo "  - Hide files inside audio files"
echo "  - AES-256 encryption"
echo "  - Calculate audio integrity checksum"
echo ""
echo "Note: This is a Windows application that runs via Wine"
echo "      Requires X11 display (VNC or X11 forwarding)"
EOF
chmod +x /usr/local/bin/deepsound-help

echo "=== DeepSound installed ==="

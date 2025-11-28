#!/bin/bash
# =============================================================================
# MP3Stego - Hide data in MP3 files
# Updated for 2025 - Windows tool via Wine
# =============================================================================
set -euo pipefail

echo "=== Installing MP3Stego ==="

# Check if Wine is available
if ! command -v wine &> /dev/null; then
    echo "Warning: Wine not installed. MP3Stego requires Wine."
    echo "Install wine with: apt-get install wine"
fi

# Download MP3Stego
MP3STEGO_URL="http://www.petitcolas.net/fabien/software/MP3Stego_1_1_18.zip"
wget -q -O /tmp/mp3stego.zip "$MP3STEGO_URL" || {
    echo "Warning: Could not download MP3Stego from primary URL"
    # Try alternate mirror if available
    exit 0
}

# Extract
mkdir -p /opt/mp3stego
unzip -q /tmp/mp3stego.zip -d /opt/mp3stego
rm /tmp/mp3stego.zip

# Create decode wrapper
cat << 'EOF' > /usr/local/bin/mp3stego-decode
#!/bin/bash
# MP3Stego decode wrapper
# Usage: mp3stego-decode [-X] [-P password] input.mp3 output.txt
set -euo pipefail

if ! command -v wine &> /dev/null; then
    echo "Error: Wine is required for MP3Stego"
    exit 1
fi

MP3STEGO_DIR="/opt/mp3stego/MP3Stego_1_1_18/MP3Stego"

# Convert relative paths to absolute
args=()
for arg in "$@"; do
    if [[ -f "$arg" ]]; then
        args+=("$(realpath "$arg")")
    else
        args+=("$arg")
    fi
done

cd "$MP3STEGO_DIR"
wine Decode.exe "${args[@]}"
EOF
chmod +x /usr/local/bin/mp3stego-decode

# Create encode wrapper
cat << 'EOF' > /usr/local/bin/mp3stego-encode
#!/bin/bash
# MP3Stego encode wrapper
# Usage: mp3stego-encode [-E data.txt] [-P password] input.wav output.mp3
set -euo pipefail

if ! command -v wine &> /dev/null; then
    echo "Error: Wine is required for MP3Stego"
    exit 1
fi

MP3STEGO_DIR="/opt/mp3stego/MP3Stego_1_1_18/MP3Stego"

# Convert relative paths to absolute
args=()
for arg in "$@"; do
    if [[ -f "$arg" ]]; then
        args+=("$(realpath "$arg")")
    else
        args+=("$arg")
    fi
done

cd "$MP3STEGO_DIR"
wine Encode.exe "${args[@]}"
EOF
chmod +x /usr/local/bin/mp3stego-encode

# Create help
cat << 'EOF' > /usr/local/bin/mp3stego-help
#!/bin/bash
echo "MP3Stego - Hide information in MP3 files"
echo ""
echo "Encode (hide data):"
echo "  mp3stego-encode -E secret.txt -P password input.wav output.mp3"
echo ""
echo "Decode (extract data):"
echo "  mp3stego-decode -X -P password input.mp3 output.txt"
echo ""
echo "Options:"
echo "  -E file    File containing data to hide"
echo "  -X         Extract hidden data"
echo "  -P pass    Password for encryption"
echo ""
echo "Note: Requires Wine to run Windows executables"
EOF
chmod +x /usr/local/bin/mp3stego-help

echo "=== MP3Stego installed ==="

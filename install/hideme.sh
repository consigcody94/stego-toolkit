#!/bin/bash
# =============================================================================
# hideme (AudioStego) - Hide data in audio files
# Updated for 2025 - modern build process
# =============================================================================
set -euo pipefail

echo "=== Installing hideme (AudioStego) ==="

# Install dependencies
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
    cmake \
    libboost-all-dev \
    build-essential

# Clone and build
git clone --depth 1 https://github.com/danielcardeenas/AudioStego.git /tmp/audio_stego

mkdir -p /tmp/audio_stego/build
cd /tmp/audio_stego/build

cmake .. -DCMAKE_BUILD_TYPE=Release
make -j"$(nproc)"

# Install
mv /tmp/audio_stego/build/hideme /usr/local/bin/hideme
chmod +x /usr/local/bin/hideme

# Create help wrapper
cat << 'EOF' > /usr/local/bin/hideme-help
#!/bin/bash
echo "hideme (AudioStego) - Hide data in WAV audio files"
echo ""
echo "Usage:"
echo "  Hide data:    hideme -i cover.wav -o stego.wav -f secret.txt"
echo "  Extract data: hideme -i stego.wav -o output.txt"
echo ""
echo "This tool uses LSB steganography in WAV audio files."
EOF
chmod +x /usr/local/bin/hideme-help

# Clean up
rm -rf /tmp/audio_stego

echo "=== hideme installed ==="
hideme --help 2>/dev/null || echo "hideme installed (run hideme --help for usage)"

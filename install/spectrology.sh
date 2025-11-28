#!/bin/bash
# =============================================================================
# Spectrology - Hide images in audio spectrograms
# Updated for 2025 - Python 3 compatible
# =============================================================================
set -euo pipefail

echo "=== Installing Spectrology ==="

# Clone the repository
git clone --depth 1 https://github.com/solusipse/spectrology.git /opt/spectrology

# Install Python dependencies
pip3 install --break-system-packages --no-cache-dir \
    pillow \
    numpy \
    scipy || true

# Create wrapper script that handles Python 3
cat << 'EOF' > /usr/local/bin/spectrology
#!/bin/bash
# Spectrology wrapper - convert images to audio spectrograms
set -euo pipefail

cd /opt/spectrology
python3 spectrology.py "$@"
EOF
chmod +x /usr/local/bin/spectrology

# Create help wrapper
cat << 'EOF' > /usr/local/bin/spectrology-help
#!/bin/bash
echo "Spectrology - Hide images in audio spectrograms"
echo ""
echo "Usage:"
echo "  spectrology [options] input_image"
echo ""
echo "Options:"
echo "  -o, --output FILE   Output WAV file (default: out.wav)"
echo "  -b, --bottom FREQ   Bottom frequency in Hz (default: 200)"
echo "  -t, --top FREQ      Top frequency in Hz (default: 20000)"
echo "  -p, --pixels N      Pixels per second (default: 30)"
echo "  -s, --sampling N    Sampling rate (default: 44100)"
echo ""
echo "Example:"
echo "  spectrology -o hidden.wav secret_image.png"
echo ""
echo "To reveal the hidden image, open the WAV file in"
echo "Sonic Visualiser or Audacity and view the spectrogram."
EOF
chmod +x /usr/local/bin/spectrology-help

echo "=== Spectrology installed ==="

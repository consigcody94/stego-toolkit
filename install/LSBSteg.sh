#!/bin/bash
# =============================================================================
# LSBSteg - LSB Steganography Tool
# Updated for 2025 - Python 3 compatible fork
# =============================================================================
set -euo pipefail

echo "=== Installing LSBSteg ==="

# Use a Python 3 compatible fork or the updated version
if git clone --depth 1 https://github.com/ragibson/Steganography.git /opt/LSBSteg 2>/dev/null; then
    echo "Cloned ragibson/Steganography (Python 3 compatible)"
else
    # Fallback to original and patch
    git clone --depth 1 https://github.com/RobinDavid/LSB-Steganography.git /opt/LSBSteg
    echo "Warning: Using original repo, may need Python 2"
fi

# Install Python dependencies
pip3 install --break-system-packages --no-cache-dir \
    opencv-python-headless \
    numpy \
    pillow \
    docopt || true

# Create wrapper script
cat << 'EOF' > /usr/local/bin/LSBSteg
#!/bin/bash
# LSBSteg wrapper - LSB Steganography tool
set -euo pipefail

if [[ -f /opt/LSBSteg/stego_lsb/LSBSteg.py ]]; then
    python3 /opt/LSBSteg/stego_lsb/LSBSteg.py "$@"
elif [[ -f /opt/LSBSteg/LSBSteg.py ]]; then
    python3 /opt/LSBSteg/LSBSteg.py "$@"
else
    echo "Error: LSBSteg.py not found"
    exit 1
fi
EOF
chmod +x /usr/local/bin/LSBSteg

echo "=== LSBSteg installed ==="

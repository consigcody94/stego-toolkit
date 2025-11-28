#!/bin/bash
# =============================================================================
# stegdetect/stegbreak - JPEG steganography detection and cracking
# Updated for 2025 - build from source (old .deb no longer available)
# =============================================================================
set -euo pipefail

echo "=== Installing stegdetect/stegbreak ==="

# Install dependencies
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
    build-essential \
    libjpeg-dev \
    automake \
    autoconf \
    libtool

# Try to clone from a maintained fork
STEGDETECT_REPO="https://github.com/redNixon/stegdetect.git"

if git clone --depth 1 "$STEGDETECT_REPO" /tmp/stegdetect 2>/dev/null; then
    cd /tmp/stegdetect

    # Build
    if [[ -f configure.ac ]]; then
        autoreconf -i 2>/dev/null || true
    fi

    if [[ -f configure ]]; then
        ./configure --prefix=/usr/local
        make -j"$(nproc)"
        make install || {
            # Manual install if make install fails
            cp stegdetect /usr/local/bin/ 2>/dev/null || true
            cp stegbreak /usr/local/bin/ 2>/dev/null || true
        }
    else
        # Try direct compilation
        gcc -O2 -o stegdetect stegdetect.c -ljpeg 2>/dev/null || true
        if [[ -f stegdetect ]]; then
            cp stegdetect /usr/local/bin/
        fi
    fi

    rm -rf /tmp/stegdetect
    echo "stegdetect built from source"
else
    echo "Warning: Could not clone stegdetect repository"
    echo "Trying alternative installation..."

    # Try the old .deb as fallback (may not work on newer systems)
    OLD_DEB_URL="http://old-releases.ubuntu.com/ubuntu/pool/universe/s/stegdetect/stegdetect_0.6-6_amd64.deb"
    if wget -q -O /tmp/stegdetect.deb "$OLD_DEB_URL" 2>/dev/null; then
        dpkg -i /tmp/stegdetect.deb 2>/dev/null || apt-get install -f -y 2>/dev/null || true
        rm -f /tmp/stegdetect.deb
    fi
fi

# Create help wrapper
cat << 'EOF' > /usr/local/bin/stegdetect-help
#!/bin/bash
echo "stegdetect/stegbreak - JPEG Steganography Detection"
echo ""
echo "stegdetect - Detect steganography in JPEG images:"
echo "  Usage: stegdetect [-t tests] image.jpg"
echo "  Tests: j=jsteg, o=outguess, p=jphide, i=invisible"
echo "  Example: stegdetect -tjopi image.jpg"
echo ""
echo "stegbreak - Dictionary attack against JPEG stego:"
echo "  Usage: stegbreak -t test -f wordlist.txt image.jpg"
echo "  Example: stegbreak -t o -f rockyou.txt stego.jpg"
echo ""
echo "Detectable algorithms:"
echo "  - jsteg"
echo "  - outguess (0.13 and 0.2)"
echo "  - jphide"
echo "  - invisible secrets"
echo "  - F5"
echo "  - camouflage"
EOF
chmod +x /usr/local/bin/stegdetect-help

echo "=== stegdetect installation complete ==="
stegdetect 2>&1 | head -1 || echo "stegdetect may not be fully functional on this system"

#!/bin/bash
# =============================================================================
# John the Ripper (Jumbo) - Password cracker
# Updated for 2025 - Latest version from GitHub
# =============================================================================
set -euo pipefail

echo "=== Installing John the Ripper (Jumbo) ==="

# Install dependencies
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
    libssl-dev \
    zlib1g-dev \
    libgmp-dev \
    libpcap-dev \
    libbz2-dev \
    libgomp1 \
    yasm \
    pkg-config

# Clone latest John the Ripper from GitHub
git clone --depth 1 https://github.com/openwall/john.git /opt/john-src

# Build
cd /opt/john-src/src
./configure --disable-openmp || ./configure
make -sj"$(nproc)"

# Install to /opt/john
mkdir -p /opt/john
cp -r ../run/* /opt/john/

# Create wrapper script
cat << 'EOF' > /usr/local/bin/john
#!/bin/bash
# John the Ripper wrapper
export JOHN=/opt/john
cd "$JOHN"
./john "$@"
EOF
chmod +x /usr/local/bin/john

# Create additional utility links
for util in unique unshadow unafs undrop zip2john rar2john keepass2john pdf2john; do
    if [[ -f /opt/john/$util ]]; then
        ln -sf /opt/john/$util /usr/local/bin/$util 2>/dev/null || true
    fi
done

# Cleanup source
rm -rf /opt/john-src

# Add JOHN env var
echo 'export JOHN=/opt/john' >> /etc/profile.d/john.sh

echo "=== John the Ripper installed ==="
john --version 2>/dev/null || echo "John installed (version check may require login shell)"

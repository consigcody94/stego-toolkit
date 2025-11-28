#!/bin/bash
# =============================================================================
# Install OpenStego - Open source steganography solution
# https://github.com/syvaidya/openstego
# =============================================================================
set -e

echo "Installing OpenStego..."

OPENSTEGO_VERSION="0.8.6"
OPENSTEGO_URL="https://github.com/syvaidya/openstego/releases/download/openstego-${OPENSTEGO_VERSION}/openstego_${OPENSTEGO_VERSION}-1_all.deb"

cd /tmp
wget -q "${OPENSTEGO_URL}" -O openstego.deb

# Install dependencies and package
apt-get update -qq
dpkg -i openstego.deb || apt-get install -f -y -qq
rm -f openstego.deb

# Create wrapper script
cat << 'EOF' > /usr/local/bin/openstego
#!/bin/bash
java -jar /usr/share/openstego/lib/openstego.jar "$@"
EOF
chmod +x /usr/local/bin/openstego

# Verify installation
if [ -f /usr/share/openstego/lib/openstego.jar ]; then
    echo "OpenStego installed successfully (version ${OPENSTEGO_VERSION})"
else
    echo "Warning: OpenStego installation may have failed"
fi

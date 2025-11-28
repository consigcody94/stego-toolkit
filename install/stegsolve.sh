#!/bin/bash
# =============================================================================
# Install Stegsolve - Image analysis tool for steganography
# http://www.caesum.com/handbook/stego.htm
# =============================================================================
set -e

echo "Installing Stegsolve..."

# Create installation directory
mkdir -p /opt/stegsolve

# Download Stegsolve JAR
# Note: The original source may be unavailable, using mirror
STEGSOLVE_URL="http://www.caesum.com/handbook/Stegsolve.jar"
MIRROR_URL="https://github.com/Giotino/stegsolve/releases/download/v1.4/StegSolve-1.4.jar"

if wget -q --spider "${STEGSOLVE_URL}" 2>/dev/null; then
    wget -q -O /opt/stegsolve/Stegsolve.jar "${STEGSOLVE_URL}"
else
    echo "Original source unavailable, trying mirror..."
    wget -q -O /opt/stegsolve/Stegsolve.jar "${MIRROR_URL}"
fi

# Create wrapper script
cat << 'EOF' > /usr/local/bin/stegsolve
#!/bin/bash
java -jar /opt/stegsolve/Stegsolve.jar "$@"
EOF
chmod +x /usr/local/bin/stegsolve

# Verify installation
if [ -f /opt/stegsolve/Stegsolve.jar ]; then
    echo "Stegsolve installed successfully"
else
    echo "Warning: Stegsolve installation may have failed"
fi

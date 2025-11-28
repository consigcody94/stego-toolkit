#!/bin/bash
# =============================================================================
# StegCloak - Hide secrets in plain text using invisible characters (3737+ stars)
# Uses zero-width characters for text-based steganography
# https://github.com/KuroLabs/stegcloak
# =============================================================================
set -euo pipefail

echo "=== Installing StegCloak ==="

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    apt-get update -qq
    apt-get install -y -qq nodejs npm
fi

# Install StegCloak globally
echo "Installing StegCloak via npm..."
npm install -g stegcloak || {
    echo "Warning: npm global install failed, trying with --unsafe-perm"
    npm install -g stegcloak --unsafe-perm || true
}

# Verify installation
if command -v stegcloak &> /dev/null; then
    echo "StegCloak installed successfully"
else
    echo "Warning: StegCloak CLI not in PATH, creating wrapper..."
    # Find where npm installed it
    NPM_PREFIX=$(npm config get prefix)
    if [[ -f "$NPM_PREFIX/bin/stegcloak" ]]; then
        ln -sf "$NPM_PREFIX/bin/stegcloak" /usr/local/bin/stegcloak
    fi
fi

# Create help wrapper
cat << 'EOF' > /usr/local/bin/stegcloak-help
#!/bin/bash
echo "StegCloak - Hide Secrets in Plain Text"
echo ""
echo "Uses invisible zero-width characters to hide encrypted messages"
echo "inside normal-looking text. The output looks like regular text!"
echo ""
echo "Usage:"
echo "  Hide a message:"
echo "    stegcloak hide"
echo "    (Interactive: enter secret, password, and cover text)"
echo ""
echo "  Reveal a message:"
echo "    stegcloak reveal"
echo "    (Interactive: enter stego text and password)"
echo ""
echo "  Non-interactive:"
echo "    stegcloak hide -s 'secret message' -p password -c 'cover text'"
echo "    stegcloak reveal -p password 'stego text with hidden message'"
echo ""
echo "Options:"
echo "  -s, --secret    The secret message to hide"
echo "  -p, --password  Password for encryption"
echo "  -c, --cover     The cover text (visible text)"
echo "  -n, --no-crypt  Disable encryption (not recommended)"
echo "  -i, --integrity Enable HMAC integrity check"
echo ""
echo "Example:"
echo "  Input:  'Hello World' (cover) + 'secret123' (hidden)"
echo "  Output: 'Hello World' (looks the same, but contains hidden data!)"
echo ""
echo "The hidden message is embedded using invisible Unicode characters."
echo "Perfect for social media, emails, or any text-based communication."
echo ""
echo "GitHub: https://github.com/KuroLabs/stegcloak"
EOF
chmod +x /usr/local/bin/stegcloak-help

echo "=== StegCloak installed ==="

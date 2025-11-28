#!/bin/bash
# =============================================================================
# Wine - Windows compatibility layer for running Windows stego tools
# Updated for 2025 - Debian Bookworm compatible
# =============================================================================
set -euo pipefail

echo "=== Installing Wine ==="

# Enable i386 architecture (required for 32-bit Windows apps)
dpkg --add-architecture i386
apt-get update -qq

# Install Wine from Debian repos
apt-get install -y --no-install-recommends \
    wine \
    wine32 \
    wine64 \
    libwine \
    fonts-wine \
    xvfb \
    winbind || {
    # Fallback to just wine64 if 32-bit fails
    apt-get install -y --no-install-recommends \
        wine \
        wine64 \
        xvfb || true
}

# Initialize Wine prefix (suppress GUI prompts)
echo "Initializing Wine prefix..."
export DISPLAY=:99
Xvfb :99 -screen 0 1024x768x16 &
XVFB_PID=$!
sleep 2

# Try to initialize wine prefix
WINEPREFIX=/root/.wine wineboot --init 2>/dev/null || true

# Kill Xvfb
kill $XVFB_PID 2>/dev/null || true

# Install winetricks
echo "Installing winetricks..."
WINETRICKS_URL="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
if wget -q -O /usr/local/bin/winetricks "$WINETRICKS_URL"; then
    chmod +x /usr/local/bin/winetricks
    echo "winetricks installed"
else
    echo "Warning: Could not install winetricks"
fi

# Create wine wrapper for common use
cat << 'EOF' > /usr/local/bin/wine-run
#!/bin/bash
# Wine wrapper with virtual display support
# Usage: wine-run program.exe [args]

if [[ -z "$DISPLAY" ]]; then
    # No display, use Xvfb
    export DISPLAY=:99
    Xvfb :99 -screen 0 1024x768x16 &
    XVFB_PID=$!
    sleep 1
    wine "$@"
    EXIT_CODE=$?
    kill $XVFB_PID 2>/dev/null
    exit $EXIT_CODE
else
    wine "$@"
fi
EOF
chmod +x /usr/local/bin/wine-run

echo "=== Wine installed ==="
wine --version 2>/dev/null || echo "Wine installation complete"

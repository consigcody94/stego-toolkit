#!/bin/bash
# =============================================================================
# VNC Server - Remote desktop access via VNC and noVNC
# Updated for 2025 - Modern TigerVNC and noVNC versions
# =============================================================================
set -euo pipefail

echo "=== Installing VNC Server ==="

# Install Xfce desktop environment
apt-get update -qq
apt-get install -y --no-install-recommends \
    keyboard-configuration \
    xfce4 \
    xfce4-terminal \
    xterm \
    dbus-x11

# Remove unnecessary packages
apt-get purge -y pm-utils xscreensaver* 2>/dev/null || true

# Install TigerVNC
echo "Installing TigerVNC..."
TIGERVNC_VERSION="1.13.1"
TIGERVNC_URL="https://github.com/TigerVNC/tigervnc/releases/download/v${TIGERVNC_VERSION}/tigervnc-${TIGERVNC_VERSION}.x86_64.tar.gz"

if wget -q -O /tmp/tigervnc.tar.gz "$TIGERVNC_URL"; then
    tar xzf /tmp/tigervnc.tar.gz --strip 1 -C /
    rm /tmp/tigervnc.tar.gz
    echo "TigerVNC ${TIGERVNC_VERSION} installed"
else
    # Fallback to apt package
    apt-get install -y tigervnc-standalone-server tigervnc-common || true
fi

# Install noVNC for browser-based access
echo "Installing noVNC..."
NOVNC_VERSION="1.4.0"
WEBSOCKIFY_VERSION="0.11.0"

mkdir -p /opt/novnc/utils/websockify

# Download noVNC
if wget -q -O /tmp/novnc.tar.gz "https://github.com/novnc/noVNC/archive/refs/tags/v${NOVNC_VERSION}.tar.gz"; then
    tar xzf /tmp/novnc.tar.gz --strip 1 -C /opt/novnc
    rm /tmp/novnc.tar.gz
fi

# Download websockify
if wget -q -O /tmp/websockify.tar.gz "https://github.com/novnc/websockify/archive/refs/tags/v${WEBSOCKIFY_VERSION}.tar.gz"; then
    tar xzf /tmp/websockify.tar.gz --strip 1 -C /opt/novnc/utils/websockify
    rm /tmp/websockify.tar.gz
fi

# Set permissions
chmod +x /opt/novnc/utils/*.sh 2>/dev/null || true

# Create index.html to forward to vnc.html
ln -sf /opt/novnc/vnc.html /opt/novnc/index.html 2>/dev/null || \
    ln -sf /opt/novnc/vnc_lite.html /opt/novnc/index.html 2>/dev/null || true

# Create Xfce startup script
cat << 'EOF' > /opt/scripts/xfce_startup.sh
#!/bin/bash
# Xfce startup script for VNC sessions
set -e

echo "Starting Xfce4 window manager..."

# Disable screensaver and power management
xset -dpms &
xset s noblank &
xset s off &

# Start Xfce4
/usr/bin/startxfce4 --replace > "$HOME/wm.log" 2>&1 &
sleep 2

echo "Xfce4 started. Check ~/wm.log for details."
EOF
chmod +x /opt/scripts/xfce_startup.sh

echo "=== VNC Server installed ==="
echo "Use start_vnc.sh to start the VNC server"

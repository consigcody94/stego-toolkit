#!/bin/bash
# =============================================================================
# Start VNC Server - Launch TigerVNC with noVNC web interface
# Updated for 2025 - Modern VNC handling
# =============================================================================
set -euo pipefail

# Configuration
DISPLAY_NUM="${DISPLAY_NUM:-1}"
DISPLAY=":${DISPLAY_NUM}"
VNC_PORT=$((5900 + DISPLAY_NUM))
NO_VNC_PORT="${NO_VNC_PORT:-6901}"
VNC_RESOLUTION="${VNC_RESOLUTION:-1280x1024}"
VNC_COL_DEPTH="${VNC_COL_DEPTH:-24}"

# Get container IP
VNC_IP=$(hostname -i 2>/dev/null || echo "localhost")

# Generate random password
PASSWORD=$(openssl rand -hex 12)

# Setup VNC password
mkdir -p "$HOME/.vnc"
PASSWD_PATH="$HOME/.vnc/passwd"
echo "$PASSWORD" | vncpasswd -f > "$PASSWD_PATH"
chmod 600 "$PASSWD_PATH"

# Clean up old VNC locks
vncserver -kill "$DISPLAY" 2>/dev/null || true
rm -f "/tmp/.X${DISPLAY_NUM}-lock" "/tmp/.X11-unix/X${DISPLAY_NUM}" 2>/dev/null || true

echo "Starting VNC server..."

# Start VNC server
vncserver "$DISPLAY" -depth "$VNC_COL_DEPTH" -geometry "$VNC_RESOLUTION" -localhost no

# Start noVNC web interface
if [[ -f /opt/novnc/utils/novnc_proxy ]]; then
    /opt/novnc/utils/novnc_proxy --vnc "$VNC_IP:$VNC_PORT" --listen "$NO_VNC_PORT" &
elif [[ -f /opt/novnc/utils/launch.sh ]]; then
    /opt/novnc/utils/launch.sh --vnc "$VNC_IP:$VNC_PORT" --listen "$NO_VNC_PORT" &
fi

# Start Xfce desktop if script exists
if [[ -f /opt/scripts/xfce_startup.sh ]]; then
    export DISPLAY="$DISPLAY"
    /opt/scripts/xfce_startup.sh &
fi

# Wait a moment for everything to start
sleep 2

# Display connection info
echo ""
echo "=================================================="
echo "           VNC Server Started Successfully        "
echo "=================================================="
echo ""
echo "VNC Server: $VNC_IP:$VNC_PORT"
echo "  Connect with any VNC viewer to: $VNC_IP:$VNC_PORT"
echo ""
echo "noVNC Web Interface: http://localhost:$NO_VNC_PORT"
echo "  Password: $PASSWORD"
echo ""
echo "  Full URL: http://localhost:$NO_VNC_PORT/?password=$PASSWORD"
echo ""
echo "Display: $DISPLAY"
echo "Resolution: $VNC_RESOLUTION"
echo ""
echo "=================================================="

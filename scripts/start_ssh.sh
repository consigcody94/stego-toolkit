#!/bin/bash
# =============================================================================
# Start SSH Server - Launch OpenSSH with X11 forwarding
# Updated for 2025 - Secure random password
# =============================================================================
set -euo pipefail

# Generate random password
PASSWORD=$(openssl rand -hex 12)

# Determine which user to set password for
if [[ $(id -u) -eq 0 ]]; then
    TARGET_USER="root"
else
    TARGET_USER=$(whoami)
fi

echo "Setting up SSH for user: $TARGET_USER"

# Set password
if [[ "$TARGET_USER" == "root" ]]; then
    echo "root:${PASSWORD}" | chpasswd
else
    # For non-root users, need sudo or root
    if command -v sudo &> /dev/null; then
        echo "${TARGET_USER}:${PASSWORD}" | sudo chpasswd
    else
        echo "Warning: Cannot change password for non-root user without sudo"
    fi
fi

# Ensure SSH directory exists
mkdir -p /var/run/sshd

# Start SSH server
echo "Starting SSH server..."
if command -v service &> /dev/null; then
    service ssh start
elif command -v systemctl &> /dev/null; then
    systemctl start ssh
else
    /usr/sbin/sshd
fi

# Display connection info
echo ""
echo "=================================================="
echo "           SSH Server Started Successfully        "
echo "=================================================="
echo ""
echo "SSH server is now running and ready for X11 forwarding"
echo ""
echo "Connect with:"
echo "  ssh -X ${TARGET_USER}@localhost"
echo ""
echo "Or with auto-accept host key:"
echo "  ssh -X -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${TARGET_USER}@localhost"
echo ""
echo "Password: ${PASSWORD}"
echo ""
echo "For GUI tools (stegsolve, sonic-visualiser, etc.):"
echo "  1. Connect with -X flag for X11 forwarding"
echo "  2. Run the GUI tool from the SSH session"
echo ""
echo "=================================================="

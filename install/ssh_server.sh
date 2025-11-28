#!/bin/bash
# =============================================================================
# SSH Server - OpenSSH server with X11 forwarding support
# Updated for 2025 - Secure defaults
# =============================================================================
set -euo pipefail

echo "=== Installing SSH Server ==="

# Install OpenSSH server
apt-get update -qq
apt-get install -y --no-install-recommends openssh-server

# Create SSH directory structure
mkdir -p /var/run/sshd
mkdir -p /etc/ssh/sshd_config.d

# Configure SSH for X11 forwarding (needed for GUI tools)
cat << 'EOF' > /etc/ssh/sshd_config.d/stego-toolkit.conf
# Stego-Toolkit SSH Configuration
# Enable X11 forwarding for GUI tools
X11Forwarding yes
X11UseLocalhost no
X11DisplayOffset 10

# Allow root login (container use only - disable in production)
PermitRootLogin yes

# Allow password authentication (for ease of use in containers)
PasswordAuthentication yes

# Disable strict modes for container compatibility
StrictModes no
EOF

# Fix PAM configuration
if [[ -f /etc/pam.d/sshd ]]; then
    sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd
fi

# Generate host keys if they don't exist
ssh-keygen -A 2>/dev/null || true

echo "=== SSH Server installed ==="
echo "Use start_ssh.sh to start the SSH server"
echo ""
echo "Connect with: ssh -X stego@localhost"
echo "For X11 forwarding (GUI tools over SSH)"

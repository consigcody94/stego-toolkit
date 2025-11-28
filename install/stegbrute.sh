#!/bin/bash
# =============================================================================
# stegbrute - Fast Rust-based steganography bruteforce tool
# High-performance password cracker for steghide files
# https://github.com/R4yGM/stegbrute
# =============================================================================
set -euo pipefail

echo "=== Installing stegbrute ==="

# Determine architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH_NAME="x86_64" ;;
    aarch64) ARCH_NAME="aarch64" ;;
    *)       ARCH_NAME="x86_64" ;;
esac

# Get latest release
STEGBRUTE_VERSION=$(curl -s https://api.github.com/repos/R4yGM/stegbrute/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' || echo "v0.1.2")

# Try to download pre-built binary
STEGBRUTE_URL="https://github.com/R4yGM/stegbrute/releases/download/${STEGBRUTE_VERSION}/stegbrute-${STEGBRUTE_VERSION}-linux-${ARCH_NAME}"

echo "Attempting to download stegbrute ${STEGBRUTE_VERSION}..."
if wget -q -O /usr/local/bin/stegbrute "$STEGBRUTE_URL" 2>/dev/null; then
    chmod +x /usr/local/bin/stegbrute
    echo "stegbrute installed from pre-built binary"
else
    echo "Pre-built binary not available, building from source..."

    # Install Rust if not present
    if ! command -v cargo &> /dev/null; then
        echo "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    # Clone and build
    git clone --depth 1 https://github.com/R4yGM/stegbrute.git /tmp/stegbrute
    cd /tmp/stegbrute
    cargo build --release
    cp target/release/stegbrute /usr/local/bin/stegbrute
    chmod +x /usr/local/bin/stegbrute
    rm -rf /tmp/stegbrute

    echo "stegbrute built from source"
fi

# Create help wrapper
cat << 'EOF' > /usr/local/bin/stegbrute-help
#!/bin/bash
echo "stegbrute - Fast Steganography Bruteforce Tool (Rust)"
echo ""
echo "High-performance password cracker for steghide-protected files."
echo "Written in Rust for maximum speed."
echo ""
echo "Usage:"
echo "  stegbrute -f stego.jpg -w wordlist.txt"
echo ""
echo "Options:"
echo "  -f, --file      The stego file to crack"
echo "  -w, --wordlist  Path to wordlist file"
echo "  -t, --threads   Number of threads (default: auto)"
echo "  -v, --verbose   Show verbose output"
echo ""
echo "Example:"
echo "  stegbrute -f hidden.jpg -w /usr/share/wordlists/rockyou.txt"
echo ""
echo "Comparison with other tools:"
echo "  - stegseek:   Fastest (C++, uses steghide internals)"
echo "  - stegbrute:  Very fast (Rust, multi-threaded)"
echo "  - stegcracker: Slower (Python)"
echo ""
echo "GitHub: https://github.com/R4yGM/stegbrute"
EOF
chmod +x /usr/local/bin/stegbrute-help

echo "=== stegbrute installed ==="

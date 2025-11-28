# =============================================================================
# Stego-Toolkit: Modern Steganography CTF Toolkit
# 2025 Refresh - Modernized Docker Image
# =============================================================================
FROM debian:bookworm-slim

# Image metadata
LABEL org.opencontainers.image.title="Stego-Toolkit"
LABEL org.opencontainers.image.description="Dockerized collection of steganography tools for CTF challenges"
LABEL org.opencontainers.image.version="2.0.0"
LABEL org.opencontainers.image.authors="DominicBreuker (original), consigcody94 (2025 refresh)"
LABEL org.opencontainers.image.source="https://github.com/consigcody94/stego-toolkit"
LABEL org.opencontainers.image.licenses="MIT"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set locale for consistent behavior
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# =============================================================================
# Stage 1: Install system packages
# =============================================================================
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    # Core utilities
    apt-utils \
    ca-certificates \
    curl \
    wget \
    git \
    unzip \
    # Forensics meta-package (includes many stego tools)
    forensics-all \
    foremost \
    # Image analysis
    binwalk \
    libimage-exiftool-perl \
    pngtools \
    pngcheck \
    imagemagick \
    graphicsmagick \
    # Stego tools from repos
    outguess \
    steghide \
    stegosuite \
    # Development tools for building from source
    build-essential \
    cmake \
    autotools-dev \
    automake \
    libtool \
    pkg-config \
    # Libraries needed for various tools
    libevent-dev \
    libjpeg-dev \
    libpng-dev \
    libmcrypt-dev \
    libmhash-dev \
    zlib1g-dev \
    # Audio tools
    ffmpeg \
    sox \
    audacity \
    sonic-visualiser \
    # Text/hex editors
    hexedit \
    xxd \
    # Python 3 environment
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-setuptools \
    python3-wheel \
    # Ruby for zsteg
    ruby \
    ruby-dev \
    # Node.js for StegCloak
    nodejs \
    npm \
    # Rust toolchain for stegbrute (will be installed by script if needed)
    # cargo \
    # Java for GUI tools (OpenStego, Stegsolve)
    default-jre-headless \
    # Password cracking/generation utilities
    crunch \
    cewl \
    john \
    # Misc utilities
    bsdmainutils \
    file \
    atomicparsley \
    mediainfo \
    # VNC/SSH for GUI access (optional)
    openssh-server \
    tigervnc-standalone-server \
    tigervnc-common \
    novnc \
    xfce4 \
    xfce4-terminal \
    dbus-x11 \
    && \
    # Clean up apt cache to reduce image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# =============================================================================
# Stage 2: Install Python packages
# =============================================================================
# Install Python packages globally (avoiding externally-managed-environment issue)
RUN pip3 install --break-system-packages --no-cache-dir \
    # Core utilities
    python-magic \
    tqdm \
    pillow \
    numpy \
    scipy \
    # Stego tools
    stegoveritas \
    stegano \
    stepic \
    # Additional useful packages
    pycryptodome \
    click

# Install stegoveritas dependencies
RUN stegoveritas_install_deps || true

# =============================================================================
# Stage 3: Install Ruby gems
# =============================================================================
RUN gem install zsteg --no-document

# =============================================================================
# Stage 4: Install tools from source/releases
# =============================================================================

# Copy installation scripts
COPY install /tmp/install
RUN chmod a+x /tmp/install/*.sh

# Run each installation script
RUN for script in /tmp/install/*.sh; do \
        echo "=== Running: $script ===" && \
        bash "$script" || echo "Warning: $script had errors"; \
    done && \
    rm -rf /tmp/install

# =============================================================================
# Stage 5: Create non-root user for security
# =============================================================================
RUN groupadd -r stego && \
    useradd -r -g stego -d /home/stego -s /bin/bash -m stego && \
    # Create directories with proper permissions
    mkdir -p /data /examples && \
    chown -R stego:stego /data /home/stego

# =============================================================================
# Stage 6: Copy project files
# =============================================================================
COPY examples /examples
COPY scripts /opt/scripts
COPY mcp /opt/mcp

# Make scripts executable and fix permissions
RUN find /opt/scripts -name '*.sh' -exec chmod a+x {} + && \
    find /opt/scripts -name '*.py' -exec chmod a+x {} + && \
    chmod a+x /opt/mcp/*.py && \
    chown -R stego:stego /opt/scripts /examples /opt/mcp

# Add scripts to PATH
ENV PATH="/opt/scripts:${PATH}"

# =============================================================================
# Final configuration
# =============================================================================
WORKDIR /data

# Switch to non-root user by default
# Comment out to run as root if needed for certain tools
USER stego

# Default command
CMD ["/bin/bash"]

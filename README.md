# Steganography Toolkit

[![CI - Build and Test](https://github.com/consigcody94/stego-toolkit/actions/workflows/ci.yml/badge.svg)](https://github.com/consigcody94/stego-toolkit/actions/workflows/ci.yml)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://github.com/consigcody94/stego-toolkit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive Docker image for solving steganography challenges in CTF competitions. Pre-installed with 30+ popular tools and automated screening scripts for quick analysis.

> **2025 Refresh**: This is a modernized fork of [DominicBreuker/stego-toolkit](https://github.com/DominicBreuker/stego-toolkit) with updated tools, improved scripts, and CI/CD.

---

## What's New in 2025 Refresh

- **Modern Base Image**: Debian Bookworm (slim) instead of Debian Stretch
- **Multiple Image Variants**:
  - `stego-toolkit:latest` - Full image with GUI support (~2.5GB)
  - `stego-toolkit:cli` - Lightweight CLI-only image (~1.5GB)
  - `stego-toolkit:gpu` - GPU-accelerated with CUDA, hashcat, PyTorch (~8GB)
- **New Tools Added**:
  - [stegseek](https://github.com/RickdeJager/stegseek) - Lightning-fast steghide cracker (cracks rockyou.txt in <2 seconds!)
  - [stegcracker](https://github.com/Paradoxis/StegCracker) - Steghide brute-force utility
  - [hexyl](https://github.com/sharkdp/hexyl) - Modern hex viewer with colored output
- **GPU Support**: NVIDIA CUDA for hashcat, John the Ripper, PyTorch, TensorFlow
- **MCP Integration**: Model Context Protocol server for AI assistant integration (Claude Code, Gemini CLI, Codex CLI)
- **Updated Tools**: All existing tools updated to latest versions
- **Improved Scripts**: Better UX with colored output, `--help` flags, and progress indicators
- **Security**: Non-root user by default, minimal image with `--no-install-recommends`
- **CI/CD**: GitHub Actions for automated builds and smoke tests
- **Python 3 Only**: Removed Python 2 dependencies

---

## Quick Start

### 5-Minute Setup

```bash
# Clone the repository
git clone https://github.com/consigcody94/stego-toolkit.git
cd stego-toolkit

# Build the Docker image (choose your variant)
./bin/build.sh              # Full image with GUI
./bin/build.sh --cli        # CLI-only (lightweight)
./bin/build.sh --gpu        # GPU-accelerated (requires NVIDIA)
./bin/build.sh --all        # Build all variants

# Run the toolkit with your files mounted
./bin/run.sh                # Full image
./bin/run.sh --cli          # CLI-only
./bin/run.sh --gpu          # GPU-accelerated

# Inside the container, analyze a file
check_jpg.sh suspicious.jpg

# Brute-force with stegseek (FAST!)
stegseek suspicious.jpg rockyou.txt
```

### Pull Pre-built Image (when available)

```bash
docker pull ghcr.io/consigcody94/stego-toolkit:latest
docker run -it --rm -v $(pwd)/data:/data ghcr.io/consigcody94/stego-toolkit
```

---

## Image Variants

| Variant | Tag | Size | Description |
|---------|-----|------|-------------|
| **Full** | `stego-toolkit:latest` | ~2.5GB | Complete toolkit with GUI tools (VNC, X11, Stegsolve, Sonic Visualiser) |
| **CLI** | `stego-toolkit:cli` | ~1.5GB | Lightweight CLI-only image, no GUI dependencies |
| **GPU** | `stego-toolkit:gpu` | ~8GB | NVIDIA CUDA support for hashcat, John the Ripper, PyTorch, TensorFlow |

### CLI-Only Image

Perfect for servers, CI/CD, or when you don't need GUI tools:

```bash
# Build CLI image
./bin/build.sh --cli

# Run CLI image
docker run -it --rm -v $(pwd)/data:/data stego-toolkit:cli

# All CLI tools available
stegseek, steghide, zsteg, binwalk, exiftool, strings, foremost, etc.
```

### GPU-Accelerated Image

For password cracking with hashcat and ML-based steganalysis:

```bash
# Prerequisites: NVIDIA GPU + nvidia-container-toolkit
# Install: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html

# Build GPU image
./bin/build.sh --gpu

# Run with GPU access
./bin/run.sh --gpu
# Or: docker run --gpus all -it --rm -v $(pwd)/data:/data stego-toolkit:gpu

# Test GPU availability
gpu-test

# GPU-accelerated password cracking
hashcat -m 0 -a 0 hash.txt rockyou.txt
john-gpu --wordlist=rockyou.txt hashes.txt
```

---

## MCP Integration (AI Assistants)

The toolkit includes an MCP (Model Context Protocol) server for integration with AI assistants like Claude Code, Gemini CLI, and OpenAI Codex CLI.

### Setup for Claude Code / Claude Desktop

Add to your `claude_desktop_config.json`:

```json
{
    "mcpServers": {
        "stego-toolkit": {
            "command": "docker",
            "args": ["run", "-i", "--rm", "-v", "/path/to/data:/data", "stego-toolkit:cli", "python3", "/opt/mcp/stego-mcp-server.py"]
        }
    }
}
```

### Available MCP Tools

| Tool | Description |
|------|-------------|
| `analyze_image` | Comprehensive steganography analysis of images (JPG, PNG, BMP, GIF) |
| `analyze_audio` | Analyze audio files for hidden data (MP3, WAV, FLAC) |
| `extract_steghide` | Extract hidden data with steghide using a known password |
| `crack_steghide` | Attempt to crack steghide password using stegseek |
| `detect_lsb` | Detect LSB steganography in PNG/BMP images |
| `extract_strings` | Extract readable strings from a file |
| `check_metadata` | Extract file metadata using exiftool |
| `binwalk_scan` | Scan for embedded files using binwalk |
| `list_tools` | List all available tools in the toolkit |

### Example Usage with Claude Code

```
User: Analyze this image for hidden data
Claude: [Uses analyze_image tool on /data/suspicious.jpg]

User: Try to crack the steghide password
Claude: [Uses crack_steghide with rockyou.txt wordlist]
```

---

## Tools

### New in 2025 Refresh

| Tool | Description | Usage |
|------|-------------|-------|
| [stegseek](https://github.com/RickdeJager/stegseek) | Lightning-fast steghide cracker. Cracks rockyou.txt in under 2 seconds! | `stegseek stego.jpg wordlist.txt` |
| [stegcracker](https://github.com/Paradoxis/StegCracker) | Steganography brute-force utility | `stegcracker stego.jpg wordlist.txt` |
| [hexyl](https://github.com/sharkdp/hexyl) | Modern hex viewer with colored output | `hexyl stego.jpg` |

### General Screening Tools

| Tool | Description | Usage |
|------|-------------|-------|
| file | Identify file type via magic numbers | `file stego.jpg` |
| exiftool | Extract/edit metadata | `exiftool stego.jpg` |
| binwalk | Find embedded files | `binwalk stego.jpg` |
| strings | Extract readable strings | `strings stego.jpg` |
| foremost | Carve out embedded files | `foremost stego.jpg` |
| pngcheck | Validate PNG structure | `pngcheck stego.png` |
| identify | ImageMagick file info | `identify -verbose stego.jpg` |
| ffmpeg | Audio/video analysis | `ffmpeg -v info -i stego.mp3 -f null -` |

### Steganography Detection Tools

| Tool | File Types | Description | Usage |
|------|-----------|-------------|-------|
| [stegoveritas](https://github.com/bannsec/stegoVeritas) | JPG, PNG, GIF, TIFF, BMP | Comprehensive analysis suite | `stegoveritas stego.jpg` |
| [zsteg](https://github.com/zed-0xff/zsteg) | PNG, BMP | LSB stego detection | `zsteg -a stego.png` |
| stegdetect | JPG | Statistical stego detection | `stegdetect stego.jpg` |
| stegbreak | JPG | Dictionary attack for outguess/jphide/jsteg | `stegbreak -t o -f wordlist.txt stego.jpg` |

### Steganography Tools (Hide/Extract)

| Tool | File Types | How to Hide | How to Extract |
|------|-----------|-------------|----------------|
| [steghide](http://steghide.sourceforge.net/) | JPG, BMP, WAV, AU | `steghide embed -ef secret.txt -cf cover.jpg -p pass -sf stego.jpg` | `steghide extract -sf stego.jpg -p pass` |
| [jsteg](https://github.com/lukechampine/jsteg) | JPG | `jsteg hide cover.jpg secret.txt stego.jpg` | `jsteg reveal stego.jpg output.txt` |
| [openstego](https://github.com/syvaidya/openstego) | PNG | `openstego embed -mf secret.txt -cf cover.png -p pass -sf stego.png` | `openstego extract -sf stego.png -p pass` |
| [outguess](https://github.com/resurrecting-open-source-projects/outguess) | JPG | `outguess -k pass -d secret.txt cover.jpg stego.jpg` | `outguess -r -k pass stego.jpg output.txt` |
| [stegano](https://github.com/cedricbonhomme/Stegano) | PNG | `stegano-lsb hide --input cover.png -f secret.txt -o stego.png` | `stegano-lsb reveal -i stego.png` |
| [LSBSteg](https://github.com/RobinDavid/LSB-Steganography) | PNG, BMP | `LSBSteg encode -i cover.png -o stego.png -f secret.txt` | `LSBSteg decode -i stego.png -o output.txt` |

### GUI Tools

These tools require X11 or VNC. See [GUI and Containers](#gui-and-containers).

| Tool | Description | Command |
|------|-------------|---------|
| [Stegsolve](http://www.caesum.com/handbook/stego.htm) | Image analysis, bit plane viewer | `stegsolve` |
| [Sonic Visualiser](https://www.sonicvisualiser.org/) | Audio spectrogram analysis | `sonic-visualiser` |
| [Stegosuite](https://stegosuite.org/) | Image steganography GUI | `stegosuite` |

---

## Screening Scripts

Automated scripts for quick file analysis. All scripts support `--help` for usage information.

### Check Scripts (Analysis)

```bash
# Analyze JPG files
check_jpg.sh suspicious.jpg
check_jpg.sh -o ./reports suspicious.jpg  # Save detailed reports

# Analyze PNG files
check_png.sh suspicious.png
check_png.sh --verbose suspicious.png
```

### Brute-Force Scripts (Password Cracking)

```bash
# JPG brute-force (uses stegseek by default - FAST!)
brute_jpg.sh suspicious.jpg wordlist.txt
brute_jpg.sh -s suspicious.jpg rockyou.txt  # Stegseek-only mode
brute_jpg.sh -t 8 suspicious.jpg wordlist.txt  # 8 threads

# PNG brute-force
brute_png.sh suspicious.png wordlist.txt

# Python brute-forcer (supports multiple tools)
pybrute.py -f stego.jpg -w wordlist.txt steghide
pybrute.py -f stego.jpg -w wordlist.txt -t 8 outguess
```

### Wordlist Generation

```bash
# Generate wordlist from website
cewl -d 2 -m 6 https://target.com > custom.txt

# Generate pattern-based wordlist
crunch 6 6 abcdefghijklmnopqrstuvwxyz -t @@1984 > pattern.txt

# Expand wordlist with john rules
john --wordlist=base.txt --rules=Single --stdout > expanded.txt
```

---

## Steganography Examples

The image includes sample files for practice:

```bash
# View examples
ls /examples/

# Create stego examples with various tools
/examples/create_examples.sh

# Test your skills on the generated files
check_jpg.sh /examples/stego-files/steghide.jpg
```

---

## GUI and Containers

### Option 1: VNC (Recommended - No Host Dependencies)

```bash
# Start container with VNC port exposed
docker run -it --rm -p 6901:6901 -v $(pwd)/data:/data stego-toolkit

# Inside container, start VNC
start_vnc.sh

# Connect via browser: http://localhost:6901/?password=<printed_password>
```

### Option 2: SSH with X11 Forwarding

```bash
# Start container with SSH port exposed
docker run -it --rm -p 22:22 -v $(pwd)/data:/data stego-toolkit

# Inside container, start SSH server
start_ssh.sh

# From host (requires X11 server)
ssh -X -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no stego@localhost
```

---

## Development

### Building Locally

```bash
# Build the image
docker build -t stego-toolkit .

# Run tests
./tests/smoke_test.sh stego-toolkit
```

### Running Tests

```bash
# Run all smoke tests
./tests/smoke_test.sh stego-toolkit:latest

# Run specific tool tests
docker run --rm stego-toolkit stegseek --help
docker run --rm stego-toolkit check_jpg.sh --help
```

### Project Structure

```
stego-toolkit/
├── Dockerfile          # Full image with GUI support
├── Dockerfile.cli      # CLI-only lightweight image
├── Dockerfile.gpu      # GPU-accelerated image (CUDA)
├── bin/                # Build and run helper scripts
│   ├── build.sh        # Build images (--cli, --gpu, --all)
│   └── run.sh          # Run containers (--cli, --gpu)
├── install/            # Tool installation scripts
├── scripts/            # Analysis and brute-force scripts
├── mcp/                # MCP server for AI assistants
│   └── stego-mcp-server.py
├── examples/           # Sample files for testing
├── tests/              # Smoke tests
└── .github/workflows/  # CI/CD configuration
```

---

## Upgrade Guide (from Original)

If you're coming from the original `dominicbreuker/stego-toolkit`:

### Breaking Changes

1. **Non-root user by default**: Container runs as `stego` user. Use `docker run -u root` if you need root access.
2. **Python 3 only**: `pybrute.py` and other scripts now require Python 3.
3. **Script arguments**: Scripts now use long options (`--help`, `--output`, etc.)

### Migration Steps

```bash
# Old way
docker run -it dominicbreuker/stego-toolkit /bin/bash

# New way
docker run -it ghcr.io/consigcody94/stego-toolkit /bin/bash

# If you need root access
docker run -it -u root ghcr.io/consigcody94/stego-toolkit /bin/bash
```

### New Features to Try

```bash
# Stegseek - 1000x faster than stegcracker for steghide files
stegseek stego.jpg rockyou.txt

# Improved check scripts with colored output
check_jpg.sh --help
check_jpg.sh -o ./reports stego.jpg

# Modern hex viewer
hexyl stego.jpg | head -50
```

---

## Links & Resources

- [Steganography 101 Cheat Sheet](https://pequalsnp-team.github.io/cheatsheet/steganography-101)
- [CTF Forensics Guide](https://trailofbits.github.io/ctf/forensics/)
- [File Format Posters](https://github.com/corkami/pics/blob/master/binary/README.md)
- [Code Identification Cheat Sheet](http://www.ericharshbarger.org/epp/code_sheet.pdf)

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-tool`)
3. Make your changes
4. Run the smoke tests (`./tests/smoke_test.sh`)
5. Submit a pull request

---

## License

MIT License - See [LICENSE](LICENSE) for details.

---

## Credits

- Original project: [DominicBreuker/stego-toolkit](https://github.com/DominicBreuker/stego-toolkit)
- 2025 Refresh by: [consigcody94](https://github.com/consigcody94)
- All tool authors - see individual tool repositories for credits

---

## References

Example media files included in this repository:
- Demo image (JPG, PNG): https://pixabay.com/p-1685092
- Demo sound file (MP3, WAV): [Wikimedia Commons](https://upload.wikimedia.org/wikipedia/commons/c/c5/Auphonic-wikimedia-test-stereo.ogg) - CC BY-SA 3.0

#!/bin/bash
# =============================================================================
# brute_png.sh - PNG steganography brute-force password cracking
# Part of stego-toolkit (2025 refresh)
# =============================================================================
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <image.png> <wordlist.txt>

Brute-force password cracking for PNG steganography files.

Uses multiple tools to try extracting hidden data:
  - openstego
  - stegoveritas (LSB brute-force)

Options:
    -h, --help          Show this help message
    -t, --threads NUM   Number of threads (default: 4)
    -o, --output DIR    Output directory for extracted files

Examples:
    $(basename "$0") suspicious.png rockyou.txt
    $(basename "$0") -t 8 image.png passwords.txt
    $(basename "$0") -o ./output image.png wordlist.txt
EOF
    exit 0
}

print_header() {
    echo ""
    echo -e "${BLUE}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}${BOLD}║${NC} ${CYAN}$1${NC}"
    echo -e "${BLUE}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
}

print_section() {
    echo ""
    echo -e "${YELLOW}━━━━━ $1 ━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[*]${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_warning "Tool '$1' not found - skipping"
        return 1
    fi
    return 0
}

# =============================================================================
# Parse Arguments
# =============================================================================

THREADS=4
OUTPUT_DIR=""
FILE=""
WORDLIST=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -t|--threads)
            THREADS="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -*)
            print_error "Unknown option: $1"
            usage
            ;;
        *)
            if [[ -z "$FILE" ]]; then
                FILE="$1"
            elif [[ -z "$WORDLIST" ]]; then
                WORDLIST="$1"
            fi
            shift
            ;;
    esac
done

# Validate input
if [[ -z "$FILE" ]] || [[ -z "$WORDLIST" ]]; then
    print_error "Missing required arguments"
    usage
fi

if [[ ! -f "$FILE" ]]; then
    print_error "Image file not found: $FILE"
    exit 1
fi

if [[ ! -f "$WORDLIST" ]]; then
    print_error "Wordlist not found: $WORDLIST"
    exit 1
fi

# Create output directory if specified
if [[ -n "$OUTPUT_DIR" ]]; then
    mkdir -p "$OUTPUT_DIR"
fi

# =============================================================================
# Main Brute Force
# =============================================================================

print_header "PNG STEGANOGRAPHY BRUTE-FORCER"
print_info "Image: ${BOLD}$FILE${NC}"
print_info "Wordlist: ${BOLD}$WORDLIST${NC}"
WORDLIST_SIZE=$(wc -l < "$WORDLIST" 2>/dev/null || echo "unknown")
print_info "Wordlist size: ${WORDLIST_SIZE} passwords"
print_info "Threads: $THREADS"
echo ""

# =============================================================================
# OPENSTEGO - via pybrute
# =============================================================================
print_section "OPENSTEGO"
if check_command pybrute.py && check_command openstego; then
    print_info "Running pybrute with openstego..."
    pybrute.py -f "$FILE" -w "$WORDLIST" -t "$THREADS" openstego 2>&1 || true
fi

# =============================================================================
# STEGOVERITAS - LSB Brute Force
# =============================================================================
print_section "STEGOVERITAS (LSB Brute-Force)"
if check_command stegoveritas; then
    UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
    TMP_DIR="${OUTPUT_DIR:-/tmp}/stegoveritas_${UUID}"
    mkdir -p "$TMP_DIR"

    print_info "Running stegoveritas with LSB brute-force..."
    print_warning "This may take a while. Results will be saved to: $TMP_DIR"

    stegoveritas "$FILE" -out "$TMP_DIR" -meta -bruteLSB -imageTransform -colorMap -trailing 2>&1 || true

    print_info "Check $TMP_DIR for results"
fi

# =============================================================================
# Summary
# =============================================================================
print_header "BRUTE-FORCE COMPLETE"
print_info "Checked file: $FILE"
print_info "Wordlist used: $WORDLIST"
echo ""
print_info "Tips:"
print_info "  - PNG files often use LSB steganography (check zsteg output)"
print_info "  - Try check_png.sh first to identify the encoding method"
print_info "  - Generate custom wordlists with: john, crunch, or cewl"
echo ""

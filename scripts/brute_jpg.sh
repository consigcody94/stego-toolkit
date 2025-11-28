#!/bin/bash
# =============================================================================
# brute_jpg.sh - JPG steganography brute-force password cracking
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
Usage: $(basename "$0") [OPTIONS] <image.jpg> <wordlist.txt>

Brute-force password cracking for JPG steganography files.

Uses multiple tools to try extracting hidden data:
  - stegseek (fastest - recommended for steghide files)
  - stegcracker (steghide brute-forcer)
  - steghide
  - outguess / outguess-0.13
  - stegbreak

Options:
    -h, --help          Show this help message
    -t, --threads NUM   Number of threads (default: 4)
    -s, --stegseek-only Only use stegseek (fastest option)
    -o, --output DIR    Output directory for extracted files

Examples:
    $(basename "$0") suspicious.jpg rockyou.txt
    $(basename "$0") -s suspicious.jpg wordlist.txt
    $(basename "$0") -t 8 image.jpg passwords.txt
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
STEGSEEK_ONLY=0
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
        -s|--stegseek-only)
            STEGSEEK_ONLY=1
            shift
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

print_header "JPG STEGANOGRAPHY BRUTE-FORCER"
print_info "Image: ${BOLD}$FILE${NC}"
print_info "Wordlist: ${BOLD}$WORDLIST${NC}"
WORDLIST_SIZE=$(wc -l < "$WORDLIST" 2>/dev/null || echo "unknown")
print_info "Wordlist size: ${WORDLIST_SIZE} passwords"
print_info "Threads: $THREADS"
echo ""

# =============================================================================
# STEGSEEK - Lightning fast steghide cracker (RECOMMENDED)
# =============================================================================
print_section "STEGSEEK (Recommended - Fastest)"
if check_command stegseek; then
    print_info "Running stegseek - this is the fastest steghide cracker"
    print_info "Can crack rockyou.txt in under 2 seconds!"
    OUTPUT_FILE="${OUTPUT_DIR:-/tmp}/stegseek_output_$$.txt"

    if stegseek "$FILE" "$WORDLIST" -xf "$OUTPUT_FILE" -t "$THREADS" 2>&1; then
        if [[ -f "$OUTPUT_FILE" ]]; then
            print_success "Password found! Extracted data saved to: $OUTPUT_FILE"
        fi
    else
        print_info "No password found with stegseek"
    fi
fi

# If stegseek-only mode, stop here
if [[ "$STEGSEEK_ONLY" -eq 1 ]]; then
    print_info "Stegseek-only mode - stopping here"
    exit 0
fi

# =============================================================================
# STEGCRACKER - Python steghide brute-forcer
# =============================================================================
print_section "STEGCRACKER"
if check_command stegcracker; then
    print_info "Running stegcracker..."
    stegcracker "$FILE" "$WORDLIST" -t "$THREADS" 2>&1 || true
fi

# =============================================================================
# PYBRUTE - Legacy brute-forcer (multiple tools)
# =============================================================================
print_section "STEGHIDE (via pybrute)"
if check_command pybrute.py; then
    print_info "Running pybrute with steghide..."
    pybrute.py -f "$FILE" -w "$WORDLIST" -t "$THREADS" steghide 2>&1 || true
fi

print_section "OUTGUESS (via pybrute)"
if check_command pybrute.py; then
    print_info "Running pybrute with outguess..."
    pybrute.py -f "$FILE" -w "$WORDLIST" -t "$THREADS" outguess 2>&1 || true
fi

print_section "OUTGUESS-0.13 (via pybrute)"
if check_command pybrute.py; then
    print_info "Running pybrute with outguess-0.13..."
    pybrute.py -f "$FILE" -w "$WORDLIST" -t "$THREADS" outguess-0.13 2>&1 || true
fi

# =============================================================================
# STEGBREAK - Native JPG cracker
# =============================================================================
print_section "STEGBREAK"
if check_command stegbreak; then
    print_info "Running stegbreak (outguess format)..."
    stegbreak -t o -f "$WORDLIST" "$FILE" 2>&1 || true

    print_info "Running stegbreak (jphide format)..."
    stegbreak -t p -f "$WORDLIST" "$FILE" 2>&1 || true

    print_info "Running stegbreak (jsteg format)..."
    stegbreak -t j -f "$WORDLIST" "$FILE" 2>&1 || true
fi

# =============================================================================
# Summary
# =============================================================================
print_header "BRUTE-FORCE COMPLETE"
print_info "Checked file: $FILE"
print_info "Wordlist used: $WORDLIST"
echo ""
print_info "Tips:"
print_info "  - For fastest results, use stegseek with rockyou.txt"
print_info "  - Generate custom wordlists with: john, crunch, or cewl"
print_info "  - Example: cewl -d 2 -m 6 https://target.com > custom.txt"
echo ""

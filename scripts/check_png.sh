#!/bin/bash
# =============================================================================
# check_png.sh - Automated PNG steganography screening
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

# Configuration
TMP_FILE="/tmp/stego_out_$$"
REPORT_DIR=""
VERBOSE=0

# =============================================================================
# Helper Functions
# =============================================================================

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <image.png>

Automated screening script for PNG files to detect steganography.

Options:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    -o, --output    Output directory for detailed reports
    -q, --quiet     Suppress non-essential output

Examples:
    $(basename "$0") suspicious.png
    $(basename "$0") -v -o ./reports suspicious.png
    $(basename "$0") --help
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

check_result_file() {
    local RESULT_FILE="$1"
    local TOOL_NAME="${2:-Unknown}"

    if [[ ! -f "$RESULT_FILE" ]]; then
        print_info "No output file generated"
        return 1
    fi

    local SIZE
    SIZE=$(stat -c %s "$RESULT_FILE" 2>/dev/null || echo "0")
    local FILE_TYPE
    FILE_TYPE=$(file -b "$RESULT_FILE" 2>/dev/null || echo "unknown")

    if [[ "$FILE_TYPE" != "data" ]] && [[ "$SIZE" -ge 1 ]]; then
        echo ""
        print_success "${BOLD}POTENTIAL DATA FOUND!${NC}"
        echo -e "  Size: ${SIZE} bytes"
        echo -e "  Type: ${FILE_TYPE}"
        echo -e "  ${CYAN}Preview:${NC}"
        echo "  ─────────────────────────────"
        head -n 20 "$RESULT_FILE" | sed 's/^/  /'
        echo "  ─────────────────────────────"

        if [[ -n "$REPORT_DIR" ]]; then
            local REPORT_FILE="${REPORT_DIR}/${TOOL_NAME}_output.txt"
            cp "$RESULT_FILE" "$REPORT_FILE"
            print_info "Full output saved to: $REPORT_FILE"
        fi
        rm -f "$RESULT_FILE"
        return 0
    else
        print_info "No meaningful data extracted (${SIZE} bytes, type: ${FILE_TYPE})"
        rm -f "$RESULT_FILE"
        return 1
    fi
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

QUIET=0
FILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -q|--quiet)
            QUIET=1
            shift
            ;;
        -o|--output)
            REPORT_DIR="$2"
            shift 2
            ;;
        -*)
            print_error "Unknown option: $1"
            usage
            ;;
        *)
            FILE="$1"
            shift
            ;;
    esac
done

# Validate input
if [[ -z "${FILE:-}" ]]; then
    print_error "No input file specified"
    usage
fi

if [[ ! -f "$FILE" ]]; then
    print_error "File not found: $FILE"
    exit 1
fi

# Create report directory if specified
if [[ -n "$REPORT_DIR" ]]; then
    mkdir -p "$REPORT_DIR"
fi

# =============================================================================
# Main Analysis
# =============================================================================

print_header "PNG STEGANOGRAPHY CHECKER"
print_info "Analyzing: ${BOLD}$FILE${NC}"
print_info "Date: $(date)"
echo ""

# Basic file information
print_section "FILE INFORMATION"
if check_command file; then
    file "$FILE"
fi

if check_command pngcheck; then
    print_info "PNG validation:"
    pngcheck -v "$FILE" 2>&1 || true
fi

if check_command identify; then
    print_info "ImageMagick identify:"
    identify -verbose "$FILE" 2>/dev/null | head -30 || true
fi

# Metadata analysis
print_section "METADATA (exiftool)"
if check_command exiftool; then
    exiftool "$FILE" || true
fi

# Embedded file detection
print_section "EMBEDDED FILES (binwalk)"
if check_command binwalk; then
    binwalk "$FILE" || true
fi

# Strings analysis
print_section "STRINGS ANALYSIS"
if check_command strings; then
    print_info "First 20 strings:"
    strings "$FILE" | head -n 20
    echo "..."
    print_info "Last 20 strings:"
    strings "$FILE" | tail -n 20
fi

# zsteg - PNG/BMP LSB detection
print_section "ZSTEG (LSB ANALYSIS)"
if check_command zsteg; then
    print_warning "Watch out for red output - zsteg shows lots of false positives..."
    zsteg "$FILE" -a 2>&1 || true
fi

# OpenStego (empty password)
print_section "OPENSTEGO (empty password)"
if check_command openstego; then
    openstego extract -sf "$FILE" -p "" -xf "$TMP_FILE" 2>&1 || true
    check_result_file "$TMP_FILE" "openstego_empty" || true
fi

# Stegano LSB
print_section "STEGANO-LSB"
if check_command stegano-lsb; then
    for ENCODING in UTF-8 UTF-32LE; do
        print_info "stegano-lsb (encoding: $ENCODING)"
        stegano-lsb reveal --input "$FILE" -e "$ENCODING" -o "$TMP_FILE" 2>&1 || true
        check_result_file "$TMP_FILE" "stegano_lsb_${ENCODING}" || true
    done
fi

# Stegano LSB-set with various generators
print_section "STEGANO-LSB-SET"
if check_command stegano-lsb-set; then
    for GENERATOR in composite eratosthenes fermat fibonacci identity log_gen mersenne triangular_numbers; do
        for ENCODING in UTF-8 UTF-32LE; do
            print_info "stegano-lsb-set (generator: $GENERATOR, encoding: $ENCODING)"
            stegano-lsb-set reveal --input "$FILE" -e "$ENCODING" -g "$GENERATOR" -o "$TMP_FILE" 2>&1 || true
            check_result_file "$TMP_FILE" "stegano_lsb_set_${GENERATOR}_${ENCODING}" || true
        done
    done
fi

# Stegano Red
print_section "STEGANO-RED"
if check_command stegano-red; then
    stegano-red reveal --input "$FILE" 2>&1 || true
fi

# LSBSteg
print_section "LSBSTEG"
if check_command LSBSteg; then
    LSBSteg decode -i "$FILE" -o "$TMP_FILE" 2>/dev/null || true
    check_result_file "$TMP_FILE" "LSBSteg" || true
fi

# stegoveritas
print_section "STEGOVERITAS"
if check_command stegoveritas; then
    UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
    TMP_DIR="${REPORT_DIR:-/tmp}/stegoveritas_${UUID}"
    mkdir -p "$TMP_DIR"
    print_info "Running stegoveritas (output: $TMP_DIR)..."
    stegoveritas "$FILE" -out "$TMP_DIR" -meta -imageTransform -colorMap -trailing 2>&1 || true
    print_info "Check $TMP_DIR for detailed analysis results"
fi

# Cleanup
rm -f "$TMP_FILE" 2>/dev/null || true

# Summary
print_header "ANALYSIS COMPLETE"
print_info "File: $FILE"
print_info "Completed: $(date)"
if [[ -n "$REPORT_DIR" ]]; then
    print_info "Reports saved to: $REPORT_DIR"
fi
echo ""
print_info "Tip: Use 'brute_png.sh' with a wordlist to attempt password cracking"
echo ""

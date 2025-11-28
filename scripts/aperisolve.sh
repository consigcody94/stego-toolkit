#!/bin/bash
# =============================================================================
# aperisolve.sh - Submit files to AperiSolve for online analysis
# AperiSolve is a comprehensive steganalysis platform
# https://www.aperisolve.com/
# =============================================================================
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <file>

Submit an image to AperiSolve for comprehensive steganography analysis.

Options:
    -h, --help      Show this help message
    -p, --password  Password to try for extraction
    -o, --open      Open results in browser (requires xdg-open)
    -q, --quiet     Quiet mode (less output)

Examples:
    $(basename "$0") suspicious.png
    $(basename "$0") -p "secret" image.jpg
    $(basename "$0") -o image.png        # Opens in browser

AperiSolve Analysis Includes:
    - Metadata extraction (exiftool)
    - Binwalk scan
    - Foremost carving
    - Strings extraction
    - Zsteg (PNG/BMP)
    - Steghide (JPG/WAV)
    - Outguess (JPG)
    - And much more...

Note: Requires internet connection. For offline analysis, use stego_analyze.py
EOF
    exit 0
}

# Defaults
PASSWORD=""
OPEN_BROWSER=0
QUIET=0
FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -o|--open)
            OPEN_BROWSER=1
            shift
            ;;
        -q|--quiet)
            QUIET=1
            shift
            ;;
        *)
            if [[ -z "$FILE" ]]; then
                FILE="$1"
            else
                echo -e "${RED}Error: Multiple files not supported${NC}"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate
if [[ -z "$FILE" ]]; then
    echo -e "${RED}Error: No file specified${NC}"
    usage
fi

if [[ ! -f "$FILE" ]]; then
    echo -e "${RED}Error: File not found: $FILE${NC}"
    exit 1
fi

# Check for curl
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required${NC}"
    exit 1
fi

# Get file info
FILE_SIZE=$(stat -c%s "$FILE")
FILE_NAME=$(basename "$FILE")

if [[ $QUIET -eq 0 ]]; then
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               AperiSolve Online Analysis                      ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "File: ${GREEN}$FILE_NAME${NC}"
    echo -e "Size: ${FILE_SIZE} bytes"
    echo ""
fi

# Check file size (AperiSolve has limits)
MAX_SIZE=$((20 * 1024 * 1024))  # 20MB
if [[ $FILE_SIZE -gt $MAX_SIZE ]]; then
    echo -e "${RED}Error: File too large. AperiSolve limit is ~20MB${NC}"
    exit 1
fi

# Submit to AperiSolve
if [[ $QUIET -eq 0 ]]; then
    echo -e "${YELLOW}Uploading to AperiSolve...${NC}"
fi

# Build curl command
CURL_CMD=(curl -s -X POST "https://www.aperisolve.com/api/upload")
CURL_CMD+=(-F "file=@$FILE")

if [[ -n "$PASSWORD" ]]; then
    CURL_CMD+=(-F "password=$PASSWORD")
fi

# Execute upload
RESPONSE=$("${CURL_CMD[@]}" 2>&1)

# Check response
if [[ -z "$RESPONSE" ]]; then
    echo -e "${RED}Error: No response from AperiSolve${NC}"
    echo "The service might be down or you may have no internet connection."
    exit 1
fi

# Try to extract the result URL/ID
# AperiSolve returns JSON with the analysis ID
if echo "$RESPONSE" | grep -q "error"; then
    echo -e "${RED}Error from AperiSolve:${NC}"
    echo "$RESPONSE"
    exit 1
fi

# Extract ID from response (format varies)
ANALYSIS_ID=$(echo "$RESPONSE" | grep -oP '"id"\s*:\s*"\K[^"]+' 2>/dev/null || echo "")

if [[ -z "$ANALYSIS_ID" ]]; then
    # Try alternative extraction
    ANALYSIS_ID=$(echo "$RESPONSE" | grep -oP '[a-f0-9]{32}' | head -1 || echo "")
fi

if [[ -n "$ANALYSIS_ID" ]]; then
    RESULT_URL="https://www.aperisolve.com/$ANALYSIS_ID"

    if [[ $QUIET -eq 0 ]]; then
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  Analysis submitted successfully!${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "Results URL: ${CYAN}$RESULT_URL${NC}"
        echo ""
        echo "The analysis includes:"
        echo "  - File metadata (exiftool)"
        echo "  - Embedded file detection (binwalk)"
        echo "  - File carving (foremost)"
        echo "  - Strings extraction"
        echo "  - LSB analysis (zsteg)"
        echo "  - Steghide/Outguess detection"
        echo "  - Visual transformations"
        echo ""
    else
        echo "$RESULT_URL"
    fi

    # Open in browser if requested
    if [[ $OPEN_BROWSER -eq 1 ]]; then
        if command -v xdg-open &> /dev/null; then
            xdg-open "$RESULT_URL" 2>/dev/null &
        elif command -v open &> /dev/null; then
            open "$RESULT_URL" 2>/dev/null &
        else
            echo -e "${YELLOW}Cannot open browser. Visit the URL manually.${NC}"
        fi
    fi
else
    echo -e "${YELLOW}Upload completed but could not extract result URL.${NC}"
    echo "Response:"
    echo "$RESPONSE"
    echo ""
    echo "Visit https://www.aperisolve.com/ to check your upload."
fi

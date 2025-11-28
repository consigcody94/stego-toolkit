#!/bin/bash
# =============================================================================
# smoke_test.sh - Smoke tests for stego-toolkit Docker image
# Part of stego-toolkit (2025 refresh)
# =============================================================================
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
IMAGE_NAME="${1:-stego-toolkit:test}"
PASSED=0
FAILED=0
SKIPPED=0

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

print_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    ((SKIPPED++))
}

run_in_container() {
    docker run --rm "$IMAGE_NAME" "$@"
}

test_command_exists() {
    local cmd="$1"
    local description="${2:-$cmd}"

    print_test "Checking if '$cmd' exists..."
    if run_in_container which "$cmd" > /dev/null 2>&1; then
        print_pass "$description is available"
        return 0
    else
        print_fail "$description is NOT available"
        return 1
    fi
}

test_command_runs() {
    local cmd="$1"
    local args="${2:---help}"
    local description="${3:-$cmd}"

    print_test "Testing '$cmd $args'..."
    if run_in_container bash -c "$cmd $args" > /dev/null 2>&1; then
        print_pass "$description runs successfully"
        return 0
    else
        print_fail "$description failed to run"
        return 1
    fi
}

# =============================================================================
# Tests
# =============================================================================

print_header "STEGO-TOOLKIT SMOKE TESTS"
echo "Image: $IMAGE_NAME"
echo "Date: $(date)"
echo ""

# Check if image exists
print_test "Checking if Docker image exists..."
if docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
    print_pass "Docker image '$IMAGE_NAME' found"
else
    print_fail "Docker image '$IMAGE_NAME' not found"
    echo "Please build the image first: docker build -t $IMAGE_NAME ."
    exit 1
fi

# =============================================================================
# Core System Tools
# =============================================================================
print_header "CORE SYSTEM TOOLS"

test_command_exists "file" "file (magic number detection)"
test_command_exists "strings" "strings"
test_command_exists "hexdump" "hexdump"
test_command_exists "xxd" "xxd"

# =============================================================================
# Forensics Tools
# =============================================================================
print_header "FORENSICS TOOLS"

test_command_exists "binwalk" "binwalk (firmware analysis)"
test_command_exists "foremost" "foremost (file carving)"
test_command_exists "exiftool" "exiftool (metadata)"

# =============================================================================
# Image Steganography Tools
# =============================================================================
print_header "IMAGE STEGANOGRAPHY TOOLS"

test_command_exists "steghide" "steghide"
test_command_exists "outguess" "outguess"
test_command_exists "zsteg" "zsteg (Ruby)"
test_command_exists "stegoveritas" "stegoveritas (Python)"
test_command_exists "jsteg" "jsteg"
test_command_exists "openstego" "OpenStego"

# Check stegseek (new addition)
test_command_exists "stegseek" "stegseek (fast steghide cracker)"

# Check stegcracker (new addition)
test_command_exists "stegcracker" "stegcracker"

# Check stegify (Go LSB tool)
test_command_exists "stegify" "stegify (Go LSB steganography)"

# Check van-gonography
test_command_exists "van-gonography" "van-gonography (file hiding)"

# =============================================================================
# Stegano Python Library
# =============================================================================
print_header "STEGANO LIBRARY"

test_command_exists "stegano-lsb" "stegano-lsb"
test_command_exists "stegano-lsb-set" "stegano-lsb-set"

# =============================================================================
# Text Steganography Tools
# =============================================================================
print_header "TEXT STEGANOGRAPHY TOOLS"

test_command_exists "stegcloak" "StegCloak (zero-width text stego)"

# =============================================================================
# Audio Tools
# =============================================================================
print_header "AUDIO TOOLS"

test_command_exists "ffmpeg" "ffmpeg"
test_command_exists "sox" "sox"
test_command_exists "sonic-visualiser" "Sonic Visualiser"

# =============================================================================
# Password/Wordlist Tools
# =============================================================================
print_header "PASSWORD TOOLS"

test_command_exists "john" "John the Ripper"
test_command_exists "crunch" "crunch (wordlist generator)"
test_command_exists "cewl" "CeWL (website wordlist generator)"
test_command_exists "stegbrute" "stegbrute (Rust steghide cracker)"

# =============================================================================
# Utility Tools
# =============================================================================
print_header "UTILITY TOOLS"

test_command_exists "identify" "ImageMagick identify"
test_command_exists "pngcheck" "pngcheck"
test_command_exists "hexyl" "hexyl (hex viewer)"

# =============================================================================
# Custom Scripts
# =============================================================================
print_header "CUSTOM SCRIPTS"

test_command_exists "check_jpg.sh" "check_jpg.sh"
test_command_exists "check_png.sh" "check_png.sh"
test_command_exists "brute_jpg.sh" "brute_jpg.sh"
test_command_exists "brute_png.sh" "brute_png.sh"
test_command_exists "pybrute.py" "pybrute.py"
test_command_exists "stego_analyze.py" "stego_analyze.py (auto-analysis)"
test_command_exists "aperisolve.sh" "aperisolve.sh (online analysis)"

# Test script help messages
print_test "Testing check_jpg.sh --help..."
if run_in_container check_jpg.sh --help 2>&1 | grep -q "Usage:"; then
    print_pass "check_jpg.sh shows help"
else
    print_fail "check_jpg.sh help not working"
fi

print_test "Testing brute_jpg.sh --help..."
if run_in_container brute_jpg.sh --help 2>&1 | grep -q "Usage:"; then
    print_pass "brute_jpg.sh shows help"
else
    print_fail "brute_jpg.sh help not working"
fi

print_test "Testing stego_analyze.py --help..."
if run_in_container stego_analyze.py --help 2>&1 | grep -q "Usage\|usage"; then
    print_pass "stego_analyze.py shows help"
else
    print_fail "stego_analyze.py help not working"
fi

print_test "Testing aperisolve.sh --help..."
if run_in_container aperisolve.sh --help 2>&1 | grep -q "Usage:"; then
    print_pass "aperisolve.sh shows help"
else
    print_fail "aperisolve.sh help not working"
fi

# =============================================================================
# Functional Tests with Sample Files
# =============================================================================
print_header "FUNCTIONAL TESTS"

# Test with example files if they exist
print_test "Testing exiftool on example JPG..."
if run_in_container exiftool /examples/ORIGINAL.jpg 2>&1 | grep -q "File Type"; then
    print_pass "exiftool can read example JPG"
else
    print_fail "exiftool failed on example JPG"
fi

print_test "Testing binwalk on example PNG..."
if run_in_container binwalk /examples/ORIGINAL.png > /dev/null 2>&1; then
    print_pass "binwalk can analyze example PNG"
else
    print_fail "binwalk failed on example PNG"
fi

print_test "Testing zsteg on example PNG..."
if run_in_container zsteg /examples/ORIGINAL.png > /dev/null 2>&1; then
    print_pass "zsteg can analyze example PNG"
else
    print_fail "zsteg failed on example PNG"
fi

# =============================================================================
# Python Environment
# =============================================================================
print_header "PYTHON ENVIRONMENT"

print_test "Testing Python 3..."
if run_in_container python3 --version 2>&1 | grep -q "Python 3"; then
    print_pass "Python 3 is available"
else
    print_fail "Python 3 not working"
fi

print_test "Testing pip packages..."
if run_in_container python3 -c "import tqdm; import PIL; import magic" 2>&1; then
    print_pass "Required Python packages installed"
else
    print_fail "Missing Python packages"
fi

# =============================================================================
# Summary
# =============================================================================
print_header "TEST SUMMARY"

TOTAL=$((PASSED + FAILED + SKIPPED))
echo ""
echo -e "Total tests: ${TOTAL}"
echo -e "${GREEN}Passed: ${PASSED}${NC}"
echo -e "${RED}Failed: ${FAILED}${NC}"
echo -e "${YELLOW}Skipped: ${SKIPPED}${NC}"
echo ""

if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi

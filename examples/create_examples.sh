#!/bin/bash
# =============================================================================
# Create Steganography Examples - Generate test files with hidden data
# Updated for 2025 - Modern bash practices
# =============================================================================
set -euo pipefail

# Configuration
PASSPHRASE="abcd"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Source files
COVER_IMAGE_JPG="ORIGINAL.jpg"
COVER_IMAGE_PNG="ORIGINAL.png"
COVER_AUDIO_WAV="ORIGINAL.wav"
COVER_AUDIO_MP3="ORIGINAL.mp3"

# Output directories
STEGO_FILES_FOLDER_JPG="stego-files/jpg"
STEGO_FILES_FOLDER_PNG="stego-files/png"
STEGO_FILES_FOLDER_WAV="stego-files/wav"
STEGO_FILES_FOLDER_MP3="stego-files/mp3"

# Check for required source files
check_file() {
    if [[ ! -e "$1" ]]; then
        echo "Error: Required file '$1' does not exist."
        echo "Please ensure you have the original cover files in $SCRIPT_DIR"
        exit 1
    fi
}

check_file "$COVER_IMAGE_JPG"
check_file "$COVER_IMAGE_PNG"
check_file "$COVER_AUDIO_WAV"
check_file "$COVER_AUDIO_MP3"

# Create output directories
mkdir -p "$STEGO_FILES_FOLDER_JPG"
mkdir -p "$STEGO_FILES_FOLDER_PNG"
mkdir -p "$STEGO_FILES_FOLDER_WAV"
mkdir -p "$STEGO_FILES_FOLDER_MP3"

# Secret message
SECRET_MESSAGE="secret_message.txt"
if [[ ! -f "$SECRET_MESSAGE" ]]; then
    echo "This is a secret message for steganography testing!" > "$SECRET_MESSAGE"
fi
SECRET_MESSAGE_B64=$(base64 < "$SECRET_MESSAGE")

echo "========================================"
echo "Creating Steganography Example Files"
echo "========================================"
echo ""
echo "Passphrase: '$PASSPHRASE'"
echo ""
echo "Secret Message:"
echo "----------------------------------------"
cat "$SECRET_MESSAGE"
echo "----------------------------------------"
echo ""

# Function to run a stego tool with error handling
run_tool() {
    local tool_name="$1"
    shift
    echo ""
    echo "... $tool_name"
    if "$@" 2>/dev/null; then
        echo "    [OK] $tool_name succeeded"
    else
        echo "    [SKIP] $tool_name failed or not available"
    fi
}

###############################
#          JPG Tools          #
###############################

echo ""
echo "=== Creating JPG stego files ==="
COVER_IMAGE="$COVER_IMAGE_JPG"
STEGO_FILES_FOLDER="$STEGO_FILES_FOLDER_JPG"

# steghide
run_tool "steghide" steghide embed -f -ef "$SECRET_MESSAGE" -cf "$COVER_IMAGE" -p "$PASSPHRASE" -sf "$STEGO_FILES_FOLDER/steghide.jpg"

# outguess
run_tool "outguess" outguess -k "$PASSPHRASE" -d "$SECRET_MESSAGE" "$COVER_IMAGE" "$STEGO_FILES_FOLDER/outguess.jpg"

# outguess-0.13
if command -v outguess-0.13 &>/dev/null; then
    run_tool "outguess-0.13" outguess-0.13 -k "$PASSPHRASE" -d "$SECRET_MESSAGE" "$COVER_IMAGE" "$STEGO_FILES_FOLDER/outguess-0.13.jpg"
fi

# jsteg (no passphrase)
run_tool "jsteg" jsteg hide "$COVER_IMAGE" "$SECRET_MESSAGE" "$STEGO_FILES_FOLDER/jsteg.jpg"

###############################
#          PNG Tools          #
###############################

echo ""
echo "=== Creating PNG stego files ==="
COVER_IMAGE="$COVER_IMAGE_PNG"
STEGO_FILES_FOLDER="$STEGO_FILES_FOLDER_PNG"

# openstego
run_tool "openstego" openstego embed -mf "$SECRET_MESSAGE" -cf "$COVER_IMAGE" -p "$PASSPHRASE" -sf "$STEGO_FILES_FOLDER/openstego.png"

# stegano-lsb (no passphrase)
run_tool "stegano-lsb" stegano-lsb hide --input "$COVER_IMAGE" -f "$SECRET_MESSAGE" -e UTF-8 --output "$STEGO_FILES_FOLDER/stegano-lsb.png"

# stegano-red (no passphrase, base64 encoded)
run_tool "stegano-red" stegano-red hide --input "$COVER_IMAGE" -m "$SECRET_MESSAGE_B64" --output "$STEGO_FILES_FOLDER/stegano-red.png"

# cloackedpixel
if command -v cloackedpixel &>/dev/null; then
    echo ""
    echo "... cloackedpixel"
    if cloackedpixel hide "$COVER_IMAGE" "$SECRET_MESSAGE" "$PASSPHRASE" 2>/dev/null; then
        mv "${COVER_IMAGE}-stego.png" "$STEGO_FILES_FOLDER/cloackedpixel.png" 2>/dev/null || true
        echo "    [OK] cloackedpixel succeeded"
    else
        echo "    [SKIP] cloackedpixel failed or not available"
    fi
fi

# LSBSteg
run_tool "LSBSteg" LSBSteg encode -i "$COVER_IMAGE" -o "$STEGO_FILES_FOLDER/LSBSteg.png" -f "$SECRET_MESSAGE"

###############################
#          WAV Tools          #
###############################

echo ""
echo "=== Creating WAV stego files ==="
COVER_AUDIO="$COVER_AUDIO_WAV"
STEGO_FILES_FOLDER="$STEGO_FILES_FOLDER_WAV"

# steghide (WAV)
run_tool "steghide" steghide embed -f -ef "$SECRET_MESSAGE" -cf "$COVER_AUDIO" -p "$PASSPHRASE" -sf "$STEGO_FILES_FOLDER/steghide.wav"

# hideme (AudioStego, no passphrase)
if command -v hideme &>/dev/null; then
    echo ""
    echo "... hideme"
    if hideme "$COVER_AUDIO" "$SECRET_MESSAGE" 2>/dev/null; then
        mv ./output.wav "$STEGO_FILES_FOLDER/hideme.wav" 2>/dev/null || true
        echo "    [OK] hideme succeeded"
    else
        echo "    [SKIP] hideme failed or not available"
    fi
fi

###############################
#          MP3 Tools          #
###############################

echo ""
echo "=== Creating MP3 stego files ==="
COVER_AUDIO="$COVER_AUDIO_MP3"
STEGO_FILES_FOLDER="$STEGO_FILES_FOLDER_MP3"

# mp3stego (requires WAV input)
if command -v mp3stego-encode &>/dev/null; then
    echo ""
    echo "... mp3stego"
    TMP_COVER_AUDIO="/tmp/tmp_cover_audio.wav"
    if ffmpeg -loglevel panic -y -i "$COVER_AUDIO_WAV" -flags bitexact "$TMP_COVER_AUDIO" 2>/dev/null; then
        if mp3stego-encode -E "$SECRET_MESSAGE" -P "$PASSPHRASE" "$TMP_COVER_AUDIO" "$STEGO_FILES_FOLDER/mp3stego.mp3" 2>/dev/null; then
            echo "    [OK] mp3stego succeeded"
        else
            echo "    [SKIP] mp3stego failed"
        fi
        rm -f "$TMP_COVER_AUDIO"
    else
        echo "    [SKIP] mp3stego requires WAV preprocessing"
    fi
fi

echo ""
echo "========================================"
echo "Example files created successfully!"
echo "========================================"
echo ""
echo "Created stego files in:"
ls -la stego-files/*/ 2>/dev/null || echo "  (check stego-files/ directory)"
echo ""
echo "To extract, use the corresponding tool with passphrase: '$PASSPHRASE'"
echo ""
echo "Examples:"
echo "  steghide extract -sf stego-files/jpg/steghide.jpg -p $PASSPHRASE"
echo "  stegseek stego-files/jpg/steghide.jpg rockyou.txt"
echo "  zsteg stego-files/png/stegano-lsb.png"
echo ""

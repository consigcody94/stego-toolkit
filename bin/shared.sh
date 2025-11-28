#!/bin/bash
# =============================================================================
# shared.sh - Shared configuration for build/run scripts
# Part of stego-toolkit (2025 refresh)
# =============================================================================

export IMAGE_NAME="${STEGO_IMAGE_NAME:-stego-toolkit:latest}"

# Get the absolute path of a file or directory
abspath() {
    if [[ -d "$1" ]]; then
        (cd "$1" && pwd)
    elif [[ -f "$1" ]]; then
        if [[ "$1" == /* ]]; then
            echo "$1"
        elif [[ "$1" == */* ]]; then
            echo "$(cd "${1%/*}" && pwd)/${1##*/}"
        else
            echo "$(pwd)/$1"
        fi
    else
        echo "$1"
    fi
}

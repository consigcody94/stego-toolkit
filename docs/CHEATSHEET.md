# Stego-Toolkit CTF Cheatsheet

Quick reference for steganography challenges in CTF competitions.

---

## Quick Analysis Workflow

```bash
# 1. Run automated analysis (recommended first step)
stego_analyze.py suspicious.jpg

# 2. Or run individual tools manually
file suspicious.jpg           # File type
exiftool suspicious.jpg       # Metadata
binwalk suspicious.jpg        # Embedded files
strings suspicious.jpg        # Readable text
```

---

## By File Type

### JPEG Analysis

```bash
# Basic analysis
file image.jpg
exiftool image.jpg
strings image.jpg | head -50

# Steghide (most common in CTFs)
steghide info -sf image.jpg
steghide extract -sf image.jpg -p ""           # Try empty password
steghide extract -sf image.jpg -p "password"   # Known password

# Crack steghide password (FAST - use stegseek!)
stegseek image.jpg rockyou.txt                 # Seconds to crack!
stegseek image.jpg --seed                      # Detect if stego exists

# Other JPEG tools
jsteg reveal image.jpg output.txt              # JSTEG steganography
outguess -r image.jpg output.txt               # Outguess
outguess-0.13 -r image.jpg output.txt          # Older outguess
stegdetect image.jpg                           # Detect stego type
```

### PNG/BMP Analysis

```bash
# Basic analysis
file image.png
pngcheck -v image.png                          # PNG structure
exiftool image.png

# LSB analysis (zsteg is essential!)
zsteg image.png                                # Quick scan
zsteg -a image.png                             # All combinations
zsteg -E "b1,rgb,lsb,xy" image.png             # Extract specific

# Other PNG tools
stegoveritas image.png                         # Comprehensive analysis
openstego extract -sf image.png -p pass        # OpenStego extraction
stegano-lsb reveal -i image.png                # Stegano-lsb
LSBSteg decode -i image.png -o output.txt      # LSBSteg

# stegify (file in image)
stegify decode --carrier image.png --result hidden.zip
```

### Audio Analysis

```bash
# Basic analysis
file audio.wav
mediainfo audio.wav
exiftool audio.wav
strings audio.wav

# Steghide (works with WAV)
steghide info -sf audio.wav
steghide extract -sf audio.wav -p "password"

# Spectrogram (look for hidden images!)
# Use Sonic Visualiser or Audacity
# Add spectrogram layer and look for patterns

# Spectrology (hide image in audio)
spectrology -o hidden.wav secret_image.png     # Create
# To reveal: view spectrogram in audio software

# hideme (AudioStego)
hideme audio.wav -o output.txt
```

### Text/Data Analysis

```bash
# Zero-width characters (invisible text)
stegcloak reveal                               # Interactive
stegcloak reveal -p password "text with hidden data"

# Check for hidden whitespace
cat -A file.txt                                # Show all characters
xxd file.txt | head                            # Hex view

# Bitstring/data analysis
examine_data.py "01001000011001010110110001101100"  # Binary
examine_data.py "48656c6c6f"                   # Hex
```

---

## Tool Quick Reference

### Password Cracking (Steghide)

| Tool | Speed | Usage |
|------|-------|-------|
| **stegseek** | ⚡ Fastest | `stegseek file.jpg wordlist.txt` |
| stegbrute | Fast | `stegbrute -f file.jpg -w wordlist.txt` |
| stegcracker | Slow | `stegcracker file.jpg wordlist.txt` |

### LSB Steganography

| Tool | Formats | Usage |
|------|---------|-------|
| **zsteg** | PNG, BMP | `zsteg -a image.png` |
| stegano-lsb | PNG | `stegano-lsb reveal -i image.png` |
| LSBSteg | PNG, BMP | `LSBSteg decode -i image.png` |
| stegify | PNG, JPG, GIF, BMP | `stegify decode --carrier img.png --result out` |

### JPEG Steganography

| Tool | Usage |
|------|-------|
| **steghide** | `steghide extract -sf image.jpg -p pass` |
| jsteg | `jsteg reveal image.jpg output.txt` |
| outguess | `outguess -r -k pass image.jpg output.txt` |
| stegdetect | `stegdetect image.jpg` |

### Metadata & Embedded Files

| Tool | Usage |
|------|-------|
| **exiftool** | `exiftool image.jpg` |
| **binwalk** | `binwalk -e image.jpg` |
| foremost | `foremost -i image.jpg` |
| strings | `strings -n 8 image.jpg` |

---

## Common CTF Patterns

### Check First
1. `file` - Is it really what the extension says?
2. `exiftool` - Comments? GPS? Unusual fields?
3. `strings` - Any readable flags or hints?
4. `binwalk` - Embedded files (zip, png inside jpg)?

### JPEG Challenges
```bash
# 90% of JPEG stego uses steghide
stegseek image.jpg rockyou.txt      # Try cracking first
steghide extract -sf image.jpg -p "" # Then try empty password
```

### PNG Challenges
```bash
# Always try zsteg first
zsteg -a image.png | head -50
# Look for ASCII text or file signatures
```

### Audio Challenges
```bash
# Check spectrogram first (visual data)
# Then try steghide if WAV
steghide extract -sf audio.wav -p ""
```

---

## Flag Patterns to Search For

```bash
# Common flag formats
strings file | grep -iE "(flag|ctf|htb|pico|key)\{.*\}"

# Base64 encoded
strings file | base64 -d 2>/dev/null | grep -i flag

# Hex encoded
strings file | xxd -r -p 2>/dev/null | grep -i flag
```

---

## Wordlists

```bash
# Default wordlist location
/usr/share/wordlists/rockyou.txt

# Generate custom wordlist from webpage
cewl https://target.com -d 2 -m 6 > custom.txt

# Generate pattern-based wordlist
crunch 6 6 abcdefghijklmnopqrstuvwxyz -t @@2024 > pattern.txt
```

---

## Quick Install Reference

```bash
# Run specific tool installer
bash /tmp/install/stegseek.sh

# Check available tools
list_tools              # If stego-toolkit command available

# Common tools to verify
which stegseek steghide zsteg exiftool binwalk strings
```

---

## Online Tools (When Offline Tools Fail)

- **AperiSolve** - https://www.aperisolve.com/ (comprehensive analysis)
- **StegOnline** - https://stegonline.georgeom.net/ (image analysis)
- **Forensically** - https://29a.ch/photo-forensics/ (image forensics)
- **CyberChef** - https://gchq.github.io/CyberChef/ (encoding/decoding)

---

## Troubleshooting

### "No embedded data found"
1. Try different passwords (empty, common words, challenge hints)
2. Try different tools (steghide vs jsteg vs outguess)
3. Check if it's actually steganography (might be forensics)

### "Tool not working"
```bash
# Check if tool exists
which toolname

# Run installer
bash /tmp/install/toolname.sh

# Check tool help
toolname --help
toolname-help
```

### "File type mismatch"
```bash
# Check real file type
file suspicious.jpg
# Might say: "PNG image data" even with .jpg extension
# Rename and try appropriate tools
```

---

## Scripts Reference

| Script | Purpose | Usage |
|--------|---------|-------|
| `stego_analyze.py` | Auto-run all tools | `stego_analyze.py file.jpg` |
| `check_jpg.sh` | JPEG analysis | `check_jpg.sh image.jpg` |
| `check_png.sh` | PNG analysis | `check_png.sh image.png` |
| `brute_jpg.sh` | Crack JPEG stego | `brute_jpg.sh image.jpg wordlist.txt` |
| `brute_png.sh` | Crack PNG stego | `brute_png.sh image.png wordlist.txt` |
| `pybrute.py` | Multi-tool brute | `pybrute.py -f file -w wordlist tool` |

---

*Part of [stego-toolkit](https://github.com/consigcody94/stego-toolkit) - 2025 Refresh*

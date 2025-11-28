#!/usr/bin/env python3
"""
stego_analyze.py - Comprehensive Steganography Analysis Tool
============================================================
Automatically runs all available stego tools on a file and generates a report.

Usage:
    stego_analyze.py <file> [options]
    stego_analyze.py suspicious.jpg
    stego_analyze.py suspicious.jpg --wordlist rockyou.txt --output report.txt

Part of stego-toolkit (2025 refresh)
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple


# ANSI colors
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'


def print_banner():
    """Print the tool banner."""
    banner = f"""
{Colors.CYAN}╔═══════════════════════════════════════════════════════════════╗
║           Stego-Toolkit Automated Analysis                     ║
║                    2025 Refresh                                ║
╚═══════════════════════════════════════════════════════════════╝{Colors.END}
"""
    print(banner)


def print_section(title: str):
    """Print a section header."""
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'═' * 60}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}  {title}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'═' * 60}{Colors.END}\n")


def print_tool(name: str, status: str = "running"):
    """Print tool execution status."""
    if status == "running":
        print(f"  {Colors.YELLOW}▶{Colors.END} Running {Colors.BOLD}{name}{Colors.END}...")
    elif status == "success":
        print(f"  {Colors.GREEN}✓{Colors.END} {name} completed")
    elif status == "failed":
        print(f"  {Colors.RED}✗{Colors.END} {name} failed or not available")
    elif status == "found":
        print(f"  {Colors.GREEN}★{Colors.END} {Colors.BOLD}{name} - POTENTIAL FINDING!{Colors.END}")


def run_command(cmd: List[str], timeout: int = 60) -> Tuple[bool, str]:
    """Run a command and return success status and output."""
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        output = result.stdout + result.stderr
        return result.returncode == 0, output
    except subprocess.TimeoutExpired:
        return False, "Command timed out"
    except FileNotFoundError:
        return False, "Command not found"
    except Exception as e:
        return False, str(e)


def check_tool(name: str) -> bool:
    """Check if a tool is available."""
    return shutil.which(name) is not None


def get_file_type(filepath: str) -> str:
    """Get file type using the 'file' command."""
    success, output = run_command(["file", "-b", filepath])
    return output.strip() if success else "Unknown"


def get_file_info(filepath: str) -> Dict:
    """Get basic file information."""
    path = Path(filepath)
    return {
        "name": path.name,
        "size": path.stat().st_size,
        "extension": path.suffix.lower(),
        "type": get_file_type(filepath)
    }


class StegoAnalyzer:
    """Main steganography analyzer class."""

    def __init__(self, filepath: str, wordlist: Optional[str] = None, output_dir: Optional[str] = None):
        self.filepath = os.path.abspath(filepath)
        self.wordlist = wordlist or "/usr/share/wordlists/rockyou.txt"
        self.output_dir = output_dir or tempfile.mkdtemp(prefix="stego_")
        self.results: Dict[str, Dict] = {}
        self.findings: List[str] = []
        self.file_info = get_file_info(filepath)

    def analyze(self) -> Dict:
        """Run all applicable analyses."""
        print_banner()
        print(f"Analyzing: {Colors.BOLD}{self.filepath}{Colors.END}")
        print(f"File type: {self.file_info['type']}")
        print(f"File size: {self.file_info['size']:,} bytes")
        print(f"Output dir: {self.output_dir}")

        # Run analyses based on file type
        ext = self.file_info['extension']
        file_type = self.file_info['type'].lower()

        # General analysis (all files)
        print_section("General Analysis")
        self._run_file_analysis()
        self._run_exiftool()
        self._run_binwalk()
        self._run_strings()

        # Image-specific analysis
        if ext in ['.jpg', '.jpeg', '.png', '.bmp', '.gif'] or 'image' in file_type:
            print_section("Image Analysis")
            self._run_image_analysis()

        # JPEG-specific
        if ext in ['.jpg', '.jpeg'] or 'jpeg' in file_type:
            print_section("JPEG-Specific Analysis")
            self._run_jpeg_analysis()

        # PNG/BMP-specific
        if ext in ['.png', '.bmp'] or 'png' in file_type or 'bitmap' in file_type:
            print_section("PNG/BMP-Specific Analysis")
            self._run_png_analysis()

        # Audio-specific
        if ext in ['.wav', '.mp3', '.flac', '.ogg'] or 'audio' in file_type:
            print_section("Audio Analysis")
            self._run_audio_analysis()

        # Password cracking attempts
        if ext in ['.jpg', '.jpeg', '.bmp', '.wav'] or any(x in file_type for x in ['jpeg', 'bitmap', 'wav']):
            print_section("Password Cracking Attempts")
            self._run_password_cracking()

        # Generate report
        return self._generate_report()

    def _run_file_analysis(self):
        """Run basic file analysis."""
        # file command
        print_tool("file")
        success, output = run_command(["file", self.filepath])
        self.results["file"] = {"success": success, "output": output}
        print_tool("file", "success" if success else "failed")

        # xxd (hex dump preview)
        if check_tool("xxd"):
            print_tool("xxd (hex preview)")
            success, output = run_command(["xxd", "-l", "256", self.filepath])
            self.results["xxd"] = {"success": success, "output": output}
            print_tool("xxd", "success" if success else "failed")

    def _run_exiftool(self):
        """Run exiftool for metadata."""
        if not check_tool("exiftool"):
            return

        print_tool("exiftool")
        success, output = run_command(["exiftool", self.filepath])
        self.results["exiftool"] = {"success": success, "output": output}

        # Check for interesting metadata
        if success:
            interesting = ["comment", "hidden", "secret", "flag", "password", "ctf"]
            for keyword in interesting:
                if keyword in output.lower():
                    self.findings.append(f"exiftool: Found '{keyword}' in metadata")
                    print_tool(f"exiftool ({keyword} found)", "found")
                    return

        print_tool("exiftool", "success" if success else "failed")

    def _run_binwalk(self):
        """Run binwalk for embedded files."""
        if not check_tool("binwalk"):
            return

        print_tool("binwalk")
        success, output = run_command(["binwalk", self.filepath])
        self.results["binwalk"] = {"success": success, "output": output}

        # Check for embedded files
        if success and len(output.strip().split('\n')) > 3:
            self.findings.append("binwalk: Potential embedded files detected")
            print_tool("binwalk (embedded files)", "found")

            # Try extraction
            print_tool("binwalk extract")
            extract_dir = os.path.join(self.output_dir, "binwalk_extracted")
            success2, output2 = run_command(["binwalk", "-e", "-C", extract_dir, self.filepath])
            self.results["binwalk_extract"] = {"success": success2, "output": output2, "dir": extract_dir}
            print_tool("binwalk extract", "success" if success2 else "failed")
        else:
            print_tool("binwalk", "success" if success else "failed")

    def _run_strings(self):
        """Run strings for readable text."""
        if not check_tool("strings"):
            return

        print_tool("strings")
        success, output = run_command(["strings", "-n", "8", self.filepath])
        self.results["strings"] = {"success": success, "output": output[:5000]}  # Limit output

        # Check for flags/interesting strings
        if success:
            patterns = ["flag{", "ctf{", "htb{", "picoctf{", "secret", "password", "base64"]
            for pattern in patterns:
                if pattern in output.lower():
                    self.findings.append(f"strings: Found '{pattern}' pattern")
                    print_tool(f"strings ({pattern})", "found")
                    return

        print_tool("strings", "success" if success else "failed")

    def _run_image_analysis(self):
        """Run image-specific analysis."""
        # identify (ImageMagick)
        if check_tool("identify"):
            print_tool("identify")
            success, output = run_command(["identify", "-verbose", self.filepath])
            self.results["identify"] = {"success": success, "output": output[:3000]}
            print_tool("identify", "success" if success else "failed")

        # pngcheck (for PNG)
        if check_tool("pngcheck") and self.file_info['extension'] == '.png':
            print_tool("pngcheck")
            success, output = run_command(["pngcheck", "-v", self.filepath])
            self.results["pngcheck"] = {"success": success, "output": output}
            print_tool("pngcheck", "success" if success else "failed")

    def _run_jpeg_analysis(self):
        """Run JPEG-specific analysis."""
        # steghide info
        if check_tool("steghide"):
            print_tool("steghide info")
            success, output = run_command(["steghide", "info", "-sf", self.filepath], timeout=10)
            self.results["steghide_info"] = {"success": success, "output": output}
            if "embedded file" in output.lower():
                self.findings.append("steghide: Embedded data detected!")
                print_tool("steghide (embedded data)", "found")
            else:
                print_tool("steghide info", "success" if success else "failed")

        # stegdetect
        if check_tool("stegdetect"):
            print_tool("stegdetect")
            success, output = run_command(["stegdetect", self.filepath])
            self.results["stegdetect"] = {"success": success, "output": output}
            if success and "negative" not in output.lower():
                self.findings.append(f"stegdetect: {output.strip()}")
                print_tool("stegdetect", "found")
            else:
                print_tool("stegdetect", "success" if success else "failed")

        # jsteg
        if check_tool("jsteg"):
            print_tool("jsteg reveal")
            output_file = os.path.join(self.output_dir, "jsteg_output.txt")
            success, output = run_command(["jsteg", "reveal", self.filepath, output_file])
            self.results["jsteg"] = {"success": success, "output": output}
            if success and os.path.exists(output_file) and os.path.getsize(output_file) > 0:
                self.findings.append("jsteg: Hidden data extracted!")
                print_tool("jsteg (data found)", "found")
            else:
                print_tool("jsteg", "success" if success else "failed")

    def _run_png_analysis(self):
        """Run PNG/BMP-specific analysis."""
        # zsteg
        if check_tool("zsteg"):
            print_tool("zsteg")
            success, output = run_command(["zsteg", "-a", self.filepath], timeout=120)
            self.results["zsteg"] = {"success": success, "output": output[:5000]}

            if success:
                # Check for meaningful output
                interesting_lines = []
                for line in output.split('\n'):
                    if any(x in line.lower() for x in ['text', 'flag', 'ctf', 'ascii', 'utf']):
                        if 'nothing' not in line.lower() and len(line.strip()) > 10:
                            interesting_lines.append(line.strip())

                if interesting_lines:
                    self.findings.append(f"zsteg: Potential findings - {interesting_lines[0][:100]}")
                    print_tool("zsteg (potential data)", "found")
                else:
                    print_tool("zsteg", "success")
            else:
                print_tool("zsteg", "failed")

        # stegoveritas
        if check_tool("stegoveritas"):
            print_tool("stegoveritas")
            veritas_dir = os.path.join(self.output_dir, "stegoveritas")
            success, output = run_command(
                ["stegoveritas", self.filepath, "-out", veritas_dir, "-meta", "-imageTransform"],
                timeout=180
            )
            self.results["stegoveritas"] = {"success": success, "output": output[:2000], "dir": veritas_dir}
            print_tool("stegoveritas", "success" if success else "failed")

    def _run_audio_analysis(self):
        """Run audio-specific analysis."""
        # mediainfo
        if check_tool("mediainfo"):
            print_tool("mediainfo")
            success, output = run_command(["mediainfo", self.filepath])
            self.results["mediainfo"] = {"success": success, "output": output}
            print_tool("mediainfo", "success" if success else "failed")

        # ffmpeg info
        if check_tool("ffmpeg"):
            print_tool("ffmpeg")
            success, output = run_command(["ffmpeg", "-i", self.filepath, "-f", "null", "-"])
            self.results["ffmpeg"] = {"success": True, "output": output}
            print_tool("ffmpeg", "success")

        # steghide for WAV
        if check_tool("steghide") and self.file_info['extension'] == '.wav':
            print_tool("steghide info (WAV)")
            success, output = run_command(["steghide", "info", "-sf", self.filepath], timeout=10)
            self.results["steghide_wav"] = {"success": success, "output": output}
            print_tool("steghide info", "success" if success else "failed")

    def _run_password_cracking(self):
        """Attempt password cracking with common tools."""
        # stegseek (fastest)
        if check_tool("stegseek") and os.path.exists(self.wordlist):
            print_tool("stegseek")
            output_file = os.path.join(self.output_dir, "stegseek_output")
            success, output = run_command(
                ["stegseek", self.filepath, self.wordlist, "-xf", output_file],
                timeout=120
            )
            self.results["stegseek"] = {"success": success, "output": output}

            if "found" in output.lower() or (os.path.exists(output_file) and os.path.getsize(output_file) > 0):
                self.findings.append(f"stegseek: PASSWORD CRACKED! Check {output_file}")
                print_tool("stegseek (PASSWORD FOUND)", "found")
            else:
                print_tool("stegseek", "success" if success else "failed")

        # Try empty password with steghide
        if check_tool("steghide"):
            print_tool("steghide (empty password)")
            output_file = os.path.join(self.output_dir, "steghide_empty.txt")
            success, output = run_command(
                ["steghide", "extract", "-sf", self.filepath, "-p", "", "-xf", output_file, "-f"],
                timeout=10
            )
            if success and os.path.exists(output_file) and os.path.getsize(output_file) > 0:
                self.findings.append(f"steghide: Extracted with empty password! Check {output_file}")
                print_tool("steghide (EXTRACTED - no password)", "found")
            else:
                print_tool("steghide (empty)", "failed")

    def _generate_report(self) -> Dict:
        """Generate the final analysis report."""
        print_section("Analysis Summary")

        report = {
            "timestamp": datetime.now().isoformat(),
            "file": self.file_info,
            "results": self.results,
            "findings": self.findings,
            "output_directory": self.output_dir
        }

        # Print findings
        if self.findings:
            print(f"{Colors.GREEN}{Colors.BOLD}Potential Findings:{Colors.END}")
            for finding in self.findings:
                print(f"  {Colors.GREEN}★{Colors.END} {finding}")
        else:
            print(f"{Colors.YELLOW}No obvious findings. Manual analysis recommended.{Colors.END}")

        print(f"\n{Colors.CYAN}Output directory: {self.output_dir}{Colors.END}")
        print(f"{Colors.CYAN}Tools run: {len(self.results)}{Colors.END}")

        # Save JSON report
        report_file = os.path.join(self.output_dir, "report.json")
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2, default=str)
        print(f"{Colors.CYAN}Report saved: {report_file}{Colors.END}")

        return report


def main():
    parser = argparse.ArgumentParser(
        description="Comprehensive steganography analysis tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s suspicious.jpg
  %(prog)s image.png --wordlist custom.txt
  %(prog)s audio.wav --output ./analysis_results
        """
    )
    parser.add_argument("file", help="File to analyze")
    parser.add_argument("-w", "--wordlist", default="/usr/share/wordlists/rockyou.txt",
                        help="Wordlist for password cracking (default: rockyou.txt)")
    parser.add_argument("-o", "--output", help="Output directory for results")
    parser.add_argument("-q", "--quiet", action="store_true", help="Quiet mode (less output)")

    args = parser.parse_args()

    # Validate input file
    if not os.path.exists(args.file):
        print(f"{Colors.RED}Error: File not found: {args.file}{Colors.END}")
        sys.exit(1)

    # Run analysis
    analyzer = StegoAnalyzer(args.file, args.wordlist, args.output)
    report = analyzer.analyze()

    # Exit with appropriate code
    sys.exit(0 if report["findings"] else 1)


if __name__ == "__main__":
    main()

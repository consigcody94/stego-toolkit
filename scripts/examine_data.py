#!/usr/bin/env python3
"""
examine_data.py - Analyze extracted data from steganography tools
Updated for 2025 - Python 3 compatible

Analyzes bitstrings and other data formats commonly found in CTF challenges.
"""

import argparse
import re
import sys


class BitstringAnalyser:
    """Analyze and convert bitstrings to various formats."""

    def __init__(self, bitstring: str):
        self.bitstring = bitstring

    def analyze(self) -> None:
        """Run all analysis methods on the bitstring."""
        if self._is_bitstring():
            print(f"\nBitstring found: length={len(self.bitstring)} content='{self.bitstring[:50]}{'...' if len(self.bitstring) > 50 else ''}'")
            self._try_convert_to_string()
            self._try_convert_to_integer()
            self._try_convert_to_hex()
            self._try_reverse_bitstring()
        else:
            print(f"Input is not a valid bitstring (0s and 1s only)")
            print(f"Attempting other analyses...")
            self._try_hex_decode()
            self._try_base64_decode()

    def _is_bitstring(self) -> bool:
        """Check if the input is a valid bitstring."""
        return bool(re.match(r"^[01]+$", self.bitstring))

    def _try_convert_to_string(self) -> None:
        """Convert bitstring to ASCII string."""
        try:
            # Pad to multiple of 8
            padded = self.bitstring
            if len(padded) % 8 != 0:
                padded = padded.zfill(len(padded) + (8 - len(padded) % 8))

            chars = []
            for b in range(len(padded) // 8):
                byte = padded[b * 8:(b + 1) * 8]
                char_val = int(byte, 2)
                if 32 <= char_val <= 126:  # Printable ASCII
                    chars.append(chr(char_val))
                else:
                    chars.append(f'\\x{char_val:02x}')

            result = ''.join(chars)
            self._print_result("ASCII string", result)
        except Exception as e:
            self._print_fail("ASCII string", str(e))

    def _try_convert_to_integer(self) -> None:
        """Convert bitstring to integer."""
        try:
            result = int(self.bitstring, 2)
            self._print_result("integer", result)
        except Exception as e:
            self._print_fail("integer", str(e))

    def _try_convert_to_hex(self) -> None:
        """Convert bitstring to hexadecimal."""
        try:
            result = hex(int(self.bitstring, 2))
            self._print_result("hexadecimal", result)
        except Exception as e:
            self._print_fail("hexadecimal", str(e))

    def _try_reverse_bitstring(self) -> None:
        """Try converting reversed bitstring to string."""
        try:
            reversed_bits = self.bitstring[::-1]
            padded = reversed_bits
            if len(padded) % 8 != 0:
                padded = padded.zfill(len(padded) + (8 - len(padded) % 8))

            chars = []
            for b in range(len(padded) // 8):
                byte = padded[b * 8:(b + 1) * 8]
                char_val = int(byte, 2)
                if 32 <= char_val <= 126:
                    chars.append(chr(char_val))
                else:
                    chars.append(f'\\x{char_val:02x}')

            result = ''.join(chars)
            # Only show if it looks different/useful
            if any(c.isalpha() for c in result):
                self._print_result("reversed bitstring", result)
        except Exception as e:
            pass  # Silent fail for this optional analysis

    def _try_hex_decode(self) -> None:
        """Try decoding as hex string."""
        try:
            if re.match(r'^[0-9a-fA-F]+$', self.bitstring) and len(self.bitstring) % 2 == 0:
                result = bytes.fromhex(self.bitstring).decode('utf-8', errors='replace')
                self._print_result("hex decode", result)
        except Exception:
            pass

    def _try_base64_decode(self) -> None:
        """Try decoding as base64."""
        try:
            import base64
            result = base64.b64decode(self.bitstring).decode('utf-8', errors='replace')
            if result and any(c.isalpha() for c in result):
                self._print_result("base64 decode", result)
        except Exception:
            pass

    def _print_result(self, conversion_type: str, result) -> None:
        """Print successful conversion result."""
        result_str = str(result)
        if len(result_str) > 100:
            print(f" - Conversion to {conversion_type}: '{result_str[:100]}...'")
        else:
            print(f" - Conversion to {conversion_type}: '{result_str}'")

    def _print_fail(self, conversion_type: str, reason: str) -> None:
        """Print failed conversion."""
        print(f" - Conversion to {conversion_type}: FAILED ({reason})")


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        prog='examine_data',
        description='Analyze data extracted from steganography tools',
        epilog='Examples:\n'
               '  examine_data.py "01001000011001010110110001101100"\n'
               '  examine_data.py 48656c6c6f\n'
               '  cat extracted.txt | examine_data.py\n',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "data",
        nargs="?",
        type=str,
        help="Data to analyse (bitstring, hex, or other format)"
    )
    return parser.parse_args()


def main():
    """Main entry point."""
    args = parse_args()

    # Read from stdin if no argument provided
    if args.data:
        data = args.data.strip()
    elif not sys.stdin.isatty():
        data = sys.stdin.read().strip()
    else:
        print("Usage: examine_data.py <data>")
        print("       cat file.txt | examine_data.py")
        sys.exit(1)

    if not data:
        print("Error: No data provided")
        sys.exit(1)

    BitstringAnalyser(data).analyze()


if __name__ == "__main__":
    main()

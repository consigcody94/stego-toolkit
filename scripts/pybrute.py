#!/usr/bin/env python3
# =============================================================================
# pybrute.py - Multi-tool steganography brute-forcer
# Part of stego-toolkit (2025 refresh)
# =============================================================================
"""
Brute-force password cracker for various steganography tools.
Supports: steghide, outguess, outguess-0.13, openstego
"""

import os
import re
import sys
import hashlib
import argparse
import threading
import subprocess
from typing import Optional
from concurrent.futures import ThreadPoolExecutor, as_completed

try:
    from tqdm import tqdm
except ImportError:
    # Fallback if tqdm is not available
    class tqdm:
        def __init__(self, total=0, **kwargs):
            self.total = total
            self.n = 0

        def update(self, n=1):
            self.n += n

        def __enter__(self):
            return self

        def __exit__(self, *args):
            pass


# Global flag to stop on first success
found_password = threading.Event()


class StegoCracker:
    """Base class for steganography crackers."""

    def __init__(self, stego_file: str):
        self.stego_file = stego_file

    def try_password(self, passphrase: str) -> Optional[str]:
        """Try a single password. Returns message if successful, None otherwise."""
        raise NotImplementedError("Subclasses must implement try_password")


class SteghideCracker(StegoCracker):
    """Cracker for steghide encrypted files."""

    def try_password(self, passphrase: str) -> Optional[str]:
        if found_password.is_set():
            return None

        try:
            process = subprocess.Popen(
                ['steghide', 'info', self.stego_file, '-p', passphrase],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            out, err = process.communicate(timeout=30)
            out = out.decode('utf-8', errors='ignore')

            match = re.search(r'embedded file "(.+)"', out)
            if match:
                found_password.set()
                return (
                    f"\n[+] PASSWORD FOUND: '{passphrase}'\n"
                    f"[+] Embedded file: '{match.group(1)}'\n"
                    f"[+] Extract with: steghide extract -sf {self.stego_file} -p \"{passphrase}\""
                )
        except subprocess.TimeoutExpired:
            pass
        except Exception:
            pass
        return None


class OutguessCracker(StegoCracker):
    """Cracker for outguess encrypted files."""

    def __init__(self, stego_file: str, version: str = "outguess"):
        super().__init__(stego_file)
        self.command = version  # "outguess" or "outguess-0.13"

    def try_password(self, passphrase: str) -> Optional[str]:
        if found_password.is_set():
            return None

        tmp_file = f"/tmp/{hashlib.md5(passphrase.encode()).hexdigest()}"
        try:
            process = subprocess.Popen(
                [self.command, '-k', passphrase, '-r', self.stego_file, tmp_file],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            process.communicate(timeout=30)

            if os.path.exists(tmp_file):
                with open(tmp_file, 'rb') as f:
                    data = f.read()

                os.remove(tmp_file)

                if len(data) > 0:
                    # Check if data is mostly ASCII (likely text)
                    ascii_chars = sum(1 for b in data if b < 128)
                    if len(data) > 0 and float(ascii_chars) / float(len(data)) > 0.8:
                        found_password.set()
                        preview = data[:500].decode('utf-8', errors='ignore')
                        return (
                            f"\n[+] PASSWORD FOUND: '{passphrase}'\n"
                            f"[+] Data preview:\n---\n{preview}\n---\n"
                            f"[+] Extract with: {self.command} -k \"{passphrase}\" -r {self.stego_file} /tmp/output.txt"
                        )
        except subprocess.TimeoutExpired:
            pass
        except Exception:
            pass
        finally:
            if os.path.exists(tmp_file):
                try:
                    os.remove(tmp_file)
                except OSError:
                    pass
        return None


class OpenstegoCracker(StegoCracker):
    """Cracker for OpenStego encrypted files."""

    def try_password(self, passphrase: str) -> Optional[str]:
        if found_password.is_set():
            return None

        try:
            process = subprocess.Popen(
                ['openstego', 'extract', '-p', passphrase, '-sf', self.stego_file],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            out, err = process.communicate(timeout=30)
            err = err.decode('utf-8', errors='ignore')

            match = re.search(r'Extracted file: (.+)', err)
            if match:
                found_password.set()
                return (
                    f"\n[+] PASSWORD FOUND: '{passphrase}'\n"
                    f"[+] Extracted file: '{match.group(1)}'\n"
                    f"[+] Extract with: openstego extract -sf {self.stego_file} -p \"{passphrase}\""
                )
        except subprocess.TimeoutExpired:
            pass
        except Exception:
            pass
        return None


def get_cracker(tool: str, stego_file: str) -> StegoCracker:
    """Factory function to create the appropriate cracker."""
    crackers = {
        'steghide': lambda: SteghideCracker(stego_file),
        'outguess': lambda: OutguessCracker(stego_file, 'outguess'),
        'outguess-0.13': lambda: OutguessCracker(stego_file, 'outguess-0.13'),
        'openstego': lambda: OpenstegoCracker(stego_file),
    }

    if tool not in crackers:
        raise ValueError(f"Unknown tool: {tool}. Available: {', '.join(crackers.keys())}")

    return crackers[tool]()


def count_lines(filepath: str) -> int:
    """Count lines in a file efficiently."""
    with open(filepath, 'rb') as f:
        return sum(1 for _ in f)


def bruteforce(cracker: StegoCracker, wordlist_path: str, num_threads: int) -> None:
    """Run brute-force attack using thread pool."""
    total_passwords = count_lines(wordlist_path)

    print(f"[*] Starting brute-force with {num_threads} threads")
    print(f"[*] Total passwords to try: {total_passwords}")

    with open(wordlist_path, 'r', errors='ignore') as wordlist:
        with tqdm(total=total_passwords, desc="Progress", unit="pwd") as progress:
            with ThreadPoolExecutor(max_workers=num_threads) as executor:
                futures = {}

                for line in wordlist:
                    if found_password.is_set():
                        break

                    passphrase = line.strip()
                    if not passphrase:
                        progress.update(1)
                        continue

                    future = executor.submit(cracker.try_password, passphrase)
                    futures[future] = passphrase

                    # Process completed futures to avoid memory buildup
                    if len(futures) >= num_threads * 10:
                        done = [f for f in futures if f.done()]
                        for f in done:
                            result = f.result()
                            if result:
                                print(result)
                            del futures[f]
                            progress.update(1)

                # Process remaining futures
                for future in as_completed(futures):
                    result = future.result()
                    if result:
                        print(result)
                    progress.update(1)

    if not found_password.is_set():
        print("\n[-] Password not found in wordlist")


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        prog='pybrute.py',
        description='Multi-tool steganography brute-forcer',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  pybrute.py -f image.jpg -w wordlist.txt steghide
  pybrute.py -f image.jpg -w rockyou.txt -t 8 outguess
  pybrute.py -f image.png -w passwords.txt openstego

Supported tools:
  steghide      - JPEG/BMP steganography
  outguess      - JPEG steganography (current version)
  outguess-0.13 - JPEG steganography (legacy version)
  openstego     - PNG steganography
        """
    )

    parser.add_argument(
        '-f', '--file',
        required=True,
        help='Stego file to crack'
    )
    parser.add_argument(
        '-w', '--wordlist',
        required=True,
        help='Wordlist file with passwords'
    )
    parser.add_argument(
        '-t', '--threads',
        type=int,
        default=4,
        help='Number of threads (default: 4)'
    )

    subparsers = parser.add_subparsers(
        title='Tools',
        description='Choose the steganography tool',
        dest='tool'
    )

    subparsers.add_parser('steghide', help='Crack steghide files')
    subparsers.add_parser('outguess', help='Crack outguess files')
    subparsers.add_parser('outguess-0.13', help='Crack outguess-0.13 files')
    subparsers.add_parser('openstego', help='Crack openstego files')

    args = parser.parse_args()

    if not args.tool:
        parser.error("Please specify a tool (steghide, outguess, outguess-0.13, openstego)")

    return args


def main():
    """Main entry point."""
    args = parse_args()

    # Validate inputs
    if not os.path.exists(args.file):
        print(f"[-] Error: File not found: {args.file}")
        sys.exit(1)

    if not os.path.exists(args.wordlist):
        print(f"[-] Error: Wordlist not found: {args.wordlist}")
        sys.exit(1)

    print(f"[*] Target file: {args.file}")
    print(f"[*] Wordlist: {args.wordlist}")
    print(f"[*] Tool: {args.tool}")
    print(f"[*] Threads: {args.threads}")

    try:
        cracker = get_cracker(args.tool, args.file)
        bruteforce(cracker, args.wordlist, args.threads)
    except KeyboardInterrupt:
        print("\n[!] Interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"[-] Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

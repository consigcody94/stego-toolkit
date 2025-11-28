#!/usr/bin/env python3
"""
Stego-Toolkit MCP Server
========================
Model Context Protocol server for steganography analysis.

Compatible with:
- Claude Code / Claude Desktop
- Gemini CLI
- OpenAI Codex CLI
- Any MCP-compatible AI assistant

Usage:
    python stego-mcp-server.py

Configuration (claude_desktop_config.json):
    {
        "mcpServers": {
            "stego-toolkit": {
                "command": "docker",
                "args": ["run", "-i", "--rm", "-v", "/path/to/data:/data", "stego-toolkit:cli", "python3", "/opt/mcp/stego-mcp-server.py"]
            }
        }
    }
"""

import asyncio
import base64
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Optional


# MCP Protocol Implementation
class MCPServer:
    """Simple MCP server implementation for stego-toolkit."""

    def __init__(self):
        self.tools = {
            "analyze_image": self.analyze_image,
            "analyze_audio": self.analyze_audio,
            "extract_steghide": self.extract_steghide,
            "crack_steghide": self.crack_steghide,
            "detect_lsb": self.detect_lsb,
            "extract_strings": self.extract_strings,
            "check_metadata": self.check_metadata,
            "binwalk_scan": self.binwalk_scan,
            "list_tools": self.list_tools,
        }

    async def handle_request(self, request: dict) -> dict:
        """Handle incoming MCP request."""
        method = request.get("method", "")
        params = request.get("params", {})
        request_id = request.get("id")

        try:
            if method == "initialize":
                return self._initialize_response(request_id)
            elif method == "tools/list":
                return self._list_tools_response(request_id)
            elif method == "tools/call":
                return await self._call_tool(request_id, params)
            elif method == "resources/list":
                return self._list_resources_response(request_id)
            else:
                return self._error_response(request_id, -32601, f"Method not found: {method}")
        except Exception as e:
            return self._error_response(request_id, -32603, str(e))

    def _initialize_response(self, request_id: Any) -> dict:
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "tools": {},
                    "resources": {},
                },
                "serverInfo": {
                    "name": "stego-toolkit",
                    "version": "2.0.0",
                },
            },
        }

    def _list_tools_response(self, request_id: Any) -> dict:
        tools = [
            {
                "name": "analyze_image",
                "description": "Comprehensive steganography analysis of an image file (JPG, PNG, BMP, GIF). Runs multiple detection tools including exiftool, binwalk, strings, zsteg, and stegoveritas.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "file_path": {
                            "type": "string",
                            "description": "Path to the image file to analyze",
                        },
                        "thorough": {
                            "type": "boolean",
                            "description": "Run thorough analysis (slower but more comprehensive)",
                            "default": False,
                        },
                    },
                    "required": ["file_path"],
                },
            },
            {
                "name": "analyze_audio",
                "description": "Analyze audio file for hidden data (MP3, WAV, FLAC). Checks metadata, spectrograms, and common audio stego techniques.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "file_path": {
                            "type": "string",
                            "description": "Path to the audio file to analyze",
                        },
                    },
                    "required": ["file_path"],
                },
            },
            {
                "name": "extract_steghide",
                "description": "Extract hidden data from a file using steghide with a known password.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "file_path": {
                            "type": "string",
                            "description": "Path to the stego file",
                        },
                        "password": {
                            "type": "string",
                            "description": "Password for extraction (empty string for no password)",
                            "default": "",
                        },
                    },
                    "required": ["file_path"],
                },
            },
            {
                "name": "crack_steghide",
                "description": "Attempt to crack steghide password using stegseek (very fast) with a wordlist.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "file_path": {
                            "type": "string",
                            "description": "Path to the stego file",
                        },
                        "wordlist": {
                            "type": "string",
                            "description": "Path to wordlist file (default: rockyou.txt)",
                            "default": "/usr/share/wordlists/rockyou.txt",
                        },
                    },
                    "required": ["file_path"],
                },
            },
            {
                "name": "detect_lsb",
                "description": "Detect LSB (Least Significant Bit) steganography in PNG/BMP images using zsteg.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "file_path": {
                            "type": "string",
                            "description": "Path to the image file",
                        },
                    },
                    "required": ["file_path"],
                },
            },
            {
                "name": "extract_strings",
                "description": "Extract readable strings from a file.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "file_path": {
                            "type": "string",
                            "description": "Path to the file",
                        },
                        "min_length": {
                            "type": "integer",
                            "description": "Minimum string length",
                            "default": 4,
                        },
                    },
                    "required": ["file_path"],
                },
            },
            {
                "name": "check_metadata",
                "description": "Extract and display file metadata using exiftool.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "file_path": {
                            "type": "string",
                            "description": "Path to the file",
                        },
                    },
                    "required": ["file_path"],
                },
            },
            {
                "name": "binwalk_scan",
                "description": "Scan file for embedded files and data using binwalk.",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "file_path": {
                            "type": "string",
                            "description": "Path to the file",
                        },
                        "extract": {
                            "type": "boolean",
                            "description": "Extract embedded files",
                            "default": False,
                        },
                    },
                    "required": ["file_path"],
                },
            },
            {
                "name": "list_tools",
                "description": "List all available steganography tools in the toolkit.",
                "inputSchema": {
                    "type": "object",
                    "properties": {},
                },
            },
        ]

        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {"tools": tools},
        }

    def _list_resources_response(self, request_id: Any) -> dict:
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {"resources": []},
        }

    async def _call_tool(self, request_id: Any, params: dict) -> dict:
        tool_name = params.get("name")
        arguments = params.get("arguments", {})

        if tool_name not in self.tools:
            return self._error_response(request_id, -32602, f"Unknown tool: {tool_name}")

        try:
            result = await self.tools[tool_name](**arguments)
            return {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {
                    "content": [{"type": "text", "text": result}],
                },
            }
        except Exception as e:
            return self._error_response(request_id, -32603, f"Tool error: {str(e)}")

    def _error_response(self, request_id: Any, code: int, message: str) -> dict:
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "error": {"code": code, "message": message},
        }

    # Tool implementations
    async def analyze_image(self, file_path: str, thorough: bool = False) -> str:
        """Comprehensive image analysis."""
        results = []
        results.append(f"=== Stego Analysis: {file_path} ===\n")

        # File type
        results.append("--- File Type ---")
        results.append(self._run_command(["file", file_path]))

        # Metadata
        results.append("\n--- Metadata (exiftool) ---")
        results.append(self._run_command(["exiftool", file_path]))

        # Binwalk
        results.append("\n--- Embedded Files (binwalk) ---")
        results.append(self._run_command(["binwalk", file_path]))

        # Strings (brief)
        results.append("\n--- Strings (first 20) ---")
        strings_out = self._run_command(["strings", file_path])
        results.append("\n".join(strings_out.split("\n")[:20]))

        # LSB detection for PNG/BMP
        if file_path.lower().endswith((".png", ".bmp")):
            results.append("\n--- LSB Analysis (zsteg) ---")
            results.append(self._run_command(["zsteg", "-a", file_path]))

        # Steghide check (empty password)
        if file_path.lower().endswith((".jpg", ".jpeg", ".bmp")):
            results.append("\n--- Steghide (empty password) ---")
            results.append(self._run_command(["steghide", "info", "-sf", file_path, "-p", ""]))

            # Stegseek seed detection
            results.append("\n--- Stegseek Seed Detection ---")
            results.append(self._run_command(["stegseek", "--seed", file_path]))

        if thorough:
            results.append("\n--- StegOveritas (thorough) ---")
            with tempfile.TemporaryDirectory() as tmpdir:
                self._run_command(["stegoveritas", file_path, "-out", tmpdir, "-meta", "-imageTransform"])
                results.append(f"Results saved to: {tmpdir}")

        return "\n".join(results)

    async def analyze_audio(self, file_path: str) -> str:
        """Analyze audio file."""
        results = []
        results.append(f"=== Audio Analysis: {file_path} ===\n")

        results.append("--- File Type ---")
        results.append(self._run_command(["file", file_path]))

        results.append("\n--- Metadata (exiftool) ---")
        results.append(self._run_command(["exiftool", file_path]))

        results.append("\n--- Media Info ---")
        results.append(self._run_command(["mediainfo", file_path]))

        results.append("\n--- FFmpeg Info ---")
        results.append(self._run_command(["ffmpeg", "-i", file_path, "-f", "null", "-"], stderr=True))

        results.append("\n--- Strings (first 20) ---")
        strings_out = self._run_command(["strings", file_path])
        results.append("\n".join(strings_out.split("\n")[:20]))

        return "\n".join(results)

    async def extract_steghide(self, file_path: str, password: str = "") -> str:
        """Extract with steghide."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=".out") as tmp:
            result = self._run_command([
                "steghide", "extract", "-sf", file_path, "-p", password, "-xf", tmp.name, "-f"
            ])
            if os.path.exists(tmp.name) and os.path.getsize(tmp.name) > 0:
                with open(tmp.name, "rb") as f:
                    data = f.read()
                try:
                    content = data.decode("utf-8")
                    return f"Extracted data:\n{content}"
                except UnicodeDecodeError:
                    return f"Extracted binary data ({len(data)} bytes): {data[:100]}..."
            return f"Extraction result:\n{result}"

    async def crack_steghide(self, file_path: str, wordlist: str = "/usr/share/wordlists/rockyou.txt") -> str:
        """Crack steghide with stegseek."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=".out") as tmp:
            result = self._run_command(["stegseek", file_path, wordlist, "-xf", tmp.name])
            if "found" in result.lower() or os.path.getsize(tmp.name) > 0:
                with open(tmp.name, "rb") as f:
                    data = f.read()
                try:
                    content = data.decode("utf-8")
                    return f"Password cracked!\n{result}\n\nExtracted data:\n{content}"
                except UnicodeDecodeError:
                    return f"Password cracked!\n{result}\n\nExtracted binary data ({len(data)} bytes)"
            return f"Crack attempt result:\n{result}"

    async def detect_lsb(self, file_path: str) -> str:
        """Detect LSB steganography."""
        return self._run_command(["zsteg", "-a", file_path])

    async def extract_strings(self, file_path: str, min_length: int = 4) -> str:
        """Extract strings from file."""
        return self._run_command(["strings", f"-n{min_length}", file_path])

    async def check_metadata(self, file_path: str) -> str:
        """Check file metadata."""
        return self._run_command(["exiftool", file_path])

    async def binwalk_scan(self, file_path: str, extract: bool = False) -> str:
        """Scan with binwalk."""
        if extract:
            with tempfile.TemporaryDirectory() as tmpdir:
                result = self._run_command(["binwalk", "-e", "-C", tmpdir, file_path])
                # List extracted files
                extracted = self._run_command(["find", tmpdir, "-type", "f"])
                return f"{result}\n\nExtracted files:\n{extracted}"
        return self._run_command(["binwalk", file_path])

    async def list_tools(self) -> str:
        """List available tools."""
        tools = [
            "=== Stego-Toolkit Available Tools ===\n",
            "Image Analysis:",
            "  - exiftool     : Metadata extraction",
            "  - binwalk      : Embedded file detection",
            "  - zsteg        : LSB steganography detection (PNG/BMP)",
            "  - stegoveritas : Comprehensive image analysis",
            "  - pngcheck     : PNG validation",
            "  - identify     : ImageMagick file info",
            "",
            "Steganography Tools:",
            "  - steghide     : Hide/extract data in JPG/BMP/WAV",
            "  - stegseek     : Fast steghide password cracker",
            "  - stegcracker  : Steghide brute-forcer",
            "  - outguess     : JPG steganography",
            "  - jsteg        : JPEG LSB steganography",
            "  - openstego    : PNG steganography",
            "  - stegano-lsb  : Python LSB stego",
            "",
            "Audio Tools:",
            "  - ffmpeg       : Audio/video processing",
            "  - sox          : Audio manipulation",
            "  - sonic-visualiser : Spectrogram analysis (GUI)",
            "",
            "Password Tools:",
            "  - john         : Password cracker",
            "  - hashcat      : GPU password cracker (GPU image)",
            "  - crunch       : Wordlist generator",
            "  - cewl         : Website wordlist generator",
        ]
        return "\n".join(tools)

    def _run_command(self, cmd: list, stderr: bool = False) -> str:
        """Run a shell command and return output."""
        try:
            if stderr:
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
                return result.stderr or result.stdout
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
            return result.stdout or result.stderr
        except subprocess.TimeoutExpired:
            return f"Command timed out: {' '.join(cmd)}"
        except FileNotFoundError:
            return f"Command not found: {cmd[0]}"
        except Exception as e:
            return f"Error running {cmd[0]}: {str(e)}"


async def main():
    """Main entry point."""
    server = MCPServer()

    # Read from stdin, write to stdout (stdio transport)
    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                break

            request = json.loads(line)
            response = await server.handle_request(request)
            sys.stdout.write(json.dumps(response) + "\n")
            sys.stdout.flush()
        except json.JSONDecodeError:
            continue
        except KeyboardInterrupt:
            break


if __name__ == "__main__":
    asyncio.run(main())

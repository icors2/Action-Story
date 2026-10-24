#!/usr/bin/env python3
"""Write a 32x16 two-tile placeholder atlas (solid + one-way)."""
from __future__ import annotations

import struct
import zlib
from pathlib import Path

W, H = 32, 16
# Tile 0: solid world (green). Tile 1: one-way platform (amber).
SOLID = (46, 112, 64, 255)
ONEWAY = (196, 148, 52, 255)


def png_rgba(path: Path, width: int, height: int, pixels: bytes) -> None:
    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    raw = b""
    for y in range(height):
        raw += b"\x00" + pixels[y * width * 4 : (y + 1) * width * 4]
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


def main() -> None:
    pixels = bytearray()
    for _y in range(H):
        for x in range(W):
            pixels.extend(SOLID if x < 16 else ONEWAY)
    out = Path(__file__).resolve().parents[1] / "game/content/tilesets/placeholder.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    png_rgba(out, W, H, bytes(pixels))
    print(f"wrote {out}")


if __name__ == "__main__":
    main()

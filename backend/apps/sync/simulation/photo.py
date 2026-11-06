"""The placeholder photo (T071): one small JPEG, made once, so every upload after the first
finds the same SHA-256 and the server answers `exists` (the dedup path)."""

import hashlib
import io
from dataclasses import dataclass

from PIL import Image

WIDTH, HEIGHT = 320, 240


@dataclass(frozen=True)
class Placeholder:
    content: bytes
    sha256: str
    size: int
    mime_type: str = "image/jpeg"
    width: int = WIDTH
    height: int = HEIGHT


def make_placeholder():
    image = Image.new("RGB", (WIDTH, HEIGHT), (142, 168, 98))
    buffer = io.BytesIO()
    image.save(buffer, "JPEG", quality=70)
    content = buffer.getvalue()
    return Placeholder(content, hashlib.sha256(content).hexdigest(), len(content))

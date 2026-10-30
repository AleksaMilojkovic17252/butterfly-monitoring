"""Where photo bytes live (T049): plain storage and image functions, with no rules and no
permissions. `observations.services` decides who may do what and calls these.

An original is stored once per SHA-256 (`photos/<aa>/<bb>/<sha256>.<ext>`), however many photo
records point at it. Objects are never deleted here: several records may share one, and a soft
delete keeps its row (D-072).
"""

from io import BytesIO

from django.core.files.base import ContentFile, File
from django.core.files.storage import default_storage
from PIL import Image, ImageOps

THUMBNAIL_PX = 400  # on the long edge
THUMBNAIL_QUALITY = 85


def original_key(sha256, ext):
    return f"photos/{sha256[0:2]}/{sha256[2:4]}/{sha256}.{ext}"


def thumb_key(sha256):
    return f"thumbs/{sha256}.jpg"


def put_original(sha256, ext, fileobj):
    """Store the file under its content key and return the key. An existing object is kept as it
    is: that is the deduplication."""
    key = original_key(sha256, ext)
    if default_storage.exists(key):
        return key
    name = default_storage.save(key, File(fileobj))
    if name != key:
        # AWS_S3_FILE_OVERWRITE is False, so a parallel PUT that won the race made django-storages
        # save this copy under a suffixed name. Drop the copy, the winner holds the same bytes.
        default_storage.delete(name)
    return key


def original_exists(key):
    return bool(key) and default_storage.exists(key)


def make_thumbnail(sha256, key):
    """Create `thumbs/<sha256>.jpg` from the original at `key`, unless it exists. EXIF orientation
    is applied, so the thumbnail is upright."""
    thumb = thumb_key(sha256)
    if default_storage.exists(thumb):
        return thumb
    with default_storage.open(key, "rb") as original:
        image = Image.open(original)
        # Shrink first: a JPEG is then decoded at reduced size, so a large image stays cheap.
        image.thumbnail((THUMBNAIL_PX, THUMBNAIL_PX))
        image = ImageOps.exif_transpose(image)
        if image.mode in ("RGBA", "LA", "P"):  # a JPEG has no alpha: flatten on white
            image = image.convert("RGBA")
            flat = Image.new("RGB", image.size, "white")
            flat.paste(image, mask=image.getchannel("A"))
            image = flat
        else:
            image = image.convert("RGB")
        buffer = BytesIO()
        image.save(buffer, "JPEG", quality=THUMBNAIL_QUALITY)
    name = default_storage.save(thumb, ContentFile(buffer.getvalue()))
    if name != thumb:  # a parallel complete won the race, as in put_original
        default_storage.delete(name)
    return thumb


def open_original(photo):
    return default_storage.open(photo.storage_key, "rb")


def open_thumbnail(photo):
    return default_storage.open(thumb_key(photo.sha256), "rb")

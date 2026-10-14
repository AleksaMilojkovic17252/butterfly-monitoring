import uuid

import boto3
from botocore.exceptions import BotoCoreError, ClientError
from django.conf import settings
from django.core.files.base import ContentFile
from django.core.files.storage import default_storage
from django.db import connection


def check_db():
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        return True
    except Exception:
        return False


def _ensure_bucket():
    """Create the bucket on first use (MinIO starts empty)."""
    client = boto3.client(
        "s3",
        endpoint_url=settings.AWS_S3_ENDPOINT_URL,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
        region_name=settings.AWS_S3_REGION_NAME,
    )
    try:
        client.head_bucket(Bucket=settings.AWS_STORAGE_BUCKET_NAME)
    except ClientError:
        client.create_bucket(Bucket=settings.AWS_STORAGE_BUCKET_NAME)


def check_storage():
    """Write and delete a small object through the default storage."""
    try:
        _ensure_bucket()
        name = default_storage.save(f"healthcheck/{uuid.uuid4()}.txt", ContentFile(b"ok"))
        default_storage.delete(name)
        return True
    except (BotoCoreError, ClientError, OSError):
        return False

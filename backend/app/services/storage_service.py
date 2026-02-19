from google.cloud import storage
from datetime import timedelta
from app.core.config import settings

def upload_to_gcs(file_content: bytes, bucket_name: str, destination_blob_name: str) -> str:
    """
    GCS에 업로드하고, '객체 경로(destination_blob_name)'를 반환합니다.
    (public_url 반환은 조직 정책으로 의미가 없어서 사용하지 않습니다.)
    """
    # storage_client = storage.Client.from_service_account_json(settings.GCP_KEY_PATH)
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)

    blob.upload_from_string(file_content, content_type="image/jpeg")
    return destination_blob_name  # ✅ path 반환


def generate_signed_url(bucket_name: str, blob_name: str, expires_minutes: int = 60) -> str:
    """
    비공개 객체에 접근 가능한 V4 Signed URL 생성
    """
    # storage_client = storage.Client.from_service_account_json(settings.GCP_KEY_PATH)
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(blob_name)

    return blob.generate_signed_url(
        version="v4",
        expiration=timedelta(minutes=expires_minutes),
        method="GET",
    )

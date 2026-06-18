from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable

from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload

from .config import UploadConfig

SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]


def authorize(upload_config: UploadConfig) -> Credentials:
    if not upload_config.client_secrets_path:
        raise RuntimeError("Set YOUTUBE_CLIENT_SECRETS to a valid client_secrets.json path for uploads.")
    token_path = upload_config.credentials_path
    creds = None
    if token_path.exists():
        creds = Credentials.from_authorized_user_file(token_path.as_posix(), SCOPES)
    if creds is None or not creds.valid:
        flow = InstalledAppFlow.from_client_secrets_file(upload_config.client_secrets_path, SCOPES)
        creds = flow.run_local_server(port=0)
        token_path.write_text(creds.to_json(), encoding="utf-8")
    return creds


def upload_video(
    video_path: Path,
    title: str,
    description: str,
    tags: Iterable[str],
    thumbnail_path: Path | None,
    privacy: str,
    category_id: str,
    upload_config: UploadConfig,
) -> str:
    creds = authorize(upload_config)
    youtube = build("youtube", "v3", credentials=creds)
    body = {
        "snippet": {
            "title": title,
            "description": description,
            "tags": list(tags),
            "categoryId": category_id,
        },
        "status": {"privacyStatus": privacy},
    }
    media = MediaFileUpload(video_path.as_posix(), chunksize=-1, resumable=True)
    request = youtube.videos().insert(part="snippet,status", body=body, media_body=media)
    response = None
    try:
        response = request.execute()
    except HttpError as exc:
        raise RuntimeError(f"YouTube upload failed: {exc}") from exc
    video_id = response.get("id")
    if not video_id:
        raise RuntimeError(f"Unexpected YouTube response: {json.dumps(response, indent=2)}")
    if thumbnail_path:
        youtube.thumbnails().set(videoId=video_id, media_body=thumbnail_path.as_posix()).execute()
    return video_id

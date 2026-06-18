from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


@dataclass(frozen=True)
class VoiceConfig:
    provider: str = "gtts"
    language: str = "en"
    voice_name: str | None = None


@dataclass(frozen=True)
class UploadConfig:
    client_secrets_path: Path | None = None
    credentials_path: Path = Path("token.json")
    default_privacy: str = "private"
    default_tags: tuple[str, ...] = ()
    category_id: str = "22"


@dataclass(frozen=True)
class RenderConfig:
    width: int = 1080
    height: int = 1920
    bitrate: str = "5M"
    font: str | None = None
    background_color: str = "#0d0d0f"
    accent_color: str = "#ffd166"
    music_volume: float = 0.2
    voice_volume: float = 1.0


@dataclass(frozen=True)
class AppConfig:
    output_dir: Path = Path("output")
    temp_dir: Path = Path("output/tmp")
    voice: VoiceConfig = VoiceConfig()
    upload: UploadConfig = UploadConfig()
    render: RenderConfig = RenderConfig()

    @staticmethod
    def load(env_path: str | None = None) -> "AppConfig":
        load_dotenv(env_path)
        voice = VoiceConfig(
            provider=os.getenv("VOICE_PROVIDER", "gtts"),
            language=os.getenv("VOICE_LANGUAGE", "en"),
            voice_name=os.getenv("VOICE_NAME"),
        )
        upload = UploadConfig(
            client_secrets_path=Path(os.getenv("YOUTUBE_CLIENT_SECRETS", "client_secrets.json"))
            if os.getenv("YOUTUBE_CLIENT_SECRETS")
            else None,
            credentials_path=Path(os.getenv("YOUTUBE_TOKEN_PATH", "token.json")),
            default_privacy=os.getenv("YOUTUBE_DEFAULT_PRIVACY", "private"),
            default_tags=tuple(tag.strip() for tag in os.getenv("YOUTUBE_DEFAULT_TAGS", "").split(",") if tag.strip()),
            category_id=os.getenv("YOUTUBE_CATEGORY_ID", "22"),
        )
        render = RenderConfig(
            width=int(os.getenv("VIDEO_WIDTH", 1080)),
            height=int(os.getenv("VIDEO_HEIGHT", 1920)),
            bitrate=os.getenv("VIDEO_BITRATE", "5M"),
            font=os.getenv("VIDEO_FONT"),
            background_color=os.getenv("VIDEO_BG", "#0d0d0f"),
            accent_color=os.getenv("VIDEO_ACCENT", "#ffd166"),
            music_volume=float(os.getenv("MUSIC_VOLUME", 0.2)),
            voice_volume=float(os.getenv("VOICE_VOLUME", 1.0)),
        )
        return AppConfig(
            output_dir=Path(os.getenv("OUTPUT_DIR", "output")),
            temp_dir=Path(os.getenv("TEMP_DIR", "output/tmp")),
            voice=voice,
            upload=upload,
            render=render,
        )

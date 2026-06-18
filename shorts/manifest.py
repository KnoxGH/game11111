from __future__ import annotations

import json
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any


@dataclass
class Manifest:
    idea: str
    script_path: Path
    audio_path: Path
    captions_path: Path
    video_path: Path
    thumbnail_path: Path | None
    title: str
    description: str
    tags: tuple[str, ...]
    duration_seconds: float | None = None
    video_id: str | None = None

    def save(self, path: Path) -> None:
        serializable = asdict(self)
        serializable["script_path"] = str(self.script_path)
        serializable["audio_path"] = str(self.audio_path)
        serializable["captions_path"] = str(self.captions_path)
        serializable["video_path"] = str(self.video_path)
        serializable["thumbnail_path"] = str(self.thumbnail_path) if self.thumbnail_path else None
        with path.open("w", encoding="utf-8") as file:
            json.dump(serializable, file, indent=2)

    @staticmethod
    def load(path: Path) -> "Manifest":
        with path.open("r", encoding="utf-8") as file:
            data: dict[str, Any] = json.load(file)
        return Manifest(
            idea=data["idea"],
            script_path=Path(data["script_path"]),
            audio_path=Path(data["audio_path"]),
            captions_path=Path(data["captions_path"]),
            video_path=Path(data["video_path"]),
            thumbnail_path=Path(data["thumbnail_path"]) if data.get("thumbnail_path") else None,
            title=data["title"],
            description=data["description"],
            tags=tuple(data.get("tags", [])),
            duration_seconds=data.get("duration_seconds"),
            video_id=data.get("video_id"),
        )

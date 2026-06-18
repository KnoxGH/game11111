from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw

from .config import RenderConfig


def ensure_ffmpeg() -> None:
    try:
        subprocess.run(["ffmpeg", "-version"], check=True, capture_output=True)
    except FileNotFoundError as exc:
        raise RuntimeError("ffmpeg is required to render videos but was not found on PATH.") from exc
    except subprocess.CalledProcessError as exc:
        raise RuntimeError("ffmpeg is installed but not usable in this environment.") from exc


def make_background(path: Path, width: int, height: int, background: str, accent: str) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    base = Image.new("RGB", (width, height), background)
    draw = ImageDraw.Draw(base)
    margin = width // 10
    overlay_height = height // 4
    draw.rectangle((margin, margin, width - margin, margin + overlay_height), outline=accent, width=8)
    draw.text((margin + 20, margin + 20), "Your Short", fill=accent)
    base.save(path)
    return path


def build_captions_srt(blocks: Iterable[tuple[int, int, str]], path: Path) -> Path:
    lines = []
    for index, (start, end, text) in enumerate(blocks, start=1):
        lines.append(str(index))
        lines.append(f"{_fmt_time(start)} --> {_fmt_time(end)}")
        lines.append(text)
        lines.append("")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")
    return path


def render_video(
    audio: Path,
    background: Path,
    captions: Path,
    output: Path,
    render_config: RenderConfig,
) -> Path:
    ensure_ffmpeg()
    output.parent.mkdir(parents=True, exist_ok=True)
    vf_filters = [
        f"scale={render_config.width}:{render_config.height}",
        "format=yuv420p",
        f"subtitles={captions.as_posix()}",
    ]
    cmd = [
        "ffmpeg",
        "-y",
        "-loop",
        "1",
        "-i",
        background.as_posix(),
        "-i",
        audio.as_posix(),
        "-shortest",
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
        "-b:v",
        render_config.bitrate,
        "-vf",
        ",".join(vf_filters),
        output.as_posix(),
    ]
    subprocess.run(cmd, check=True)
    return output


def _fmt_time(seconds: int) -> str:
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    secs = seconds % 60
    return f"{hours:02}:{minutes:02}:{secs:02},000"

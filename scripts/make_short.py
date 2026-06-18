from __future__ import annotations

import argparse
import datetime as dt
from pathlib import Path

from tqdm import tqdm

from shorts.config import AppConfig
from shorts.manifest import Manifest
from shorts.script import Script, draft_script
from shorts.tts import synthesize_voice
from shorts.upload import upload_video
from shorts.video import build_captions_srt, make_background, render_video


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate and upload an automated YouTube Short.")
    parser.add_argument("--idea", required=True, help="One-line idea or hook for the Short.")
    parser.add_argument("--out", default=None, help="Optional output directory.")
    parser.add_argument("--upload", action="store_true", help="Upload the rendered video to YouTube.")
    parser.add_argument("--thumbnail", default=None, help="Path to a custom thumbnail.")
    parser.add_argument("--privacy", default=None, help="Override privacy status for upload.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    config = AppConfig.load()
    idea = args.idea.strip()

    stamp = dt.datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    base_dir = Path(args.out or config.output_dir / f"short-{stamp}")
    base_dir.mkdir(parents=True, exist_ok=True)

    steps = [
        "Drafting script",
        "Synthesizing voice",
        "Building captions",
        "Rendering video",
    ]
    script: Script | None = None
    audio_path = base_dir / "voice.mp3"
    captions_path = base_dir / "captions.srt"
    background_path = base_dir / "background.png"
    video_path = base_dir / "short.mp4"
    for step in tqdm(steps, desc="Pipeline", unit="step"):
        if step == "Drafting script":
            script = draft_script(idea)
            (base_dir / "script.txt").write_text(script.to_text(), encoding="utf-8")
        elif step == "Synthesizing voice" and script:
            synthesize_voice(script.to_text(), audio_path, config.voice)
        elif step == "Building captions" and script:
            blocks = script.to_caption_blocks()
            build_captions_srt(blocks, captions_path)
        elif step == "Rendering video":
            make_background(
                background_path,
                config.render.width,
                config.render.height,
                config.render.background_color,
                config.render.accent_color,
            )
            render_video(audio_path, background_path, captions_path, video_path, config.render)

    assert script is not None
    manifest = Manifest(
        idea=idea,
        script_path=base_dir / "script.txt",
        audio_path=audio_path,
        captions_path=captions_path,
        video_path=video_path,
        thumbnail_path=Path(args.thumbnail) if args.thumbnail else None,
        title=script.title,
        description=f"{idea}\n\nMade with the automation pipeline.",
        tags=config.upload.default_tags,
    )
    manifest.save(base_dir / "manifest.json")

    if args.upload:
        video_id = upload_video(
            video_path=video_path,
            title=script.title,
            description=manifest.description,
            tags=manifest.tags,
            thumbnail_path=manifest.thumbnail_path,
            privacy=args.privacy or config.upload.default_privacy,
            category_id=config.upload.category_id,
            upload_config=config.upload,
        )
        manifest.video_id = video_id
        manifest.save(base_dir / "manifest.json")
        print(f"Uploaded video https://youtube.com/shorts/{video_id}")
    else:
        print(f"Short ready at {video_path}")


if __name__ == "__main__":
    main()

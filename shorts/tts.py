from __future__ import annotations

from pathlib import Path

from gtts import gTTS

from .config import VoiceConfig


def synthesize_voice(script_text: str, destination: Path, voice: VoiceConfig) -> Path:
    destination.parent.mkdir(parents=True, exist_ok=True)
    tts = gTTS(text=script_text, lang=voice.language)
    tts.save(destination.as_posix())
    return destination

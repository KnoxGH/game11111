# YouTube Shorts automation starter

This repo provides a minimal Python pipeline to generate and optionally upload YouTube Shorts end-to-end:

1. Draft a quick script from a one-line idea.
2. Synthesize a voiceover with gTTS.
3. Build simple captions and a branded background.
4. Render a vertical 1080×1920 MP4 with ffmpeg.
5. Upload to YouTube via the Data API (optional).

## Quick start

1. Install dependencies and ensure `ffmpeg` is on your `PATH`:
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   # install ffmpeg via your package manager (e.g., brew install ffmpeg or apt-get install ffmpeg)
   ```

2. (Optional) Add a `.env` for overrides:
   ```dotenv
   VOICE_LANGUAGE=en
   VIDEO_BG=#0d0d0f
   VIDEO_ACCENT=#ffd166
   YOUTUBE_CLIENT_SECRETS=client_secrets.json
   YOUTUBE_TOKEN_PATH=token.json
   YOUTUBE_DEFAULT_TAGS=shorts,automation
   ```

3. Generate a Short (renders to `output/short-<timestamp>/`):
   ```bash
   python scripts/make_short.py --idea "5 AI hacks for daily life"
   ```

4. Upload to YouTube (opens a browser for OAuth the first time):
   ```bash
   python scripts/make_short.py --idea "5 AI hacks for daily life" --upload
   ```

Artifacts include:
- `script.txt`, `captions.srt`, `voice.mp3`, `background.png`, `short.mp4`, `manifest.json`
- Optional `token.json` stores YouTube refresh tokens.

## Notes

- gTTS requires network access to synthesize speech.
- ffmpeg is required for rendering; install it before running the pipeline.
- The YouTube upload step needs a valid OAuth client secrets file set via `YOUTUBE_CLIENT_SECRETS`.

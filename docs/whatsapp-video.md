# whatsapp-video helper

`whatsapp-video` converts any input video into a WhatsApp-friendly MP4 so it can be shared without the app recompressing it into a blurry mess. The script lives in `config/.local/bin/whatsapp-video` as a first-class executable managed directly by chezmoi.

## Prerequisites

- `ffmpeg` and `ffprobe` must be available in `$PATH`. Install them through your package manager (`scripts/bootstrap` will handle this on supported hosts).

## Usage

```bash
whatsapp-video [--output PATH] [--max-size MB] INPUT
```

- `INPUT` (required) – source video file to convert.
- `--output PATH` – optional destination path. Defaults to `<INPUT>-whatsapp.mp4` alongside the source file.
- `--max-size MB` – approximate target size in megabytes (default `16`). WhatsApp’s hard limit is 16 MB for direct sends; lowering this can help when sending longer clips.

Example:

```bash
whatsapp-video --max-size 12 ~/Videos/presentation.mp4
```

The command prints the target bitrate budget and writes `~/Videos/presentation-whatsapp.mp4` (unless `--output` overrides it).

## Implementation notes

- Video is re-encoded to H.264 High Profile, level 4.0, with 30 FPS and 1280px max width to stay inside WhatsApp’s playback constraints.
- Audio is transcoded to AAC stereo at 96 kbps.
- The script calculates a video bitrate that keeps the file below the requested size, while keeping a floor of 120 kbps to avoid unwatchably low quality.
- Outputs are moved to fast-start MP4 so uploads begin immediately when shared.
- If `ffprobe` cannot read the input duration the script aborts to avoid guessing bitrates.

## Tips

- You can run `whatsapp-video` on already small clips to normalize them for WhatsApp without size reduction.
- For ultra-short clips (≤ 10 seconds) increase `--max-size` to bump quality if the default looks soft.
- If you need audio-only, use `ydp --audio` from `config/.local/bin/ydp` instead of this helper.

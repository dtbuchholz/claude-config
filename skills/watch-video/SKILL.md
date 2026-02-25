---
name: watch-video
description: >
  Extract frames from a local video file and view them as images. Use when the user shares a video
  file path, asks to review/watch/analyze a video, or wants to understand what happens in a video.
  Requires FFmpeg.
---

# Watch Video

Extract key frames from a video file so you can "see" what's in it.

## Procedure

### 1. Get video info

```bash
ffprobe -v error -show_entries format=duration,size -show_entries stream=width,height,r_frame_rate,codec_name -of json "$VIDEO_PATH"
```

Report: duration, resolution, codec. Use duration to decide frame count.

### 2. Choose extraction strategy

| Duration | Frames | Strategy                |
| -------- | ------ | ----------------------- |
| < 10s    | 4      | Evenly spaced           |
| 10–60s   | 6      | Evenly spaced           |
| 1–5 min  | 8      | 1 per ~30s + first/last |
| > 5 min  | 8      | Keyframes, capped       |

Never extract more than 8 frames. Each frame costs ~1,600–6,000 tokens.

### 3. Extract frames

```bash
# Create temp directory
TMPDIR=$(mktemp -d)

# Evenly spaced (most common — replace FPS with 1/interval)
ffmpeg -i "$VIDEO_PATH" -vf "fps=1/$INTERVAL" -frames:v $COUNT -q:v 2 "$TMPDIR/frame_%02d.jpg"

# Keyframes only (for long videos)
ffmpeg -i "$VIDEO_PATH" -vf "select='eq(pict_type,I)'" -vsync vfr -frames:v 8 -q:v 2 "$TMPDIR/frame_%02d.jpg"
```

### 4. View frames

Read each extracted frame using the Read tool. Describe what you see in each frame, noting
timestamps (frame number \* interval).

### 5. Clean up

```bash
rm -rf "$TMPDIR"
```

## Rules

- Always check the file exists and is a video before extracting.
- Cap at 8 frames. If the user needs more detail on a specific section, they can ask you to extract
  frames from a time range.
- Use `-q:v 2` for reasonable quality without huge file sizes.
- Clean up the temp directory after reading frames.
- If the user asks about a specific moment, extract a targeted frame:
  `ffmpeg -i "$VIDEO_PATH" -ss HH:MM:SS -frames:v 1 -q:v 2 frame.jpg`

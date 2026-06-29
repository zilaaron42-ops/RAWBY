# Per-theme background videos

Drop a looping background video here for each accent theme. The app
(`src/components/ui/ThemeBackground.tsx`) auto-uses the one matching the active
accent. Until a file exists, an animated gold-aurora fallback shows — nothing
breaks if a file is missing.

| File         | Theme   | Vibe                              |
|--------------|---------|-----------------------------------|
| `amber.mp4`  | Cinema  | golden black hole / nebula in space |
| `green.mp4`  | Pine    | nature — forest, fog, drone over trees |
| `azure.mp4`  | Azure   | ocean — underwater / waves        |
| `rose.mp4`   | Ember   | fire / embers, or a red-lit night city |

## Getting real footage (free, human-made — not AI)

Use any free, royalty-free stock site and download a short seamless **loop**:

- **Pexels Videos** — https://www.pexels.com/videos/ (free, no attribution)
- **Coverr** — https://coverr.co/ (free loops)
- **Mixkit** — https://mixkit.co/free-stock-video/ (free)

Search terms: "black hole", "nebula", "forest fog drone", "underwater ocean",
"fire embers", "neon city night".

## Specs (keep it light)

- 1080p (or 720p), H.264 `.mp4`, no audio.
- ~10–20s seamless loop, ideally **under ~6 MB** each so load stays fast.
- Darker / lower-contrast clips look best (a veil dims them anyway).

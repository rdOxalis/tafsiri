Drop phone screenshots here as 1.png, 2.png, 3.png … (sequential, no gaps).

F-Droid requirements:
- PNG or JPG, no transparency required
- Min 320 px, max 3840 px on each edge; aspect ratio between 1:2 and 2:1
- 2–8 screenshots recommended; the first one is the listing thumbnail
- Same filenames per locale; if a locale has none, F-Droid falls back to en-US

These live in the repo (not the APK), so adding them needs NO new tag/build —
F-Droid picks them up on the next metadata scan. Optional siblings in ../ :
  icon.png            (1024x1024 max; otherwise F-Droid extracts the launcher icon)
  featureGraphic.png  (1024x500)

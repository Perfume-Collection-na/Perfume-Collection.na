#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob

dirs=("image" "masculine" "feminine" "unisex")
QUALITY=80
MAX_DIM=800

if command -v magick >/dev/null 2>&1; then
  IM_CMD="magick"
elif command -v convert >/dev/null 2>&1; then
  IM_CMD="convert"
else
  IM_CMD=""
fi

echo "Image optimization script started"

for d in "${dirs[@]}"; do
  if [ -d "$d" ]; then
    echo "Scanning directory: $d"
    for img in "$d"/**/*.{jpg,JPG,jpeg,JPEG,png,PNG}; do
      [ -f "$img" ] || continue
      out="${img%.*}.webp"
      echo "Processing: $img -> $out"

      if [ -n "$IM_CMD" ]; then
        $IM_CMD "$img" -strip -resize ${MAX_DIM}x${MAX_DIM}\> -quality ${QUALITY} "$out"
      elif command -v cwebp >/dev/null 2>&1; then
        cwebp -q ${QUALITY} "$img" -o "$out"
      else
        echo "No image tools available (ImageMagick or cwebp). Skipping $img"
        continue
      fi
    done
  else
    echo "Directory not found: $d - skipping"
  fi
done

git add --all "**/*.webp" || true

if ! git diff --cached --quiet; then
  git config user.name "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git commit -m "chore(images): generate optimized WebP versions"
  git push
else
  echo "No WebP changes to commit"
fi

echo "Image optimization script finished"

#!/usr/bin/env bash
# image-shrink: 大图 → ≤2000px JPEG 小副本（macOS 用系统自带 sips；Linux 用 magick/ffmpeg）
# 用法: bash shrink.sh <原图> [maxDim=2000] [quality=85]
set -euo pipefail
src="${1:?用法: shrink.sh <原图> [maxDim] [quality]}"
max="${2:-2000}"; q="${3:-85}"
[ -f "$src" ] || { echo "文件不存在: $src" >&2; exit 2; }
dir="$(dirname "$src")"; base="$(basename "$src")"; stem="${base%.*}"
out="$dir/$stem.small.jpg"

if command -v sips >/dev/null 2>&1; then
  # macOS：先按长边缩，再转 JPEG
  tmp="$dir/.$stem.small.tmp"
  cp -f "$src" "$tmp"
  w=$(sips -g pixelWidth "$tmp" | awk '/pixelWidth/{print $2}')
  h=$(sips -g pixelHeight "$tmp" | awk '/pixelHeight/{print $2}')
  if [ "$w" -gt "$max" ] || [ "$h" -gt "$max" ]; then sips -Z "$max" "$tmp" >/dev/null; fi
  sips -s format jpeg -s formatOptions "$q" "$tmp" --out "$out" >/dev/null
  rm -f "$tmp"
elif command -v magick >/dev/null 2>&1; then
  magick "$src" -background white -alpha remove -resize "${max}x${max}>" -quality "$q" "$out"
elif command -v ffmpeg >/dev/null 2>&1; then
  ffmpeg -y -loglevel error -i "$src" -vf "scale=min(${max}\\,iw):-2:flags=lanczos" -q:v 3 "$out"
else
  echo "无可用图像工具（sips / magick / ffmpeg）" >&2; exit 3
fi

osize=$(stat -f%z "$src" 2>/dev/null || stat -c%s "$src")
nsize=$(stat -f%z "$out" 2>/dev/null || stat -c%s "$out")
if [ "$nsize" -ge "$osize" ]; then
  rm -f "$out"
  echo "SKIP 压不小，保留原图: $src ($osize bytes)"
  exit 0
fi
echo "OK $out"
echo "   $src ($osize bytes) -> $(basename "$out") ($nsize bytes)"

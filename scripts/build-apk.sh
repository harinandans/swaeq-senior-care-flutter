#!/usr/bin/env bash
# Build release APK with Docker (linux/amd64 — use AWS x86 / CodeBuild).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/build-output"
IMAGE_TAG="${IMAGE_TAG:-swaeq-senior-apk:local}"
API_BASE_URL="${API_BASE_URL:-https://5on0mm6m5d.execute-api.ap-south-1.amazonaws.com}"

mkdir -p "$OUT_DIR"

echo "==> docker build (linux/amd64) API_BASE_URL=$API_BASE_URL"
docker build --platform linux/amd64 \
  --build-arg "API_BASE_URL=$API_BASE_URL" \
  -t "$IMAGE_TAG" "$ROOT"

echo "==> Extracting APK…"
docker run --rm --platform linux/amd64 \
  -v "$OUT_DIR:/host" \
  "$IMAGE_TAG" \
  cp /out/swaeq-senior.apk /host/swaeq-senior.apk

echo ""
echo "APK ready: $OUT_DIR/swaeq-senior.apk"
ls -lh "$OUT_DIR/swaeq-senior.apk"

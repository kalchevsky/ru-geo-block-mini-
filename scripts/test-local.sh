#!/usr/bin/env bash
# Быстрая локальная проверка сборки без установки geoview:
# качает geoview, собирает файлы и печатает размеры.
set -euo pipefail
cd "$(dirname "$0")/.."

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if ! command -v geoview >/dev/null 2>&1; then
  echo ">> geoview не найден, скачиваю..."
  for asset in geoview-linux-amd64 geoview-linux-arm64; do
    if curl -fsSL --retry 2 -o "$WORK/geoview" \
        "https://github.com/snowie2000/geoview/releases/latest/download/${asset}"; then
      chmod +x "$WORK/geoview"
      GEOVIEW="$WORK/geoview"
      break
    fi
  done
fi
GEOVIEW="${GEOVIEW:-geoview}"

"$GEOVIEW" -version || true
GEOVIEW="$GEOVIEW" ./scripts/build.sh
echo
echo "=== out/ ==="
ls -la out/

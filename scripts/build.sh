#!/usr/bin/env bash
# Собирает мини-версии geoip.dat и geosite.dat из списков категорий в config/.
# Требует: geoview в $GEOVIEW (или в PATH), curl, sha256sum.
set -euo pipefail

GEOVIEW="${GEOVIEW:-geoview}"
GEOSITE_SRC="${GEOSITE_SRC:-https://raw.githubusercontent.com/runetfreedom/russia-blocked-geosite/release/geosite.dat}"
GEOIP_SRC="${GEOIP_SRC:-https://raw.githubusercontent.com/runetfreedom/russia-blocked-geoip/release/geoip.dat}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/out"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$OUT"

# Читает файл-список, убирает комментарии/пустые строки, склеивает через запятую
read_list() {
  local file="$1"
  [ -f "$file" ] || { echo ""; return; }
  sed -e 's/#.*$//' -e 's/[[:space:]]//g' "$file" | grep -v '^$' | awk 'BEGIN{s=""} {s = (s=="" ? $0 : s "," $0)} END{print s}'
}

# Проверяем, что все запрошенные категории существуют в источнике (strict-режим geoview).
# Если хоть одной нет — падаем, а не собираем молча неполный файл.
build_one() {
  local type="$1" src="$2" listfile="$3" outname="$4"
  local list; list="$(read_list "$listfile")"

  if [ -z "$list" ]; then
    echo "!! $listfile пуст — пропускаю $outname"
    return 0
  fi

  echo ">> $outname"
  echo "   категории: $list"

  curl -fsSL --retry 3 -o "$WORK/src.dat" "$src"

  set +e
  "$GEOVIEW" -action=convert -type="$type" -format="$type" \
    -input="$WORK/src.dat" -list="$list" -output="$WORK/out.dat" -lowmem
  local rc=$?
  set -e
  if [ $rc -ne 0 ]; then
    echo "!! geoview вернул ошибку $rc для $outname (проверьте имена категорий)"
    exit 1
  fi

  # Санити-проверка: protobuf начинается с 0x0A (field 1, wire type 2).
  # Если geoview выдал plain-text список доменов, первый байт будет ASCII.
  local first_byte
  first_byte="$(head -c1 "$WORK/out.dat" | od -An -tu1 | tr -d ' \n')"
  if [ "$first_byte" != "10" ]; then
    echo "!! $outname не похож на .dat (первый байт=$first_byte, ожидался 10)"
    exit 1
  fi

  cp "$WORK/out.dat" "$OUT/$outname"
  ( cd "$OUT" && sha256sum "$outname" > "$outname.sha256sum" )
  local sz
  sz="$(stat -c%s "$OUT/$outname" 2>/dev/null || wc -c < "$OUT/$outname")"
  echo "   готово: ${sz} байт"
}

build_one geosite "$GEOSITE_SRC" "$ROOT/config/geosite.list" geosite.dat
build_one geoip   "$GEOIP_SRC"   "$ROOT/config/geoip.list"   geoip.dat

echo "Сборка завершена."

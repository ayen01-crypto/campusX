#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

missing=false
for platform in android ios web; do
  if [[ ! -d "$platform" ]]; then
    missing=true
  fi
done

if [[ "$missing" == true ]]; then
  tmpdir="$(mktemp -d)"
  flutter create \
    --org com.campusx \
    --project-name campusx \
    --platforms=android,ios,web \
    "$tmpdir/campusx"

  for platform in android ios web; do
    if [[ ! -d "$ROOT/$platform" ]]; then
      cp -R "$tmpdir/campusx/$platform" "$ROOT/$platform"
    fi
  done

  rm -rf "$tmpdir"
fi

flutter pub get

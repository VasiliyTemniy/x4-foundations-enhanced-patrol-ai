#!/usr/bin/env bash
set -euo pipefail

MOD="vas_enhanced_patrol_ai"
ROOT="$(cd "$(dirname "$0")" && pwd)"
PKG="$ROOT/packages/$MOD"
TS="$(date +%d-%m-%Y_%H%M%S)"
ZIP="$ROOT/packages/${MOD}_${TS}.zip"

rm -rf "$PKG"
mkdir -p "$PKG"

cp -a "$ROOT/src/." "$PKG/"

# This is the only mod in my collection that has to have license included
# because it's based on HappyStation mod which is MIT-licensed
cp    "$ROOT/LICENSE"      "$PKG/LICENSE"

(cd "$ROOT/packages" && zip -r -9 "$ZIP" "$MOD")

echo "Packed: $ZIP"

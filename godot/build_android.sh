#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_PROJECT="$ROOT_DIR/godot"
OUTPUT_APK="$ROOT_DIR/RESET-NIGHT-GODOT.apk"
GODOT_BIN="${GODOT_BIN:-godot}"
ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
KEYSTORE="$GODOT_PROJECT/resetnight-debug.keystore"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "ERROR: Godot 4 executable not found. Install Godot 4.3+." >&2
  exit 2
fi
if [[ -z "$ANDROID_HOME" || ! -d "$ANDROID_HOME" ]]; then
  echo "ERROR: ANDROID_HOME or ANDROID_SDK_ROOT is missing/invalid." >&2
  exit 2
fi
if [[ ! -f "$GODOT_PROJECT/project.godot" ]]; then
  echo "ERROR: Godot project.godot is missing." >&2
  exit 2
fi
if [[ ! -s "$KEYSTORE" ]]; then
  echo "ERROR: Stable RESET NIGHT debug signing key is missing." >&2
  exit 2
fi
if ! command -v keytool >/dev/null 2>&1; then
  echo "ERROR: JDK keytool is required." >&2
  exit 2
fi

# Fail early if the persistent signing identity is unreadable.
keytool -list -keystore "$KEYSTORE" -storetype PKCS12 \
  -storepass resetnight-ci-debug -alias resetnightdebug >/dev/null

"$GODOT_BIN" --version
"$GODOT_BIN" --headless --editor --path "$GODOT_PROJECT" --import
"$GODOT_BIN" --headless --path "$GODOT_PROJECT" --export-debug "Android" "$OUTPUT_APK"
test -s "$OUTPUT_APK"

APKSIGNER="$(find "$ANDROID_HOME/build-tools" -type f -name apksigner | sort -V | tail -n 1)"
if [[ -z "$APKSIGNER" ]]; then
  echo "ERROR: Android build-tools apksigner was not found." >&2
  exit 2
fi
"$APKSIGNER" verify --verbose "$OUTPUT_APK"
"$APKSIGNER" verify --print-certs "$OUTPUT_APK" | grep -E "Signer #1 certificate SHA-256 digest|Signer #1 certificate DN"
echo "APK created and signature verified: $OUTPUT_APK"

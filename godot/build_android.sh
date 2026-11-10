#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_PROJECT="$ROOT_DIR/godot"
OUTPUT_APK="$ROOT_DIR/RESET-NIGHT-GODOT.apk"
GODOT_BIN="${GODOT_BIN:-godot}"
ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "ERROR: Godot 4 executable not found. Set GODOT_BIN or install Godot 4.3+." >&2
  exit 2
fi
if [[ -z "$ANDROID_HOME" ]]; then
  echo "ERROR: ANDROID_HOME or ANDROID_SDK_ROOT is not set." >&2
  exit 2
fi
if [[ ! -f "$GODOT_PROJECT/project.godot" ]]; then
  echo "ERROR: Godot project.godot is missing." >&2
  exit 2
fi

mkdir -p "$HOME/.android"
if [[ ! -f "$HOME/.android/debug.keystore" ]]; then
  keytool -genkeypair -v -keystore "$HOME/.android/debug.keystore" -storepass android \
    -alias androiddebugkey -keypass android \
    -dname "CN=Android Debug,O=Android,C=US" -keyalg RSA -keysize 2048 -validity 10000
fi

sed "s|__DEBUG_KEYSTORE__|$HOME/.android/debug.keystore|g" \
  "$GODOT_PROJECT/export_presets.cfg" > "$GODOT_PROJECT/export_presets.ci.cfg"
cp "$GODOT_PROJECT/export_presets.ci.cfg" "$GODOT_PROJECT/export_presets.cfg"
rm "$GODOT_PROJECT/export_presets.ci.cfg"

"$GODOT_BIN" --version
"$GODOT_BIN" --headless --editor --path "$GODOT_PROJECT" --import
"$GODOT_BIN" --headless --path "$GODOT_PROJECT" --export-debug "Android" "$OUTPUT_APK"
test -s "$OUTPUT_APK"
echo "APK created: $OUTPUT_APK"

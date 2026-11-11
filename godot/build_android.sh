#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_PROJECT="$ROOT_DIR/godot"
OUTPUT_APK="$ROOT_DIR/RESET-NIGHT-GODOT.apk"
GODOT_BIN="${GODOT_BIN:-godot}"
ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
KEYSTORE="$GODOT_PROJECT/resetnight-debug.keystore"

command -v "$GODOT_BIN" >/dev/null || { echo "Godot 4 executable missing" >&2; exit 2; }
command -v java >/dev/null || { echo "Java SDK missing" >&2; exit 2; }
command -v keytool >/dev/null || { echo "JDK keytool missing" >&2; exit 2; }
[[ -n "$ANDROID_HOME" && -d "$ANDROID_HOME" ]] || { echo "ANDROID_HOME invalid: $ANDROID_HOME" >&2; exit 2; }
[[ -s "$KEYSTORE" ]] || { echo "Stable debug keystore missing: $KEYSTORE" >&2; exit 2; }

keytool -list -keystore "$KEYSTORE" -storetype PKCS12 -storepass resetnight-ci-debug -alias resetnightdebug >/dev/null

GODOT_VERSION="$("$GODOT_BIN" --version)"
echo "Godot: $GODOT_VERSION"
VERSION_DIR="$(echo "$GODOT_VERSION" | sed 's/\.official.*//')"
TEMPLATE_DIR="$HOME/.local/share/godot/export_templates/$VERSION_DIR"
mkdir -p "$TEMPLATE_DIR"
if [[ ! -s "$TEMPLATE_DIR/android_debug.apk" || ! -s "$TEMPLATE_DIR/android_release.apk" ]]; then
  TEMPLATE_ZIP="$RUNNER_TEMP/godot-templates.tpz"
  python3 -c 'import urllib.request,sys; urllib.request.urlretrieve("https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz", sys.argv[1])' "$TEMPLATE_ZIP"
  unzip -oq "$TEMPLATE_ZIP" -d "$RUNNER_TEMP/godot-templates"
  mkdir -p "$TEMPLATE_DIR"
  cp "$RUNNER_TEMP/godot-templates/templates/"* "$TEMPLATE_DIR/"
fi

CONFIG_DIR="$HOME/.config/godot"
mkdir -p "$CONFIG_DIR"
JAVA_HOME_PATH="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"
cat > "$CONFIG_DIR/editor_settings-4.tres" <<EOF
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "$ANDROID_HOME"
export/android/java_sdk_path = "$JAVA_HOME_PATH"
export/android/debug_keystore = "$KEYSTORE"
export/android/debug_keystore_user = "resetnightdebug"
export/android/debug_keystore_pass = "resetnight-ci-debug"
EOF

export ANDROID_HOME ANDROID_SDK_ROOT="$ANDROID_HOME" JAVA_HOME="$JAVA_HOME_PATH"
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$KEYSTORE"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="resetnightdebug"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="resetnight-ci-debug"

"$GODOT_BIN" --headless --editor --path "$GODOT_PROJECT" --import
"$GODOT_BIN" --headless --editor --path "$GODOT_PROJECT" --quit --verbose
"$GODOT_BIN" --headless --path "$GODOT_PROJECT" --export-debug "Android" "$OUTPUT_APK" --verbose
test -s "$OUTPUT_APK"

APKSIGNER="$(find "$ANDROID_HOME/build-tools" -type f -name apksigner | sort -V | tail -n 1)"
[[ -n "$APKSIGNER" ]] || { echo "apksigner missing from $ANDROID_HOME/build-tools" >&2; exit 2; }
"$APKSIGNER" verify --verbose "$OUTPUT_APK"
"$APKSIGNER" verify --print-certs "$OUTPUT_APK"
echo "APK_PACKAGE=com.fatihkoc.resetnight.godot3d"
echo "APK_VERSION=1.4.9 (14)"
echo "APK_PATH=$OUTPUT_APK"

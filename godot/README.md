# RESET NIGHT — Godot 4 3D Comic Survival

## Android package and update compatibility

- Android application ID: `com.fatihkoc.resetnight`
- Version: `1.4.1` (version code 6)
- The Android ID is intentionally distinct from the earlier test package `com.resetnight.game`, preventing Android from treating this build as an update to a differently signed package.
- A persistent **debug-only** PKCS#12 key is stored at `godot/resetnight-debug.keystore`. CI and local exports use this same key, so future test APKs keep the same signing identity.
- This is a development/test signing key, not a production release key. Do not publish a store release signed with it.

The first installation of this new package appears as a separate app from any older `com.resetnight.game` test installation. Once installed, later APKs built from this repository can update it without changing the signing identity. The older installation is not removed and its local data is not touched.

## Run and export
Open `godot/project.godot` in Godot 4.3+. For Android export, install the Android SDK, JDK and matching Godot export templates, then run:

```bash
cd godot
./build_android.sh
```

The script imports resources, exports the Android APK and verifies its signature with Android build-tools.

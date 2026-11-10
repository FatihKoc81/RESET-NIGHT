# RESET NIGHT — Godot foundation

This is the beginning of the Godot 4 migration. The existing HTML prototype remains untouched on the `main` branch.

## Current foundation
- Godot 4 project configured for Android-friendly GL Compatibility rendering.
- Main menu scaffold with dark industrial styling and a logo asset slot.
- Basic survival scene: movement, chasing enemies, health, timer, melee range and win/lose state.
- The official logo is copied into `godot/assets/reset_night_logo.jpg` by the Godot build workflow when that workflow is added.

## Controls
- WASD / arrow keys: move
- Space: melee attack

## Next integration tasks
1. Replace placeholder UI with the approved Gemini menu and HUD assets.
2. Add touch joystick and action buttons.
3. Import final character, enemy, environment, weapon and audio assets.
4. Implement combat, inventory, pickups, progression and save data.
5. Configure Android export signing and build a test APK.

The current scene is a technical foundation, not a finished game.
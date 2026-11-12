# RESET NIGHT — Gemini Project Lead Instructions

You are the primary project lead and implementation agent for this repository. The owner works from an Android phone and should not be asked to perform routine coding, terminal, build, or Git operations.

## Authority and collaboration
- Inspect the repository before changing it. Treat the current source as authoritative; do not assume prior chat descriptions match the code.
- You may implement, test, and commit changes on a dedicated feature branch. Do not push directly to `main` for substantial changes. Open a pull request with a concise summary and test evidence.
- Never claim a feature, device test, or build is complete unless it has actually been verified. Clearly distinguish static inspection, automated tests, successful APK export, and real-device testing.
- Preserve existing working features. Make small, reviewable changes and explain risks before destructive migrations.
- The owner uses Android only. Avoid asking them to paste large code blocks or run complex commands. Provide one simple action at a time only when genuinely necessary.

## Product vision — non-negotiable
RESET NIGHT is a 3D action/survival game with TWO playable factions. It is not a zombie game.

### Factions
1. DEFENSE (SAVUNMA): protect safe zones, build/repair barricades, gather supplies, hold checkpoints, defend civilians/survivors against human attackers.
2. ATTACK (SALDIRI): play as a ruthless, violent human raider gang. Attackers are ordinary human beings—psychopathic, bloodthirsty hostile groups—not zombies, undead, infected, monsters, or supernatural creatures.

The player chooses a faction before entering a game mode. The two factions must eventually have genuinely different objectives, equipment, missions, and gameplay loops. Do not merely change menu labels while both sides play identically.

### Modes and naming
- Use “SOLO”, “EKİP” (not “Co-op”), and “HİKÂYE & GÖREV”.
- “EKİP” is the Turkish user-facing name for 2–4 player cooperative play.
- Main flow: RESET NIGHT → choose faction (SAVUNMA / SALDIRI) → choose mode → character/loadout → gameplay.

## Quality requirements
- No zombie visuals, zombie names, bite attacks, undead lore, or zombie spawners. Replace hostile NPCs with believable human raiders, and add human defender NPCs where appropriate.
- The app icon and in-game title logo must remain visible and correct. Never replace the logo with a blank/black icon or generic text fallback without explicitly explaining and validating it.
- The playable game must have visible player characters, visible human opponents/allies, a coherent 3D environment, usable camera, animations, collision, and functioning combat. A successful APK export alone is not proof the game is playable.
- Prioritize a complete, coherent playable vertical slice over cosmetic version bumps: one map, one faction-vs-faction objective loop, functional movement/camera/combat, and clear win/loss conditions.
- Mobile-first landscape UI: no overlapping panels, no controls hidden under panels, touch-friendly buttons, correct Android back behavior, and sensible scaling across aspect ratios.
- Keep performance appropriate for Android devices. Use real model assets or intentionally designed, readable low-poly art; avoid primitive placeholder blocks as final art.

## Required workflow for each task
1. Audit relevant scenes, scripts, assets, project settings, and recent GitHub Actions runs.
2. State the root cause and a short plan before broad refactors.
3. Implement on a feature branch.
4. Run available Godot headless parse/import/scene validation and project tests. Fix all errors.
5. Run Android export through the repository workflow where available.
6. Report exact commit/branch, changed files, tests run, APK artifact/release link, and any unverified items.
7. Do not ask the owner to install a build until the relevant workflow succeeds. For real-device checks, provide a short focused checklist and wait for evidence.

## First assignment
Perform a full audit of the current repository and report:
- Why the current Android build opens to an incomplete/black/primitive scene or lacks visible characters/environment.
- Whether the main menu, faction selection, enemy spawning, player scene, map scene, logo/icon, and Android export are wired correctly.
- Every remaining zombie reference and whether it is active, dead code, asset, or documentation.
- The actual status of faction-specific gameplay and EKİP mode.
- The smallest safe plan to produce a genuinely playable, visually coherent first release.

Do not start by bumping the version number. Audit first, then fix the highest-impact blocker and prove it with tests.

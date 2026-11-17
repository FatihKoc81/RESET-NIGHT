# RESET NIGHT — Claude Code Primary Developer (Direct Main Workflow)

You are the primary developer and implementation owner of RESET NIGHT. The repository owner explicitly authorizes direct commits to the default `main` branch and does not want routine pull-request approval gates.

## Required delivery workflow
- Work directly on the checked-out `main` branch. Do not create feature branches or pull requests for ordinary implementation tasks.
- Commit each coherent, tested implementation increment to `main` with a clear commit message and push it to GitHub.
- Keep changes scoped. Do not combine unrelated features in one large change.
- The `.github/workflows/godot-android.yml` workflow builds and publishes the Android APK when files under `godot/**` change on `main`.
- Ensure each completed gameplay/source change is pushed under `godot/**` so the APK workflow is triggered when appropriate. Do not make artificial source changes just to trigger a build.
- Inspect the APK workflow result and release/artifact output. Report a verified download URL only when the build and upload actually succeeded.
- If the APK build fails, inspect logs, fix the cause in a separate commit, push again, and verify the next build.
- Do not endlessly retry or spend unbounded API/build budget. If blocked after focused attempts, report the exact blocker and stop.

## Quality and safety
- Run Godot 4 headless import, script parsing, and scene validation before each commit where feasible.
- Preserve working scenes, scripts, assets, input, UI, save data, and Android export configuration.
- Never commit API keys, signing secrets, private credentials, or personal data.
- Never delete or rewrite large areas without first proving the change is necessary.
- Do not claim real Android device testing unless it was actually performed.
- Distinguish successful Godot validation, successful APK export, APK installation, and real-device gameplay as separate verification levels.
- Keep mobile-first controls and performance.
- Gemini is your technical assistant for research, debugging, test design, and review. You remain responsible for implementation and final decisions.
- GPT-6 coordinates priorities and independently reviews results.

## RESET NIGHT product requirements
- Godot 4, true 3D action/survival game; not a zombie game.
- Preserve SAVUNMA and SALDIRI factions and SOLO, EKİP, HİKÂYE & GÖREV modes.
- Enemies are human attackers, not zombies, undead, infected, monsters, or supernatural creatures.
- Build genuinely playable systems, not visual placeholders.

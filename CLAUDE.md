# CLAUDE.md

Rules and workflow for working on **Arma 3 Radio Stations** (by Rowantrek), a CBA_A3 Arma 3 mod that gives every vehicle, and a placeable object, a synced music radio.

## Where things are documented

| Where | What |
|---|---|
| **CLAUDE.md** (this file) | Rules, workflow and pointers only. **Keep it short.** Don't add technical explanations here. They go in ARCHITECTURE.md. |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | How the mod works and why. Enough to understand the design, no more. |
| **Code and code comments** | The details, and the source of truth. Read the functions involved before changing them, and keep comments short, explaining *why*. |
| **[README.md](README.md)** | The user manual for players, mission makers, server owners and music add-on makers. |

When you change behaviour, update the README for anything user-facing and ARCHITECTURE.md for design changes.

## Repository layout

```
Arma3RadioStations/            The mod (HEMTT project, prefix "a3r", mainprefix "z")
  addons/main/                 a3r_main.pbo: logic, settings, keybinds, placeable radio, logo (data/)
  addons/stations/             a3r_stations.pbo: built-in stations + .ogg audio (generated)
  .hemtt/missions/a3r_test.VR  Test mission for `hemtt launch`
AddonTemplate/                 Example music add-on (HEMTT project) for others to copy
tools/                         import_music.ps1, bump_version.ps1, make_demo_audio.sh
```

## Build and verify

```sh
cd Arma3RadioStations && hemtt build    # compiles and lints SQF and config; fails on errors
cd AddonTemplate && hemtt check
```

- There are no automated tests. **Only the user can test in game.** After a change, run `hemtt build`, report any warnings, and list what to check in game, including multiplayer when sync is involved.
- HEMTT and ffmpeg are installed on this machine. `warning[BBW1]: Arma 3 Tools not found` is harmless.
- `.hemttout/` and `releases/` are git-ignored. Never commit `*.biprivatekey` / `.hemttprivatekey`.

## Deliberate decisions: keep them

ARCHITECTURE.md explains the reasons.

- Every radio plays on the **effects channel**. Never use `playMusic`.
- **Vehicles use keybinds only, and placed radios use the scroll menu only.**
- **One volume knob per radio** affects occupants and everyone outside alike. Placed radios always sound like a PA.
- Network state stays minimal and server-authoritative. Don't add per-frame network traffic, `remoteExec` audio or server-side loops.
- Changing a default key needs a **new keybind id**, because CBA keeps saved bindings.
- Don't rename the `a3r_stations` CfgPatches class.

## Conventions

- **Naming:** functions `A3R_fnc_<name>`, in `functions/fn_<name>.sqf` and listed alphabetically in `CfgFunctions` in `addons/main/config.cpp`. Variables and CBA events `a3r_*`. Config classes `A3R_*`.
- **Function header:** a `/* */` block with purpose, `Arguments:` and `Return:`, then `params`.
- **SQF style:**
  - 4-space indents and `private` locals.
  - Lazy `&& {}` conditions and `exitWith` early returns.
  - `getVariable [name, default]`, and `findIf` / `select` / `apply` instead of manual loops.
- **Public API** (keep backwards compatible, documented in the README):
  - functions `A3R_fnc_setStation`, `setVolume`, `getStations` and `getTrackAt`;
  - object variables `a3r_hasRadio`, `a3r_isRadio`, `a3r_station`, `a3r_volume` and `a3r_pa`;
  - config properties `a3r_hasRadio` and `a3r_isRadio`;
  - the `A3R_Stations` schema and the `<track>_PA` convention;
  - `A3R_Radio_FM` and the setting names.
- `requiredVersion = 2.18`: use only commands available in Arma 2.18.
- Line endings follow `.gitattributes`.

## Generated files and music

- `cfgSounds.hpp`, `cfgMusic.hpp`, `stations.hpp` and `data/*.ogg` in `addons/stations`, the test mission's `radio/` folder and `AddonTemplate/addons/main` are written by `import_music.ps1`. Change the music or the script, not these files.
- **The built-in stations are real music the user added.** Don't replace or re-import them unless asked, and never import `demo_music/builtin` over them.
- Don't add music unless the user confirms they have the rights to distribute it.

## Releasing

- **Version:** `YYYY.MM.DD.N`, set with `powershell -ExecutionPolicy Bypass -File tools\bump_version.ps1`. Don't edit the numbers by hand.
- **Padding:** the month and day must stay two digits, because CfgPatches `version` is a decimal number.
- **Build:** `hemtt release`. The user publishes to the Workshop with Arma 3 Publisher.

## Commits and pull requests

- **When:** commit, push or open a PR only when the user asks. Work on a short kebab-case branch, not `main`.
- **Detail:** messages should be detailed enough that someone reading `git log` a year from now understands what changed for players, and why, without opening the diff.
- **Scope:** one logical change per commit where possible. If changes are intertwined in the same files, make one commit with a section per change.
- **Subject:** imperative, ≤ 72 characters, describing the effect on the mod, not the files.
- **Body:** wrapped at about 72 columns, covering:
  - what changed and why, including rejected alternatives when the choice wasn't obvious;
  - user-facing changes (keys, defaults, settings, API);
  - **Compatibility** (API, settings, keybind ids, station config, network variables);
  - **Verified**: what was actually run, and what still needs in-game or multiplayer testing.

  Never imply in-game testing that didn't happen. See `git log` for examples.
- **PR description** (`gh pr create` against `main`): Summary, Changes, Player / mission maker / server owner impact, Compatibility, Testing (checkboxes, ticked only for what was actually done; in-game boxes only if the user confirms), Docs.
- **Attribution:** end commit messages and PR descriptions with the attribution lines the session provides.

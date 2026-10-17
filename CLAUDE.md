# CLAUDE.md

Context for working on **Arma 3 Radio Stations** (by Rowantrek): a CBA_A3-based Arma 3 mod that gives every vehicle, and a placeable object, a music radio. Stations are "live": every machine works out the current track from the synced mission clock, so only the chosen station goes over the network.

`README.md` is the user-facing manual (players, mission makers, server owners, music add-on makers). This file covers what you need to change the code safely. **When you change behaviour, settings, keybinds, function signatures or the import tool, update the README to match.**

## Repository layout

```
Arma3RadioStations/            The mod itself (HEMTT project, prefix "a3r", mainprefix "z")
  addons/main/                 a3r_main.pbo: all logic, settings, keybinds, placeable radio
    config.cpp                 CfgPatches, XEH hooks, CfgFunctions, A3R_Radio_FM object, empty A3R_Stations root
    XEH_preInit.sqf            caches, CBA settings, server event handler, keybinds
    XEH_postInit.sqf           client-only: starts the 0.5 s loop, adds placed-radio scroll actions
    functions/fn_*.sqf         A3R_fnc_* functions (see below)
    script_version.hpp         Version YYYY.MM.DD.N (see Releasing)
    data/Arma3RadioStations.paa  Mod logo (512×512), used by mod.cpp picture/logo/logoOver/logoSmall
  addons/stations/             a3r_stations.pbo: built-in stations + .ogg audio (generated)
  .hemtt/missions/a3r_test.VR  Test mission opened by `hemtt launch`: mission station, placed radio, vehicles
AddonTemplate/                 Separate HEMTT project (prefix "a3r_mymusic"): example music add-on for others to copy
tools/import_music.ps1         Converts music folders to .ogg and writes the three station .hpp files
tools/bump_version.ps1         Sets script_version.hpp to today's date, N+1 if already today
tools/make_demo_audio.sh       Synthesizes the placeholder demo tracks with ffmpeg (POSIX sh, LF line endings)
```

## Build and verify

There are no automated tests. Verification is HEMTT's build-time checks plus in-game testing, which only the user can do.

```sh
cd Arma3RadioStations && hemtt build    # rapifies configs, compiles/lints SQF; fails on errors
cd AddonTemplate && hemtt check          # template only has config, no SQF
hemtt launch                             # (user) Arma + CBA + test mission in Eden
hemtt release                            # (user) signed build in releases/
```

- HEMTT 1.22 and ffmpeg are installed on this machine. `warning[BBW1]: Arma 3 Tools not found` is expected and harmless (no models/textures).
- Always run `hemtt build` after editing SQF or config, and report any warnings. Then tell the user what to test in game, ideally in multiplayer too (a local hosted server + a second client) for anything touching sync or networking.
- Output goes to `.hemttout/` and `releases/`, both git-ignored. Never commit `*.biprivatekey` / `.hemttprivatekey`.

## How it works

### Data model (all config)

A station is a class under `A3R_Stations` with `displayName` and `tracks[]`. Each track class name must exist in **both**:
- `CfgSounds` (used by `say3D` for everything heard from outside; its volume, the 2nd `sound[]` element, is the **only** way to set that loudness) and
- `CfgMusic`, whose `duration` drives the schedule and whose `name` is the title shown. Its `sound[]` isn't played any more, but keep it so add-ons stay valid music configs.

Tracks missing from either, or with `duration <= 0`, are silently dropped; a station with no valid tracks is hidden. Durations must match the real audio length, or tracks get cut off or leave silence, which is why the import tool measures them with ffprobe.

Three station sources, all read via `A3R_fnc_findConfig` (mission's `missionConfigFile` first, then `configFile`):

| Source | Where | How it's identified |
|---|---|---|
| Mission | `description.ext` → `A3R_Stations` | `missionConfigFile` |
| Built-in | `addons/stations` | `"a3r_stations" in configSourceAddonList` |
| Add-on | any other mod's `A3R_Stations` | everything else in `configFile` |

Don't rename the `a3r_stations` CfgPatches class: the built-in/add-on split depends on it. Add-on mods must have `requiredAddons[] = {"a3r_main"}`.

Sound paths: addons use absolute `\z\<prefix>\addons\<addon>\data\file.ogg`; missions use paths relative to the mission root (`radio\file.ogg`).

### Networking (keep it minimal)

- The only replicated state is:
  - per radio, `a3r_station` (station class or `""`), `a3r_volume` (knob 0–1, unset = 0.5), `a3r_lastStation` (set when turned off) and, for vehicles, `a3r_pa` (bool, unset = false);
  - `a3r_radios`, a public `missionNamespace` array of radios that are on.
  JIP works through these public variables.
- Playback gain is `2 * a3r_volume`, so the 0.5 default is the sound file's normal loudness and 1 is double. This real volume only applies inside a vehicle (`playSoundUI`, capped at 5). Outside, the gain scales range.
- Any machine calls `A3R_fnc_setStation` / `A3R_fnc_setVolume` / `A3R_fnc_togglePA`, which send the CBA server events `a3r_setStation` / `a3r_setVolume` / `a3r_setPA` to `A3R_fnc_serverSetStation` / `A3R_fnc_serverSetVolume` / `A3R_fnc_serverSetPA`. Only the server broadcasts those variables; it validates stations against `A3R_fnc_getStations` and clamps volume. (`setVolume` and `togglePA` also set their variable locally, unbroadcast, so fast repeated presses work before the server's update arrives.)
- `serverSetStation` defers with `CBA_fnc_waitUntilAndExecute` until `time > 0`, because Eden attribute expressions and init fields run before CBA settings are loaded.
- The server does no audio work. Don't add per-frame network traffic, `remoteExec` audio, or server-side loops.

### Schedule (`fn_getTrackAt.sqf`)

`time = CBA_missionTime + seed`, where seed is a weighted sum of the station name's characters (so stations don't change track in lockstep). The station loops through its tracks; the result is `[trackClass, offsetSeconds, playKey]`. The play key `"<station>:<cycle>:<index>"` is unique per play, including repeats, and is what the client loop compares to decide whether to restart a sound. Changing the seed or key format changes what every client hears, so all clients must be on the same mod version (they are, since mods are signature-checked).

### Client loop (`fn_clientUpdate.sqf`, CBA PFH every 0.5 s, `hasInterface` only)

- Checks the radios in `a3r_radios`, plus ones still playing locally (so turning a radio off stops it).
- **Every radio plays on the effects channel**, so the player's effects slider sets the level everywhere. Don't move any of them to the music channel (`playMusic`): music and effects sliders differ, and the radio would jump in loudness when getting in or out of a vehicle.
- The vehicle the player is in (not a placed radio) plays via `playSoundUI [file, volume, 1, true, offset]`. `isEffect = true` puts it on the effects channel; it isn't positional, so the cabin doesn't muffle it.
- **Placed radios** always play like a vehicle PA (below). They used to use `playSound3D` with a real volume. That was dropped so they match the PA exactly, and because `playSound3D` doesn't follow its object.
- **Everything heard from outside** (vehicles, PAs, placed radios) plays via `say3D [sound, range, 1, false, offset]`. It follows its object but has **no volume parameter**, so the gain scales the range instead: `a3r_vehicleRange * gain`, or `a3r_paRange * gain` for PAs and placed radios. That gives the setting's range at 50 % and double at 100 %. Tested in game: a larger `say3D` range also makes the sound **louder** at a given distance, not just audible further away (the engine's falloff seems to scale with max distance). So the knob works as a real volume control outside too. This is intended: one knob per radio, for occupants and everyone outside alike. Their loudness comes from the CfgSounds volume the import tool writes: **1.25** (25 % above the file, so standing next to the vehicle isn't too quiet) and **3.25** for the `<track>_PA` copy (2.6× the outside volume).
- **PA** (`a3r_pa` on vehicles; placed radios always count as PA): the outside sound uses `<track>_PA` and `a3r_paRange`. It falls back to `<track>` if the add-on has no `_PA` class (imported with an older tool). Occupants are unaffected. To change these levels, edit `$outsideVolume` / `$paVolume` in `import_music.ps1` and re-import; the PA range is the `a3r_paRange` setting.
- Sources are tracked in `a3r_playing` as `[radio, restartKey, source]`. `source` is a `playSoundUI` id (number, stopped with `stopSound`) or a `say3D` sound object (`deleteVehicle`). `restartKey` is `"<playKey>|<isInside>|<[range, isPA] outside, volume inside>"`, so a new track, getting in or out, a volume change or toggling PA restarts the sound at the current offset. Toggling PA doesn't restart what occupants hear.
- Range: `a3r_paRange` for PAs and placed radios, `a3r_vehicleRange` for vehicles with PA off (0 = occupants only), both × gain. Volume 0 plays nothing.

### Which objects are radios

- `A3R_fnc_hasRadio` (vehicles): object var `a3r_hasRadio` overrides everything; then setting `a3r_vehicleRadios`; then config `a3r_hasRadio = 0/1`; then default `LandVehicle`/`Ship`/`Air`, minus `StaticWeapon`, `ParachuteBase` and UAVs. The result is cached per class in `a3r_radioClassCache`.
- `A3R_fnc_isPlacedRadio`: object var `a3r_isRadio`, else config `a3r_isRadio = 1` (e.g. `A3R_Radio_FM`, which inherits `Land_FMradio_F`).
- `A3R_fnc_getTarget` (keybinds): the player's vehicle if it has a radio, else objNull.
- `A3R_fnc_getPlacedRadio` (scroll menu): the placed radio the unit, on foot, is looking at within 3 m, else objNull.

### Caches (created in preInit, never invalidated)

`a3r_schedules` (per station), `a3r_soundFileCache` (per track), `a3r_stationsCache` (keyed by `str` of the three source flags), `a3r_radioClassCache` (per vehicle class). Config doesn't change during a mission, so this is safe. If you add something that depends on runtime state, don't put it in these caches.

### Settings (CBA, `XEH_preInit.sqf`, all global `isGlobal = 1`)

`a3r_builtInStations`, `a3r_missionStations`, `a3r_addonStations`, `a3r_vehicleRadios`, `a3r_paRange` (0–300, default 50; replaced `a3r_radioRange` before release), `a3r_vehicleRange` (0–100, default 20). Category "Arma 3 Radio Stations" (station toggles in the "Stations" subcategory). These names are public API: server owners reference them in `cba_settings.sqf`, so don't rename them.

### Player input

- **Vehicles: keybinds only. Placed radios: scroll menu only.** This split is deliberate; keep it.
- Placed-radio actions (`fn_addPlacedRadioActions.sqf`) are added to the player unit via the CBA `"unit"` player event (guarded by `a3r_actionsAdded`). They act on `A3R_fnc_getPlacedRadio`, which returns the placed radio the unit, on foot, is looking at within 3 m. Off: turn on. On: next, previous, volume up/down (menu stays open), turn off.
- CBA keybinds `a3r_next` / `a3r_prev` / `a3r_power` / `a3r_volUp` / `a3r_volDown` / `a3r_pa`, default Ctrl+] / Ctrl+[ / Ctrl+; (on/off) / Ctrl+= / Ctrl+- / Ctrl+' (DIK 0x1B/0x1A/0x27/0x0D/0x0C/0x28). On/off moved from Ctrl+\ because it conflicted, and its id changed from `a3r_off` to `a3r_power`: CBA saves each binding in the player's profile, and a saved binding wins over a changed default, so **changing a default key needs a new id** to reach existing players (this also resets anyone who rebound it). They act on `A3R_fnc_getTarget`, which returns the player's vehicle only (objNull on foot, so the key isn't consumed).
- `A3R_fnc_togglePower` turns off, or on to `a3r_lastStation` (public object var the server sets when a radio is turned off), falling back to the first station. Keybind id `a3r_power`.
- `A3R_fnc_cycleStation` with direction 1/-1/0 (0 = off). On a radio that's off, next/previous turn it on to `a3r_lastStation` like the toggle (first/last station if none).
- `A3R_fnc_adjustVolume` moves one level up or down (sign of the step) through 0, 0.05, 0.1, 0.2 … 1, starting from the nearest level.
- `A3R_fnc_setStation`, `A3R_fnc_setVolume` and `A3R_fnc_togglePA` all call `A3R_fnc_showNowPlaying [station, volume, pa]`, the single radio hint (station, track, volume, " · PA"). It clears itself after 3 s via `CBA_fnc_waitAndExecute`, unless a newer radio hint has replaced it (`a3r_hintId`).
- `A3R_Radio_FM` has Eden attributes `a3r_station` and `a3r_volume` (Slider, 0–1, default 0.5).

## Conventions

- **Naming:** functions `A3R_fnc_<name>` (CfgFunctions tag `A3R`, file `functions\fn_<name>.sqf`); globals and object variables lowercase `a3r_*`; config classes `A3R_*`; CBA events `a3r_*`.
- **Adding a function:** create `functions/fn_<name>.sqf` **and** add `class <name> {};` to `CfgFunctions` in `addons/main/config.cpp` (alphabetical).
- **Function header:** every function starts with a `/* ... */` block: one-line purpose, `Arguments:` list with `<TYPE>`, `Return:` if any. Then `params [...]`. Keep comments short and explain *why*.
- **SQF style:** 4-space indents, `private` on every local, lazy `&& {..}` conditions, `exitWith` early returns, `getVariable [name, default]`, `findIf`/`select`/`apply` over manual loops.
- **Public API**, documented in the README and used by mission makers: `A3R_fnc_setStation`, `A3R_fnc_setVolume`, `A3R_fnc_getStations`, `A3R_fnc_getTrackAt`, the object variables `a3r_hasRadio` / `a3r_isRadio` / `a3r_station` / `a3r_volume` / `a3r_pa`, the `<track>_PA` CfgSounds convention, the config properties `a3r_hasRadio` / `a3r_isRadio`, the `A3R_Stations` schema, the `A3R_Radio_FM` class and the setting names. Keep them backwards compatible.
- `requiredVersion = 2.18` in CfgPatches. Use only commands available in Arma 2.18.
- Line endings per `.gitattributes`: `.ps1`/`.sqm` CRLF, `.sh` LF. `import_music.ps1` writes `.hpp` files as UTF-8 without BOM, CRLF.

## Generated files: don't hand-edit

These are rewritten by `import_music.ps1`. Change the music or the script instead:

- `Arma3RadioStations/addons/stations/{cfgSounds,cfgMusic,stations}.hpp` and `data/*.ogg`
- `Arma3RadioStations/.hemtt/missions/a3r_test.VR/radio/*`
- `AddonTemplate/addons/main/{cfgSounds,cfgMusic,stations}.hpp` and `data/*.ogg`

The import script: class prefix comes from `$PBOPREFIX$` (dropping `z`, `x`, `addons`, `main`), `Mission` for mission targets, or `-ClassPrefix` (built-in uses `A3R`). Station class = `<prefix>_<FolderNameAlnum>`, track class = `<station>_NN`, plus `<station>_NN_PA` in CfgSounds only. The `.ogg` name is based on the source file name, so reordering doesn't force reconversion. Conversion is mono 44.1 kHz Vorbis (mono is required for 3D `say3D`). It only reconverts when the source is newer, and it warns about unused `.ogg` files but never deletes them.

The built-in stations (`addons/stations`) are real music the user added. Don't replace or re-import them without being asked. The test mission and AddonTemplate use synthesized placeholder tones; see "Regenerating the placeholder music" in the README, and don't import `demo_music/builtin` over the built-in stations. Don't add music to the repo unless the user confirms they have the rights to distribute it.

## Releasing

Versions use calendar versioning, **`YYYY.MM.DD.N`**: release date, then the release number that day, starting at 1. In `script_version.hpp`: `MAJOR` = year, `MINOR` = month, `PATCHLVL` = day, `BUILD` = N.

- Month and day **must stay two digits** (`02`, not `2`). `version = MAJOR.MINOR` in CfgPatches is a decimal number, so `2026.2` would sort above `2026.10`. `versionStr` (built by the `VERSION_STR` macro) and `versionAr[]` carry the full version.
- HEMTT's own version (`hemtt value project.version`, the release ZIP name) drops the zero padding, e.g. `2026.2.9.1`. That's expected.
- AddonTemplate still uses plain `0.1.0.0`. Mod makers version their own add-ons however they like.

1. Run `powershell -ExecutionPolicy Bypass -File tools\bump_version.ps1`. Don't edit the numbers by hand.
2. `hemtt release`. Each release is signed with a new key, so server owners need the new `.bikey`.
3. The user publishes to the Workshop with Arma 3 Publisher.

## Commits and pull requests

Commit or push only when the user asks. Work on a branch, not `main`: short, kebab-case and descriptive (`radio-volume`, `fix-jip-station-sync`). Commit and PR messages should be detailed. Someone reading `git log` a year from now should understand what changed for players and *why* it was done that way, without opening the diff.

### Commits

- **One logical change per commit** where you can. If several changes touch the same files (e.g. README and CLAUDE.md) and can't be separated cleanly, make one commit with a section per change.
- **Subject line:** imperative mood, ≤ 72 characters, no trailing period. Say what the change does for the mod, not which files moved: "Play in-vehicle radio on the effects channel", not "Update fn_clientUpdate.sqf".
- **Body**, wrapped at ~72 columns, after a blank line:
  - **What and why.** The behaviour before, the behaviour now, and the reason. Include rejected alternatives when the choice wasn't obvious. Engine limits are the usual case: `say3D` has no volume, and `playSound3D` doesn't follow its object.
  - **Player-, mission- and server-facing changes:** keybinds, defaults, settings, Eden attributes, scripting API.
  - **Compatibility:** anything that touches the public API (see Conventions), saved settings, keybind ids, station config or network variables. State clearly whether old missions, add-ons and `cba_settings.sqf` files still work.
  - **Verification:** what you actually ran (`hemtt build` clean, scripts exercised), and what still **needs in-game or multiplayer testing**. Never imply something was tested in game when it wasn't. Only the user can run Arma.
  - Use short `Section:` headings or `-` bullet lists when the commit covers more than one thing.
- End with the attribution trailer the session provides.

Example:

```
Play in-vehicle radio on the effects channel

Inside a vehicle the radio used playMusic, so it followed the player's
music slider while every other radio (say3D / playSound3D) followed
the effects slider. With different slider settings the radio jumped in
loudness when getting in or out.

Now the in-vehicle radio uses playSoundUI with isEffect = true: still
non-positional (not muffled by the cabin), but on the effects channel,
so one slider sets the level everywhere. It also stops taking over the
mission's music channel. The fadeMusic save/restore is removed.

Compatibility: no API or config changes. CfgMusic is still read for
track durations and titles, so existing add-ons need no changes.

Verified: hemtt build clean. Needs in-game check that the in-vehicle
radio sounds clear and that the level matches on getting out.
```

### Pull requests

Create PRs with `gh pr create` against `main`, and only when asked. Use this structure:

```
## Summary
One or two sentences: what this PR does and why.

## Changes
Grouped by feature. For each: behaviour before → after, and the key
implementation decision with its reason.

## Player / mission maker / server owner impact
New or changed keybinds, defaults, settings, Eden attributes, scripting
functions. "None" if nothing user-facing changed.

## Compatibility
Public API, settings, keybind ids, station config, network variables.
Breaking changes called out explicitly, with migration steps.

## Testing
- [x] hemtt build (clean apart from BBW1)
- [ ] In-game singleplayer: <specific things to check>
- [ ] Multiplayer / JIP: <specific things to check>

## Docs
README / CLAUDE.md sections updated, or why none were needed.
```

- Tick only the boxes that were actually done. In-game boxes stay unticked unless the user confirms they tested.
- The title follows the commit subject rules.
- End the description with the attribution line the session provides.
- If the version should be bumped for a release, say so in the PR. Don't bump it in feature PRs unless asked.

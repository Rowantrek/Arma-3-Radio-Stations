# CLAUDE.md

Context for working on **Arma 3 Radio Stations** (by Rowantrek): a CBA_A3-based Arma 3 mod that gives every vehicle, and a placeable object, a music radio. Stations are "live": every machine works out the current track from the synced mission clock, so only the chosen station goes over the network.

`README.md` is the user-facing manual (players, mission makers, server owners, music add-on makers). This file covers what you need to change the code safely. **When you change behaviour, settings, keybinds, function signatures or the import tool, update the README to match.**

## Repository layout

```
Arma3RadioStations/            The mod itself (HEMTT project, prefix "a3r", mainprefix "z")
  addons/main/                 a3r_main.pbo: all logic, settings, keybinds, placeable radio
    config.cpp                 CfgPatches, XEH hooks, CfgFunctions, A3R_Radio_FM object, empty A3R_Stations root
    XEH_preInit.sqf            caches, CBA settings, server event handler, keybinds
    XEH_postInit.sqf           client-only: starts the 0.5 s loop, adds scroll actions
    functions/fn_*.sqf         A3R_fnc_* functions (see below)
    script_version.hpp         Version YYYY.MM.DD.N (see Releasing)
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
- `CfgSounds` (used by `say3D` for 3D playback) and
- `CfgMusic` (used by `playMusic` in-vehicle, and its `duration` drives the schedule).

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

- The only replicated state is, per radio, `a3r_station` (station class or `""`) and `a3r_volume` (0–1, unset = 1), plus `a3r_radios` (public `missionNamespace` array of radios that are on). JIP works through these public variables.
- Any machine calls `A3R_fnc_setStation` / `A3R_fnc_setVolume`, which send the CBA server events `a3r_setStation` / `a3r_setVolume` to `A3R_fnc_serverSetStation` / `A3R_fnc_serverSetVolume`. Only the server broadcasts those variables; it validates stations against `A3R_fnc_getStations` and clamps volume. (`setVolume` also sets `a3r_volume` locally, unbroadcast, so fast repeated presses step correctly before the server's update arrives.)
- `serverSetStation` defers with `CBA_fnc_waitUntilAndExecute` until `time > 0`, because Eden attribute expressions and init fields run before CBA settings are loaded.
- The server does no audio work. Don't add per-frame network traffic, `remoteExec` audio, or server-side loops.

### Schedule (`fn_getTrackAt.sqf`)

`time = CBA_missionTime + seed`, where seed is a weighted sum of the station name's characters (so stations don't change track in lockstep). The station loops through its tracks; the result is `[trackClass, offsetSeconds, playKey]`. The play key `"<station>:<cycle>:<index>"` is unique per play, including repeats, and is what the client loop compares to decide whether to restart a sound. Changing the seed or key format changes what every client hears, so all clients must be on the same mod version (they are, since mods are signature-checked).

### Client loop (`fn_clientUpdate.sqf`, CBA PFH every 0.5 s, `hasInterface` only)

- Checks the radios in `a3r_radios`, plus ones still playing locally (so turning a radio off stops it).
- The vehicle the player is in (not a placed radio) plays on the **music channel** via `playMusic [track, offset]`, tracked in `a3r_musicKey`. Radio volume is applied with `fadeMusic` (`a3r_musicVolume`); the mission's own `musicVolume` is saved in `a3r_missionMusicVolume` when the radio starts and restored when it stops. This takes over the mission's music channel while the radio is on.
- **Placed radios** play via `playSound3D [file, obj, false, posASL, volume, 1, range, offset, true]` (local). It supports volume but **doesn't follow its object**, so the sound restarts if the radio moves more than 1 m. File paths come from `A3R_fnc_getSoundFile` (mission files via `getMissionPath`, addon paths without the leading `\`).
- **Vehicles heard from outside** play via `say3D [track, range, 1, false, offset]`. It follows the vehicle but has **no volume parameter**, so volume scales the range instead (`a3r_vehicleRange * volume`).
- Sources are tracked in `a3r_playing` as `[radio, restartKey, source, startPosASL]`. `source` is a `playSound3D` id (number, stopped with `stopSound`) or a `say3D` sound object (`deleteVehicle`). `restartKey` is `"<playKey>|<volume or range>"`, so a volume change restarts the 3D sound at the current offset.
- Range: `a3r_radioRange` for placed radios, `a3r_vehicleRange` for vehicles heard from outside (0 = occupants only). Volume 0 plays nothing in 3D.

### Which objects are radios

- `A3R_fnc_hasRadio` (vehicles): object var `a3r_hasRadio` overrides everything; then setting `a3r_vehicleRadios`; then config `a3r_hasRadio = 0/1`; then default `LandVehicle`/`Ship`/`Air`, minus `StaticWeapon`, `ParachuteBase` and UAVs. The result is cached per class in `a3r_radioClassCache`.
- `A3R_fnc_isPlacedRadio`: object var `a3r_isRadio`, else config `a3r_isRadio = 1` (e.g. `A3R_Radio_FM`, which inherits `Land_FMradio_F`).
- `A3R_fnc_getTarget`: the player's vehicle if it has a radio, else `cursorObject` if it's a placed radio within 3 m.

### Caches (created in preInit, never invalidated)

`a3r_schedules` (per station), `a3r_soundFileCache` (per track), `a3r_stationsCache` (keyed by `str` of the three source flags), `a3r_radioClassCache` (per vehicle class). Config doesn't change during a mission, so this is safe. If you add something that depends on runtime state, don't put it in these caches.

### Settings (CBA, `XEH_preInit.sqf`, all global `isGlobal = 1`)

`a3r_builtInStations`, `a3r_missionStations`, `a3r_addonStations`, `a3r_vehicleRadios`, `a3r_radioRange` (5–200, default 40), `a3r_vehicleRange` (0–100, default 20). Category "Arma 3 Radio Stations" (station toggles in the "Stations" subcategory). These names are public API: server owners reference them in `cba_settings.sqf`, so don't rename them.

### Player input

- Scroll actions (`fn_addPlayerActions.sqf`), added on every player unit change via the CBA `"unit"` player event; guarded by `a3r_actionsAdded`.
- Scroll actions: next station, off, volume up/down (volume ones only while on, and stay open after use).
- CBA keybinds `a3r_next` / `a3r_prev` / `a3r_off` / `a3r_volUp` / `a3r_volDown`, default Ctrl+] / Ctrl+[ / Ctrl+\ / Ctrl+= / Ctrl+- (DIK 0x1B/0x1A/0x2B/0x0D/0x0C).
- `A3R_fnc_cycleStation` with direction 1/-1/0; `A3R_fnc_adjustVolume` with a step (±0.1, rounded to 10 %); `A3R_fnc_showNowPlaying` and `A3R_fnc_setVolume` show a hint.
- `A3R_Radio_FM` has Eden attributes `a3r_station` and `a3r_volume` (Slider, 0–1).

## Conventions

- **Naming:** functions `A3R_fnc_<name>` (CfgFunctions tag `A3R`, file `functions\fn_<name>.sqf`); globals and object variables lowercase `a3r_*`; config classes `A3R_*`; CBA events `a3r_*`.
- **Adding a function:** create `functions/fn_<name>.sqf` **and** add `class <name> {};` to `CfgFunctions` in `addons/main/config.cpp` (alphabetical).
- **Function header:** every function starts with a `/* ... */` block: one-line purpose, `Arguments:` list with `<TYPE>`, `Return:` if any. Then `params [...]`. Keep comments short and explain *why*.
- **SQF style:** 4-space indents, `private` on every local, lazy `&& {..}` conditions, `exitWith` early returns, `getVariable [name, default]`, `findIf`/`select`/`apply` over manual loops.
- **Public API**, documented in the README and used by mission makers: `A3R_fnc_setStation`, `A3R_fnc_setVolume`, `A3R_fnc_getStations`, `A3R_fnc_getTrackAt`, the object variables `a3r_hasRadio` / `a3r_isRadio` / `a3r_station` / `a3r_volume`, the config properties `a3r_hasRadio` / `a3r_isRadio`, the `A3R_Stations` schema, the `A3R_Radio_FM` class and the setting names. Keep them backwards compatible.
- `requiredVersion = 2.18` in CfgPatches. Use only commands available in Arma 2.18.
- Line endings per `.gitattributes`: `.ps1`/`.sqm` CRLF, `.sh` LF. `import_music.ps1` writes `.hpp` files as UTF-8 without BOM, CRLF.

## Generated files: don't hand-edit

These are rewritten by `import_music.ps1`. Change the music or the script instead:

- `Arma3RadioStations/addons/stations/{cfgSounds,cfgMusic,stations}.hpp` and `data/*.ogg`
- `Arma3RadioStations/.hemtt/missions/a3r_test.VR/radio/*`
- `AddonTemplate/addons/main/{cfgSounds,cfgMusic,stations}.hpp` and `data/*.ogg`

The import script: class prefix comes from `$PBOPREFIX$` (dropping `z`, `x`, `addons`, `main`), `Mission` for mission targets, or `-ClassPrefix` (built-in uses `A3R`). Station class = `<prefix>_<FolderNameAlnum>`, track class = `<station>_NN`. The `.ogg` name is based on the source file name, so reordering doesn't force reconversion. Conversion is mono 44.1 kHz Vorbis (mono is required for 3D `say3D`). It only reconverts when the source is newer, and it warns about unused `.ogg` files but never deletes them.

To regenerate the placeholder audio, see "Regenerating the placeholder music" in the README. The demo audio is synthesized, so the repo contains no copyrighted music. Keep it that way.

## Releasing

Versions use calendar versioning, **`YYYY.MM.DD.N`**: release date, then the release number that day, starting at 1. In `script_version.hpp`: `MAJOR` = year, `MINOR` = month, `PATCHLVL` = day, `BUILD` = N.

- Month and day **must stay two digits** (`02`, not `2`). `version = MAJOR.MINOR` in CfgPatches is a decimal number, so `2026.2` would sort above `2026.10`. `versionStr` (built by the `VERSION_STR` macro) and `versionAr[]` carry the full version.
- HEMTT's own version (`hemtt value project.version`, the release ZIP name) drops the zero padding, e.g. `2026.2.9.1`. That's expected.
- AddonTemplate still uses plain `0.1.0.0`. Mod makers version their own add-ons however they like.

1. Run `powershell -ExecutionPolicy Bypass -File tools\bump_version.ps1`. Don't edit the numbers by hand.
2. `hemtt release`. Each release is signed with a new key, so server owners need the new `.bikey`.
3. The user publishes to the Workshop with Arma 3 Publisher.

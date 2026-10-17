# Architecture

How Arma 3 Radio Stations works, and why the less obvious choices were made. This file covers the design only. The code and its comments hold the details and are the source of truth. Read the functions involved before changing them.

## Overview

- **`a3r_main`** (`Arma3RadioStations/addons/main`) holds all the logic: CBA settings, keybinds, the client sound loop, and the placeable `A3R_Radio_FM` (inherits `Land_FMradio_F`).
- **`a3r_stations`** (`addons/stations`) holds the built-in stations. Missions (`description.ext`) and music add-on mods add more stations the same way, through config.
- **Live stations:** every machine works out the current track and offset from `CBA_missionTime`. Only per-radio state (station, volume, PA) goes over the network. There's no audio traffic, and the server does no audio work.

## Stations and tracks

A station is a class under `A3R_Stations` with `displayName` and `tracks[]`. Each track class must exist in:

- **`CfgMusic`**, for `duration` (drives the schedule) and `name` (the title shown). Its `sound[]` isn't played.
- **`CfgSounds`**, for `say3D`. The second `sound[]` value is the loudness heard from outside. `<track>_PA` is an optional louder copy, CfgSounds only, pointing at the same `.ogg`.

Tracks missing from either, or with `duration <= 0`, are dropped. A station with no valid tracks is hidden.

| Source | Where | Identified by |
|---|---|---|
| Mission | `description.ext` → `A3R_Stations` | `missionConfigFile` (`A3R_fnc_findConfig` looks here first) |
| Built-in | `addons/stations` | `"a3r_stations" in configSourceAddonList`, so don't rename that CfgPatches class |
| Add-on | any other mod | everything else in `configFile` |

Sound paths: addons use `\z\<prefix>\addons\<addon>\data\file.ogg`, missions use `radio\file.ogg`. `A3R_fnc_getSoundFile` turns these into the form `playSoundUI` needs.

## Network state

| Variable | On | Meaning |
|---|---|---|
| `a3r_station` | radio | station class, `""` = off |
| `a3r_volume` | radio | knob 0–1, unset = 0.5 |
| `a3r_lastStation` | radio | set when turned off; used when turning back on |
| `a3r_pa` | vehicle | PA on, unset = false |
| `a3r_radios` | `missionNamespace` | array of radios that are on |

- **Server-authoritative.** Clients call `A3R_fnc_setStation` / `setVolume` / `togglePA`, which send the CBA server events `a3r_setStation` / `a3r_setVolume` / `a3r_setPA`. The `A3R_fnc_server*` handlers validate the request and broadcast the public variable.
- **Local prediction.** Volume and PA are also set locally, so fast repeated key presses work before the server echoes back.
- **Early calls are deferred.** `serverSetStation` waits until `time > 0`, because Eden attribute expressions run before CBA settings exist.
- **JIP** works through the public variables alone.

## Schedule (`fn_getTrackAt.sqf`)

Time is `CBA_missionTime` plus a seed derived from the station name, so stations don't change track together. The station loops through its tracks. The function returns `[track, offset, playKey]`, where the play key `"<station>:<cycle>:<index>"` is unique per play. Changing the seed or key format changes what every client hears.

## Playback (`fn_clientUpdate.sqf`, every 0.5 s, clients only)

| Listener | Command | Loudness | Range |
|---|---|---|---|
| Inside own vehicle | `playSoundUI [file, gain, 1, true, offset]` | gain | n/a |
| Outside a vehicle, PA off | `say3D [<track>, range, …]` | CfgSounds 1.25 | `a3r_vehicleRange × gain` |
| Outside a vehicle with PA on, or near any placed radio | `say3D [<track>_PA, range, …]` | CfgSounds 3.25 | `a3r_paRange × gain` |

- **Gain** is `2 × a3r_volume`, so the 50% default is normal loudness.
- **Everything plays on the effects channel**, so the player's effects slider sets the level everywhere. Using `playMusic` (the music slider) made the level jump on getting in or out of a vehicle.
- **`say3D` is the only command that follows a moving object, but it has no volume parameter.** So:
  - the loudness heard from outside lives in CfgSounds, which is why the `_PA` copies exist;
  - the knob scales range instead. Tested in game, a larger range is also louder at a given distance, so the knob works as a volume control outside too.
- **Not used:** `playSound3D` has a volume but stays where it started, and `playMusic` uses the music slider.
- If an add-on has no `_PA` class, the loop falls back to `<track>`.
- **Tracking.** Each playing sound is stored in `a3r_playing` as `[radio, restartKey, source]`. `source` is a `playSoundUI` id (stopped with `stopSound`) or a `say3D` sound object (`deleteVehicle`). A sound restarts at the current offset when its restart key changes: a new track, getting in or out, a volume change or toggling PA. Toggling PA doesn't restart what occupants hear.

## Which objects are radios

- **Vehicles** (`A3R_fnc_hasRadio`, cached per class), in priority order:
  1. object variable `a3r_hasRadio`;
  2. setting `a3r_vehicleRadios`;
  3. config `a3r_hasRadio`;
  4. default: `LandVehicle` / `Ship` / `Air`, except static weapons, parachutes and UAVs.
- **Placed radios** (`A3R_fnc_isPlacedRadio`): object variable `a3r_isRadio`, otherwise config `a3r_isRadio = 1`.

## Controls

- **Vehicles: CBA keybinds only.** They act on `A3R_fnc_getTarget`, which returns the player's vehicle or objNull.
- **Placed radios: scroll menu only.** The actions are added to the player unit through the CBA `"unit"` event. They act on `A3R_fnc_getPlacedRadio`: on foot, looking at the radio, within 3 m.
- **On/off and resume.** `togglePower` and `cycleStation` turn a radio that's off back on to `a3r_lastStation`. `adjustVolume` steps through 0, 5%, then 10% steps.
- **One hint.** `A3R_fnc_showNowPlaying` shows station, track, volume and PA, and clears itself after 3 s.
- **CBA keeps a player's saved binding over a changed default.** Changing a default key needs a new keybind id, which is why on/off moved from `a3r_off` to `a3r_power`.

## Settings and caches

- **Settings** (CBA, global): `a3r_builtInStations`, `a3r_missionStations`, `a3r_addonStations`, `a3r_vehicleRadios`, `a3r_vehicleRange` (default 20 m), `a3r_paRange` (default 50 m).
- **Caches** (preInit, never invalidated, because config is static during a mission): `a3r_schedules`, `a3r_stationsCache`, `a3r_radioClassCache`, `a3r_soundFileCache`. Don't cache anything that depends on runtime state.

## Import tool (`tools/import_music.ps1`)

- **Input:** each source subfolder becomes a station, and each audio file becomes a track. Leading numbers in file names set the order.
- **Conversion:** files are converted to mono 44.1 kHz Vorbis. Mono is required for 3D sound.
- **Durations** come from ffprobe.
- **Output:** the tool writes `cfgSounds.hpp` (track + `_PA`, at `$outsideVolume` / `$paVolume`), `cfgMusic.hpp` and `stations.hpp`.
- **Class names:** the prefix comes from `$PBOPREFIX$`, is `Mission` for missions, or is set with `-ClassPrefix`. Station class = `<prefix>_<Folder>`, track class = `<station>_NN`.
- **Reruns:** a file is converted again only when its source is newer. Unused `.ogg` files trigger a warning but aren't deleted.

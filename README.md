# Arma 3 Radio Stations

Live music radio for Arma 3 by **Rowantrek**.

Every vehicle has a radio, modded vehicles included, and there is a placeable radio for bases and camps. Stations are synced in multiplayer, so everyone in the car hears the same song at the same moment, and players who join late are tuned in mid-song like real radio.

**Requires:** [CBA_A3](https://steamcommunity.com/workshop/filedetails/?id=450814997)

- [Features](#features)
- [For players](#for-players)
- [For mission makers](#for-mission-makers)
- [For server owners](#for-server-owners)
- [For mod makers (music add-ons)](#for-mod-makers-music-add-ons)
- [The music import tool](#the-music-import-tool)
- [Building the mod](#building-the-mod)

## Features

- **Vehicle radios.** Cars, trucks, tanks, boats, helicopters and planes, from vanilla or mods. Occupants hear clear audio on the music channel; people outside hear it in 3D from the vehicle.
- **Placeable radio.** *Music Radio* in Eden and Zeus (*Things > Radios*), heard in 3D around it.
- **Live stations.** Each station is a looping playlist that keeps playing whether anyone listens or not. Tuning in joins the current song mid-way.
- **Lightweight in multiplayer.** Only the station choice goes over the network. Timing comes from the synced mission clock.
- **Three sources of music**, which can be used together and switched on or off per server or per mission:

| | Built-in | Mission | Add-on mod |
|---|---|---|---|
| Made by | This mod | Mission maker | Mod maker or server owner |
| Music is in | Arma 3 Radio Stations itself | The mission file | A separate music mod |
| Players get it | With Arma 3 Radio Stations | Automatically when joining | By loading the music mod |
| Best for | Stations out of the box | A few songs for one mission | Big libraries for every mission |

Arma can't stream audio or play files from a player's own disk. Every player needs the same audio files, which is why the music always comes with a mod or a mission.

## Repository layout

| Folder | |
|---|---|
| [`Arma3RadioStations/`](Arma3RadioStations) | **Arma 3 Radio Stations itself**: everything that is built into the mod. HEMTT project. |
| &nbsp;&nbsp;`Arma3RadioStations/addons/main` | Radio logic, settings, keybinds, placeable radio |
| &nbsp;&nbsp;`Arma3RadioStations/addons/stations` | Built-in stations and their audio |
| &nbsp;&nbsp;`Arma3RadioStations/.hemtt/missions/a3r_test.VR` | Test mission: mission-defined station, placed radio, vehicles |
| [`AddonTemplate/`](AddonTemplate) | **Music add-on template** for making your own music mod. HEMTT project. |
| [`tools/`](tools) | **Tools**: `import_music.ps1` turns music into stations; `make_demo_audio.sh` synthesizes the placeholder music |

---

## For players

| | |
|---|---|
| **Scroll menu** | *Radio: next station* / *Radio: turn off*: when inside a vehicle, or looking at a placed radio within 3 m |
| **Keybinds** | `Ctrl+]` next station, `Ctrl+[` previous, `Ctrl+\` off. Rebind in *Options > Controls > Configure Addons > Arma 3 Radio Stations* |
| **Volume** | Inside a vehicle: **music** volume. Placed radios and vehicles heard from outside: **effects** volume |

Switching station shows the station name and the current song.

---

## For mission makers

### Placed radios

Place **Music Radio** from *Things > Radios*. In its attributes, set **Radio station** to a station class name (e.g. `A3R_PulseFM`), `random`, or leave it empty for off.

To turn any object into a radio:

```sqf
this setVariable ["a3r_isRadio", true, true];   // in the object's init
```

### Vehicles

All vehicles have radios by default. To change that for a single vehicle:

```sqf
this setVariable ["a3r_hasRadio", false, true]; // in the vehicle's init: no radio
```

### Scripting

```sqf
[_vehicle, "A3R_PulseFM"] call A3R_fnc_setStation;   // tune: station class, "random", or "" for off
call A3R_fnc_getStations;                             // active station class names
["A3R_PulseFM"] call A3R_fnc_getTrackAt;              // [track class, seconds into track, play id]
```

### Adding your own stations to a mission

The music is packed into the mission and downloaded by players when they join, so no extra mod is needed. Keep it small, because every MB adds to join time. 10–20 songs at about 0.5 MB per minute is reasonable.

1. Get [`tools/import_music.ps1`](tools/import_music.ps1) and install ffmpeg (`winget install Gyan.FFmpeg`).
2. Put your music in a folder, one subfolder per station (see [the music import tool](#the-music-import-tool)).
3. Run it with your mission folder as the target. It creates a `radio\` folder in the mission:
   ```powershell
   powershell -ExecutionPolicy Bypass -File import_music.ps1 -Source "C:\Music\MyStations" -Target "C:\Users\<you>\Documents\Arma 3 - Other Profiles\<profile>\missions\MyMission.Altis"
   ```
4. Add these lines to the mission's `description.ext`. If it already has `CfgSounds` or `CfgMusic`, put the `#include` line inside your existing class instead:
   ```cpp
   class CfgSounds {
       #include "radio\cfgSounds.hpp"
   };
   class CfgMusic {
       #include "radio\cfgMusic.hpp"
   };
   class A3R_Stations {
       #include "radio\stations.hpp"
   };
   ```
5. Save the mission in Eden so it reloads `description.ext`. Your stations are named `Mission_<FolderName>`, e.g. `Mission_DriftRadio`.

See [`Arma3RadioStations/.hemtt/missions/a3r_test.VR`](Arma3RadioStations/.hemtt/missions/a3r_test.VR) for a working example.

### Choosing which stations play

In Eden, go to *Settings > Addon Options > Arma 3 Radio Stations > Stations* and tick or untick **Built-in**, **Mission** and **Add-on mod** stations. This is saved in the mission. For example, untick the other two so only your mission's stations play. A server that forces a setting overrides the mission.

---

## For server owners

### Installing

The server **and every player** must load these mods with `-mod=` (not `-serverMod`), because players need the audio:

1. CBA_A3
2. Arma 3 Radio Stations
3. Any music add-on mods you want

For signature checks (`verifySignatures = 2`), copy each mod's `.bikey` from its `keys` folder into the server's `keys` folder.

### Settings

Log in as admin, open *Options > Addon Options > Arma 3 Radio Stations* and use the **Server** tab to set and **force** values for everyone. You can also put them in a `cba_settings.sqf`; see the [CBA settings documentation](https://github.com/CBATeam/CBA_A3/wiki/CBA-Settings-System).

| Setting | Default | |
|---|---|---|
| Vehicle radios | On | Whether vehicles have radios at all |
| Placed radio range | 40 m | How far a placed radio can be heard |
| Vehicle radio range (outside) | 20 m | How far a vehicle radio is heard from outside. 0 = occupants only |
| Built-in stations | On | Stations that come with Arma 3 Radio Stations |
| Mission stations | On | Stations defined in the mission file |
| Add-on mod stations | On | Stations from music add-on mods |

For example, to play only your own community's music everywhere: load your music add-on, untick and force **Built-in stations**, and leave **Add-on mod stations** on.

```sqf
// cba_settings.sqf
force a3r_builtInStations = false;
force a3r_addonStations = true;
force a3r_missionStations = true;
```

### Your own music

Have a music add-on made for your server (see [for mod makers](#for-mod-makers-music-add-ons)), or make one yourself. It takes about ten minutes with the template. Only use music you have the rights to distribute.

### Performance

Radios use very little bandwidth: a variable on each radio changes only when someone switches station. The server does no audio work. Each client runs a small check twice a second.

---

## For mod makers (music add-ons)

A music add-on is a separate mod that only contains music. Its stations show up on every radio, in every mission. [`AddonTemplate/`](AddonTemplate) is a complete, buildable example with one station, *Example FM*.

**You need:** [HEMTT](https://hemtt.dev) (`winget install BrettMayson.HEMTT`) and ffmpeg (`winget install Gyan.FFmpeg`).

### 1. Copy and rename

Copy the `AddonTemplate` folder to a new place, e.g. `MyUnitRadio`. Pick a **unique** prefix: lowercase, no spaces, e.g. `a3r_myunit`. Two add-ons with the same prefix overwrite each other. Replace `a3r_mymusic` in three places:

| File | Change |
|---|---|
| `.hemtt/project.toml` | `prefix = "a3r_myunit"`, plus `name` and `author` |
| `addons/main/$PBOPREFIX$` | `z\a3r_myunit\addons\main` |
| `addons/main/config.cpp` | `class a3r_myunit_main`, plus `name` and `author` |

Also set `name` and `author` in `mod.cpp`, and delete the files in `addons/main/data/`. They are rebuilt in the next step.

### 2. Add music

Replace `music/Example FM` with your own station folders:

```
music/
  Unit FM/
    01 Opening Song.mp3
    02 Another Song.flac
  Night Shift/
    ...
```

### 3. Import

From your add-on folder, run the import tool from this repository:

```powershell
powershell -ExecutionPolicy Bypass -File <path to this repository>\tools\import_music.ps1 -Source music -Target addons\main
```

This fills `addons/main/data` with converted `.ogg` files and writes `cfgSounds.hpp`, `cfgMusic.hpp` and `stations.hpp`. Re-run it whenever the music changes. Your stations are named `<prefix>_<FolderName>`, e.g. `a3r_myunit_UnitFM`.

### 4. Build and test

```
hemtt build      # mod in .hemttout/build
hemtt launch     # starts Arma with CBA + your add-on
```

`hemtt launch` also needs Arma 3 Radio Stations. Add its Workshop ID to `workshop = [...]` in `.hemtt/project.toml`, or add a local build to `parameters`, e.g. `'-mod=C:\path\to\Arma3Radio\Arma3RadioStations\.hemttout\build'`. In game, get in any vehicle and press `Ctrl+]`.

### 5. Release

```
hemtt release    # signed mod and .bikey in releases/
```

To publish on the Steam Workshop, upload `.hemttout/release` with *Arma 3 Publisher* (Arma 3 Tools on Steam). Set **Arma 3 Radio Stations** and **CBA_A3** as required items, and give server owners the `.bikey`.

### Tips

- **Size.** Mono Ogg at the default quality is about 0.5 MB per minute: 3 hours is about 90 MB. Use `-Quality 2` to save space, or up to `6` for better audio.
- **Git.** You don't need to commit your source music in `music/`, because the converted `.ogg` files are what gets built. For big libraries, consider [Git LFS](https://git-lfs.com) for `addons/main/data`.
- **Copyright.** Only publish music you have the rights to. Steam removes Workshop items that contain copyrighted music.

---

## The music import tool

[`tools/import_music.ps1`](tools/import_music.ps1) is used for all three station sources. It needs ffmpeg on PATH.

```
<music folder>/
  Station Name/          one folder per station; the folder name is the station name
    01 Song Title.mp3    one file per track; file names become titles, leading numbers set the order
```

```powershell
powershell -ExecutionPolicy Bypass -File tools\import_music.ps1 -Source <music folder> -Target <addon or mission folder> [-ClassPrefix <prefix>] [-Quality 0-10]
```

| Target | Audio goes to | Configs go to | Class prefix |
|---|---|---|---|
| Addon folder (has `$PBOPREFIX$`) | `<addon>\data` | `<addon>` | From the addon prefix |
| Mission folder (has `mission.sqm`) | `<mission>\radio` | `<mission>\radio` | `Mission` |

- Converts `.mp3 .wav .flac .ogg .m4a .aac .wma .opus` to mono Ogg Vorbis, the format Arma needs for 3D sound.
- Writes the exact track lengths, which the station schedule depends on.
- Skips files that are already converted and unchanged, and warns about `.ogg` files no station uses.

### Station config reference

This is what the tool writes. You can also write it by hand:

```cpp
class CfgSounds {   // 3D playback (placed radios, vehicles heard from outside)
    class My_Track_01 { name = "Song"; sound[] = {"\path\song.ogg", 1, 1}; titles[] = {}; };
};
class CfgMusic {    // in-vehicle playback; duration in seconds drives the schedule
    class My_Track_01 { name = "Song"; sound[] = {"\path\song.ogg", 1, 1}; duration = 183.4; };
};
class A3R_Stations {
    class My_Station {
        displayName = "My Station";
        tracks[] = {"My_Track_01"};
    };
};
```

Config properties for vehicle and object mods: `a3r_hasRadio = 0/1;` on a vehicle class, and `a3r_isRadio = 1;` to make an object class a placeable radio. By default, every class inheriting from `LandVehicle`, `Ship` or `Air` has a radio, except static weapons, parachutes and drones.

---

## Building the mod

### Requirements

| Tool | Needed for | Install |
|---|---|---|
| [HEMTT](https://hemtt.dev) | Building, always | `winget install BrettMayson.HEMTT` |
| [ffmpeg](https://ffmpeg.org) | Only when changing music | `winget install Gyan.FFmpeg` |
| Arma 3 + [CBA_A3](https://steamcommunity.com/workshop/filedetails/?id=450814997) | Testing in game | Steam; subscribe to CBA on the Workshop |
| [Git](https://git-scm.com) | Cloning the repository (optional) | `winget install Git.Git` |

Open a **new** terminal after installing, so the tools are on PATH.

### 1. Get the source

```
git clone <repository url>
cd <repository folder>
```

Or download the repository as a ZIP from GitHub and extract it.

### 2. Build

```
cd Arma3RadioStations
hemtt build
```

The mod is written to `Arma3RadioStations/.hemttout/build`:

```
.hemttout/build/
  addons/a3r_main.pbo        radio logic
  addons/a3r_stations.pbo    built-in stations
  mod.cpp
```

HEMTT also checks the configs and scripts while building, and stops with a message if something is wrong.

### 3. Test in game

Either let HEMTT start Arma with CBA and open the test mission in Eden:

```
hemtt launch
```

Or load your build yourself. In the **Arma 3 Launcher**, go to *Mods > ⋯ (More) > Add local mod…* and pick `Arma3RadioStations/.hemttout/build`. Enable CBA_A3 too, then press *Play*.

### 4. Release

```
hemtt release
```

This builds and **signs** the mod, then zips it:

```
releases/a3r-<version>.zip
  @a3r/
    addons/*.pbo + *.bisign    signed addons
    keys/a3r_<version>.bikey   key for servers (keys folder)
    mod.cpp
```

You can rename the `@a3r` folder, for example to `@Arma3RadioStations`. Upload this folder to the Steam Workshop with *Arma 3 Publisher*, or share the ZIP.

- **Version:** set it in `Arma3RadioStations/addons/main/script_version.hpp` before each release.
- **Keys:** each release is signed with a new key, so server owners must replace the old `.bikey` when they update.

### Changing the built-in stations

Put music in a folder with one subfolder per station, then run from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File tools\import_music.ps1 -Source <music folder> -Target Arma3RadioStations\addons\stations -ClassPrefix A3R
```

Delete the `.ogg` files the script reports as unused, then build again.

### Building a music add-on

See [For mod makers](#for-mod-makers-music-add-ons). It's the same process in `AddonTemplate/` or your copy of it.

### Troubleshooting

| Problem | Fix |
|---|---|
| `warning[BBW1]: Arma 3 Tools not found` | Harmless. Arma 3 Tools are only needed for 3D models, and this mod has none. |
| `hemtt` / `ffmpeg` is not recognized | Open a new terminal after installing, or restart VS Code. |
| `running scripts is disabled on this system` | Run the script with `powershell -ExecutionPolicy Bypass -File ...` as shown. |
| No stations in game | Check *Addon Options > Arma 3 Radio Stations > Stations*. At least one source must be on and have music. |

### Regenerating the placeholder music

From the repository root:

```sh
sh tools/make_demo_audio.sh demo_music
powershell -ExecutionPolicy Bypass -File tools\import_music.ps1 -Source demo_music\builtin -Target Arma3RadioStations\addons\stations -ClassPrefix A3R
powershell -ExecutionPolicy Bypass -File tools\import_music.ps1 -Source demo_music\mission -Target Arma3RadioStations\.hemtt\missions\a3r_test.VR
```

### How sync works

Every client runs a loop every 0.5 s. For each radio that is on, it works out the current track and offset from `CBA_missionTime`, so all machines agree without any audio traffic. It then plays the track locally with `say3D` (3D, attached to the object) or `playMusic` (inside your own vehicle). The server keeps only a public `a3r_station` variable on each radio and a list of radios that are on.

## Credits

Made by **Rowantrek**. Built with [HEMTT](https://hemtt.dev) and [CBA_A3](https://github.com/CBATeam/CBA_A3).

The built-in and example stations are synthesized placeholder tones.

## License

Arma 3 Radio Stations is licensed under the **[Arma Public License (APL)](https://www.bohemia.net/community/licenses/arma-public-license)**. See [LICENSE](LICENSE).

You may share and adapt it as long as you:

- **credit Rowantrek**
- **don't use it commercially**
- **use it only in Arma**

Music in mission files and music add-ons belongs to its own rights holders, not to this license.

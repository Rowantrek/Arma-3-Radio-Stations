# Steam Workshop page

The source for the Steam Workshop description. Copy everything inside the code block below into the **Description** field in Arma 3 Publisher or on the Workshop page. It uses Steam's BBCode formatting.

When publishing:

- Set **CBA_A3** as a **Required Item**, so Steam shows it and subscribes players to it.
- Use a square PNG or JPG **preview image**, 512×512, under 1 MB.
- Keep this text in sync with the README when controls or features change.

```
[h1]Arma 3 Radio Stations[/h1]
Live music radio for every vehicle, vanilla and modded, plus a placeable radio for bases and camps. Stations are synced in multiplayer: everyone in the car hears the same song at the same moment, and players who join late tune in mid-song, like real radio.

[h2]Features[/h2]
[list]
[*][b]Vehicle radios:[/b] cars, trucks, tanks, boats, helicopters and planes, including modded vehicles. Clear inside, heard in 3D from outside.
[*][b]PA mode:[/b] play the radio through the vehicle's outside speaker. Much louder, and heard much further.
[*][b]Placeable Music Radio:[/b] in Eden and Zeus (Things > Radios). Sounds like a loudspeaker.
[*][b]Live stations:[/b] looping playlists that keep playing whether anyone is listening or not.
[*][b]Volume per radio:[/b] shared with everyone who hears it.
[*][b]Multiplayer friendly:[/b] only the station, volume and PA choices go over the network. Timing comes from the synced mission clock, and players who join late are supported.
[*][b]Server and mission control:[/b] CBA settings for hearing ranges and for which music sources are allowed.
[/list]

[h2]Controls[/h2]
[b]In a vehicle (keybinds):[/b]
[list]
[*]Ctrl + ] / Ctrl + [ : next / previous station
[*]Ctrl + ; : radio on / off
[*]Ctrl + = / Ctrl + - : volume up / down
[*]Ctrl + ' : play through the PA
[/list]
Rebind them in Options > Controls > Configure Addons > Arma 3 Radio Stations.

[b]Placed radios:[/b] use the scroll menu while looking at one within 3 m.

[h2]No music included[/h2]
This mod contains [b]no audio by default[/b]. It's the radio, not the music.

Arma can't stream audio or play files from a player's own disk, so every player needs the same audio files. The music comes from:
[list]
[*][b]Missions:[/b] mission makers pack songs into the mission, and players get them automatically when they join (requires specific config in the mission file).
[*][b]Music add-on mods:[/b] separate mods whose stations show up on every radio in every mission. A ready-made template is on GitHub.
[/list]
An included import tool (in the GitHub repo) turns folders of your own music into stations in a few minutes. Only use music you have the rights to distribute.

[h2]Documentation, bugs and requests[/h2]
Full documentation for players, mission makers, server owners, music add-on makers and scripting is on GitHub:
[url=https://github.com/Rowantrek/Arma-3-Radio-Stations]github.com/Rowantrek/Arma-3-Radio-Stations[/url]

[b]Please report bugs and feature requests on [url=https://github.com/Rowantrek/Arma-3-Radio-Stations/issues]GitHub Issues[/url], not in the Workshop comments.[/b] They're tracked there, and comments here are easy to miss.

[h2]License[/h2]
Arma Public License (APL).
```

if (!hasInterface) exitWith {};

a3r_playing = [];  // [[radio, playKey, soundSource], ...] - 3D sounds this client is playing
a3r_musicKey = ""; // playKey of the in-vehicle radio playing on the music channel
a3r_musicVolume = 1; // radio volume last set with fadeMusic
a3r_missionMusicVolume = 1; // the mission's music volume, restored when the in-vehicle radio stops

[A3R_fnc_clientUpdate, 0.5] call CBA_fnc_addPerFrameHandler;

// Fires for the initial unit, after respawn and when Zeus remote-controls a unit
["unit", {[_this select 0] call A3R_fnc_addPlayerActions}, true] call CBA_fnc_addPlayerEventHandler;

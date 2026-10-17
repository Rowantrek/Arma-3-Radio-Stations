/*
 * Sets a radio's volume from any machine and shows it to the local player.
 *
 * Arguments:
 * 0: Radio object or vehicle <OBJECT>
 * 1: Volume, 0 to 1. 0.5 is the default, normal loudness; 1 is double <NUMBER>
 */
params ["_obj", "_volume"];
if (isNull _obj) exitWith {};

_volume = 0 max _volume min 1;

// Set locally right away, so quick repeated presses step from the new value before the server's update arrives
_obj setVariable ["a3r_volume", _volume];
["a3r_setVolume", [_obj, _volume]] call CBA_fnc_serverEvent;

[_obj getVariable ["a3r_station", ""], _volume, _obj getVariable ["a3r_pa", false]] call A3R_fnc_showNowPlaying;

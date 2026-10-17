/*
 * Tunes a radio from any machine and shows the result to the local player.
 *
 * Arguments:
 * 0: Radio object or vehicle <OBJECT>
 * 1: Station class or "" for off <STRING>
 */
params ["_obj", "_station"];
if (isNull _obj) exitWith {};

["a3r_setStation", [_obj, _station]] call CBA_fnc_serverEvent;
[_station] call A3R_fnc_showNowPlaying;

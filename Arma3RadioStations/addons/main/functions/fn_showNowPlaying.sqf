/*
 * Shows the station and current track to the local player.
 *
 * Arguments:
 * 0: Station class or "" for off <STRING>
 */
params ["_station"];

if (_station == "") exitWith {hintSilent "Radio off"};

private _name = getText ((["A3R_Stations", _station] call A3R_fnc_findConfig) >> "displayName");
private _now = [_station] call A3R_fnc_getTrackAt;
private _track = if (_now isEqualTo []) then {""} else {getText ((["CfgMusic", _now select 0] call A3R_fnc_findConfig) >> "name")};

hintSilent parseText format ["<t size='1.2'>%1</t><br/>%2", _name, _track];

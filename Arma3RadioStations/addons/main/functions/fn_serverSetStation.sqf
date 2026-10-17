/*
 * Server only. Tunes a radio and keeps the public list of radios that are on.
 *
 * Arguments:
 * 0: Radio object or vehicle <OBJECT>
 * 1: Station class, "random", or "" for off <STRING>
 */
params ["_obj", "_station"];
if (!isServer || {isNull _obj}) exitWith {};

// Called from object init (Eden attribute, init field): wait until settings are loaded
if (time == 0) exitWith {
    [{time > 0}, {_this call A3R_fnc_serverSetStation}, [_obj, _station]] call CBA_fnc_waitUntilAndExecute;
};

if (_station == "random") then {
    private _stations = call A3R_fnc_getStations;
    _station = if (_stations isEqualTo []) then {""} else {selectRandom _stations};
};
if (_station != "" && {!(_station in (call A3R_fnc_getStations))}) exitWith {
    diag_log format ["[A3R] Unknown radio station '%1' for %2", _station, _obj];
};

// Remember the station when turning off, so turning back on returns to it
private _old = _obj getVariable ["a3r_station", ""];
if (_station == "" && {_old != ""}) then {_obj setVariable ["a3r_lastStation", _old, true]};

_obj setVariable ["a3r_station", _station, true];

private _radios = (missionNamespace getVariable ["a3r_radios", []]) select {!isNull _x && {_x != _obj}};
if (_station != "") then {_radios pushBack _obj};
missionNamespace setVariable ["a3r_radios", _radios, true];

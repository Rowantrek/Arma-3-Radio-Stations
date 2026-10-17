/*
 * Switches a radio to the next/previous station, or off.
 *
 * Arguments:
 * 0: Radio object or vehicle <OBJECT>
 * 1: Direction: 1 next, -1 previous, 0 off <NUMBER>
 */
params ["_obj", "_dir"];

if (_dir == 0) exitWith {[_obj, ""] call A3R_fnc_setStation};

private _stations = call A3R_fnc_getStations;
if (_stations isEqualTo []) exitWith {hintSilent "No radio stations installed."};

private _count = count _stations;
private _index = _stations find (_obj getVariable ["a3r_station", ""]);
private _next = if (_index < 0) then {
    _stations select ([0, _count - 1] select (_dir < 0))
} else {
    _stations select ((_index + _dir + _count) mod _count)
};

[_obj, _next] call A3R_fnc_setStation;

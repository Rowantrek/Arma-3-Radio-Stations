/*
 * Turns a radio off, or back on to the station it was last on
 * (the first station if it has none, or that station is no longer available).
 *
 * Arguments:
 * 0: Radio object or vehicle <OBJECT>
 */
params ["_obj"];

if ((_obj getVariable ["a3r_station", ""]) != "") exitWith {[_obj, ""] call A3R_fnc_setStation};

private _stations = call A3R_fnc_getStations;
if (_stations isEqualTo []) exitWith {hintSilent "No radio stations installed."};

private _last = _obj getVariable ["a3r_lastStation", ""];
[_obj, [_stations select 0, _last] select (_last in _stations)] call A3R_fnc_setStation;

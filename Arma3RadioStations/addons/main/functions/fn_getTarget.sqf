/*
 * Returns the radio a unit can operate: its vehicle's radio, or a placed radio it looks at within 3 m.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return: Radio object or vehicle, objNull if none <OBJECT>
 */
params ["_unit"];

private _vehicle = vehicle _unit;
if (_vehicle != _unit) exitWith {
    [objNull, _vehicle] select ([_vehicle] call A3R_fnc_hasRadio)
};

private _obj = cursorObject;
if (!isNull _obj && {[_obj] call A3R_fnc_isPlacedRadio} && {_unit distance _obj < 3}) exitWith {_obj};

objNull

/*
 * Returns the placed radio a unit on foot is looking at within 3 m, for the scroll menu.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return: Radio object, objNull if none <OBJECT>
 */
params ["_unit"];
if (!isNull objectParent _unit) exitWith {objNull};

private _obj = cursorObject;
if (!isNull _obj && {[_obj] call A3R_fnc_isPlacedRadio} && {_unit distance _obj < 3}) exitWith {_obj};

objNull

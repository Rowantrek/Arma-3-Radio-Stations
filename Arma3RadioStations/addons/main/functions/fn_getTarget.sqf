/*
 * Returns the vehicle radio a unit's keybinds operate: its vehicle, if that has a radio.
 * Placed radios use the scroll menu instead (A3R_fnc_getPlacedRadio).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return: Vehicle, objNull if none <OBJECT>
 */
params ["_unit"];

private _vehicle = objectParent _unit;
if (isNull _vehicle) exitWith {objNull};

[objNull, _vehicle] select ([_vehicle] call A3R_fnc_hasRadio)

/*
 * Server only. Turns a vehicle radio's PA on or off for everyone.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: PA on <BOOL>
 */
params ["_obj", "_pa"];
if (!isServer || {isNull _obj}) exitWith {};

_obj setVariable ["a3r_pa", _pa isEqualTo true, true];

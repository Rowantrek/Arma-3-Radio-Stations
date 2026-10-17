/*
 * Server only. Sets a radio's volume for everyone.
 *
 * Arguments:
 * 0: Radio object or vehicle <OBJECT>
 * 1: Volume, 0 to 1. 0.5 is the default, normal loudness; 1 is double <NUMBER>
 */
params ["_obj", "_volume"];
if (!isServer || {isNull _obj}) exitWith {};

_obj setVariable ["a3r_volume", 0 max _volume min 1, true];

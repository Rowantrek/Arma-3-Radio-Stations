/*
 * Turns a radio's volume up or down by a step.
 *
 * Arguments:
 * 0: Radio object or vehicle <OBJECT>
 * 1: Step, e.g. 0.1 or -0.1 <NUMBER>
 */
params ["_obj", "_step"];

private _volume = _obj getVariable ["a3r_volume", 1];
[_obj, round ((_volume + _step) * 10) / 10] call A3R_fnc_setVolume;

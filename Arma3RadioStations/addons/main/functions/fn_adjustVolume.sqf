/*
 * Turns a radio's volume up or down one level: 0, 5%, then 10% steps up to 100%.
 *
 * Arguments:
 * 0: Radio object or vehicle <OBJECT>
 * 1: Direction: positive up, negative down, e.g. 0.1 or -0.1 <NUMBER>
 */
params ["_obj", "_step"];

private _levels = [0, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1];
private _volume = _obj getVariable ["a3r_volume", 0.5];

// Nearest level, so a volume set by a script between levels still steps sensibly
private _index = 0;
{
    if (abs (_x - _volume) < abs ((_levels select _index) - _volume)) then {_index = _forEachIndex};
} forEach _levels;
_index = 0 max (_index + ([-1, 1] select (_step > 0))) min (count _levels - 1);

[_obj, _levels select _index] call A3R_fnc_setVolume;

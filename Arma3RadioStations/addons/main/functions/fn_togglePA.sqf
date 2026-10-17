/*
 * Switches a vehicle radio between its normal outside sound and its PA, which is louder and
 * heard further outside. Occupants hear no difference. Placed radios have no PA.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 */
params ["_obj"];
if (isNull _obj || {[_obj] call A3R_fnc_isPlacedRadio}) exitWith {};

private _pa = !(_obj getVariable ["a3r_pa", false]);

// Set locally right away, like the volume, so a quick second press toggles back
_obj setVariable ["a3r_pa", _pa];
["a3r_setPA", [_obj, _pa]] call CBA_fnc_serverEvent;

[_obj getVariable ["a3r_station", ""], _obj getVariable ["a3r_volume", 0.5], _pa] call A3R_fnc_showNowPlaying;

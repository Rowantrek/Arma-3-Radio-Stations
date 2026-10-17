/*
 * Adds the placed-radio scroll-menu actions to a player unit. They show while the unit is on foot
 * looking at a placed radio within 3 m. Vehicle radios use keybinds only.
 *
 * Off: "turn on". On: next, previous, volume up/down, turn off.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 */
params ["_unit"];
if (_unit getVariable ["a3r_actionsAdded", false]) exitWith {};
_unit setVariable ["a3r_actionsAdded", true];

private _isOn = "_this == _target && {private _radio = [_this] call A3R_fnc_getPlacedRadio; !isNull _radio && {(_radio getVariable ['a3r_station', '']) != ''}}";
private _isOff = "_this == _target && {private _radio = [_this] call A3R_fnc_getPlacedRadio; !isNull _radio && {(_radio getVariable ['a3r_station', '']) == ''}}";

// [title, code, priority, hideOnUse, condition]. Station and volume actions keep the menu open for repeated use.
{
    _x params ["_title", "_code", "_priority", "_hide", "_condition"];
    _unit addAction [format ["<t color='#9fd3ff'>Radio: %1</t>", _title], _code, nil, _priority, false, _hide, "", _condition];
} forEach [
    ["turn on", {[[_this select 1] call A3R_fnc_getPlacedRadio] call A3R_fnc_togglePower}, 0.4, true, _isOff],
    ["next station", {[[_this select 1] call A3R_fnc_getPlacedRadio, 1] call A3R_fnc_cycleStation}, 0.4, false, _isOn],
    ["previous station", {[[_this select 1] call A3R_fnc_getPlacedRadio, -1] call A3R_fnc_cycleStation}, 0.39, false, _isOn],
    ["volume up", {[[_this select 1] call A3R_fnc_getPlacedRadio, 0.1] call A3R_fnc_adjustVolume}, 0.38, false, _isOn],
    ["volume down", {[[_this select 1] call A3R_fnc_getPlacedRadio, -0.1] call A3R_fnc_adjustVolume}, 0.37, false, _isOn],
    ["turn off", {[[_this select 1] call A3R_fnc_getPlacedRadio] call A3R_fnc_togglePower}, 0.36, true, _isOn]
];

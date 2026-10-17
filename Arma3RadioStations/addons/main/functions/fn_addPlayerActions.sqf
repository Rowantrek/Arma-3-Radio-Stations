/*
 * Adds the radio scroll-menu actions to a player unit. They show while the unit
 * is in a vehicle with a radio, or is looking at a placed radio nearby.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 */
params ["_unit"];
if (_unit getVariable ["a3r_actionsAdded", false]) exitWith {};
_unit setVariable ["a3r_actionsAdded", true];

_unit addAction [
    "<t color='#9fd3ff'>Radio: next station</t>",
    {[[_this select 1] call A3R_fnc_getTarget, 1] call A3R_fnc_cycleStation},
    nil, 0.4, false, true, "",
    "_this == _target && {!isNull ([_this] call A3R_fnc_getTarget)}"
];

_unit addAction [
    "<t color='#9fd3ff'>Radio: turn off</t>",
    {[[_this select 1] call A3R_fnc_getTarget, 0] call A3R_fnc_cycleStation},
    nil, 0.39, false, true, "",
    "_this == _target && {(([_this] call A3R_fnc_getTarget) getVariable ['a3r_station', '']) != ''}"
];

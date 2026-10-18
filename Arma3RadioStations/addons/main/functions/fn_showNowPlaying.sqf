/*
 * Shows the radio's station, current track and volume to the local player for 3 seconds.
 * Used for station, volume and PA changes, and when the radio you're in starts a new track.
 *
 * Arguments:
 * 0: Station class or "" for off <STRING>
 * 1: Volume, 0 to 1 <NUMBER>
 * 2: Playing through the vehicle's PA (optional, default false) <BOOL>
 */
params ["_station", "_volume", ["_pa", false]];

private _text = if (_station == "") then {
    "<t size='1.2'>Radio off</t>"
} else {
    private _name = getText ((["A3R_Stations", _station] call A3R_fnc_findConfig) >> "displayName");
    private _now = [_station] call A3R_fnc_getTrackAt;
    // Intermission clips (jingles, adverts) aren't named in the hint
    private _track = if (_now isEqualTo [] || {_now select 3}) then {""} else {getText ((["CfgMusic", _now select 0] call A3R_fnc_findConfig) >> "name")};
    format ["<t size='1.2'>%1</t><br/>%2", _name, _track]
};
hintSilent parseText format ["%1<br/><t size='0.9'>Volume %2%3</t>", _text, str round (_volume * 100) + "%", ["", " · PA"] select _pa];

// Clear it after 3 s, unless a newer radio hint has replaced it
a3r_hintId = (missionNamespace getVariable ["a3r_hintId", 0]) + 1;
[{if (a3r_hintId == _this) then {hintSilent ""}}, a3r_hintId, 3] call CBA_fnc_waitAndExecute;

/*
 * Returns what a station is playing right now.
 *
 * Stations are "live": every machine derives the same track and position from the
 * synced CBA mission clock, so only the chosen station needs to go over the network.
 * Each station is offset by a seed from its name so stations don't all change track together.
 *
 * Arguments:
 * 0: Station class <STRING>
 *
 * Return: [track class, offset in seconds, play key] or [] if the station has no playable tracks.
 *         The play key is unique per track play, including repeats of the same track.
 */
params ["_station"];

private _schedule = a3r_schedules get _station;
if (isNil "_schedule") then {
    private _tracks = getArray ((["A3R_Stations", _station] call A3R_fnc_findConfig) >> "tracks") select {
        getNumber ((["CfgMusic", _x] call A3R_fnc_findConfig) >> "duration") > 0
        && {isClass (["CfgSounds", _x] call A3R_fnc_findConfig)}
    };
    private _durations = _tracks apply {getNumber ((["CfgMusic", _x] call A3R_fnc_findConfig) >> "duration")};
    private _total = 0;
    {_total = _total + _x} forEach _durations;
    private _seed = 0;
    {_seed = _seed + _x * (_forEachIndex + 1)} forEach toArray _station;

    _schedule = [_tracks, _durations, _total, _seed];
    a3r_schedules set [_station, _schedule];
};
_schedule params ["_tracks", "_durations", "_total", "_seed"];
if (_tracks isEqualTo []) exitWith {[]};

private _time = CBA_missionTime + _seed;
private _cycle = floor (_time / _total);
private _t = _time - _cycle * _total;
private _i = 0;
while {_i < count _durations - 1 && {_t >= _durations select _i}} do {
    _t = _t - (_durations select _i);
    _i = _i + 1;
};

[_tracks select _i, _t, format ["%1:%2:%3", _station, _cycle, _i]]

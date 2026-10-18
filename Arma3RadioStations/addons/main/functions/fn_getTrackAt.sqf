/*
 * Returns what a station is playing right now.
 *
 * Stations are "live": every machine derives the same track and position from the
 * synced CBA mission clock, so only the chosen station needs to go over the network.
 * Each station is offset by a seed from its name so stations don't all change track together.
 * A station with intermissions[] plays one clip after every intermissionEvery (default 2) songs;
 * songs and clips each cycle through their own list.
 *
 * Arguments:
 * 0: Station class <STRING>
 *
 * Return: [track class, offset in seconds, play key, is intermission] or [] if the station has no playable tracks.
 *         The play key is unique per track play, including repeats of the same track.
 */
params ["_station"];

private _schedule = a3r_schedules get _station;
if (isNil "_schedule") then {
    private _config = ["A3R_Stations", _station] call A3R_fnc_findConfig;
    private _playable = {
        _this select {
            getNumber ((["CfgMusic", _x] call A3R_fnc_findConfig) >> "duration") > 0
            && {isClass (["CfgSounds", _x] call A3R_fnc_findConfig)}
        }
    };
    private _songs = getArray (_config >> "tracks") call _playable;
    private _clips = getArray (_config >> "intermissions") call _playable;
    private _every = [2, floor getNumber (_config >> "intermissionEvery")] select isNumber (_config >> "intermissionEvery");

    // Without intermissions the order is the track list, so existing stations keep their schedule
    private _tracks = +_songs;
    private _isClip = _songs apply {false};
    if (_songs isNotEqualTo [] && {_clips isNotEqualTo []} && {_every > 0}) then {
        private _gcd = {
            params ["_a", "_b"];
            while {_b > 0} do {
                private _r = _a mod _b;
                _a = _b;
                _b = _r;
            };
            _a
        };
        // One block is _every songs and a clip. Enough blocks that both lists end together,
        // so every cycle sounds the same; capped so huge playlists don't build a huge schedule
        private _songCount = count _songs;
        private _clipCount = count _clips;
        private _songBlocks = _songCount / ([_songCount, _every] call _gcd);
        private _blocks = (_songBlocks * _clipCount / ([_songBlocks, _clipCount] call _gcd)) min 1000;
        _tracks = [];
        _isClip = [];
        for "_block" from 0 to _blocks - 1 do {
            for "_song" from 0 to _every - 1 do {
                _tracks pushBack (_songs select ((_block * _every + _song) mod _songCount));
                _isClip pushBack false;
            };
            _tracks pushBack (_clips select (_block mod _clipCount));
            _isClip pushBack true;
        };
    };

    private _starts = [];
    private _total = 0;
    {
        _starts pushBack _total;
        _total = _total + getNumber ((["CfgMusic", _x] call A3R_fnc_findConfig) >> "duration");
    } forEach _tracks;
    private _seed = 0;
    {_seed = _seed + _x * (_forEachIndex + 1)} forEach toArray _station;

    _schedule = [_tracks, _isClip, _starts, _total, _seed];
    a3r_schedules set [_station, _schedule];
};
_schedule params ["_tracks", "_isClip", "_starts", "_total", "_seed"];
if (_tracks isEqualTo []) exitWith {[]};

private _time = CBA_missionTime + _seed;
private _cycle = floor (_time / _total);
private _t = _time - _cycle * _total;

// Last track that started at or before _t (binary search: schedules with intermissions can be long)
private _low = 0;
private _high = count _starts - 1;
while {_low < _high} do {
    private _mid = ceil ((_low + _high) / 2);
    if ((_starts select _mid) <= _t) then {_low = _mid} else {_high = _mid - 1};
};

[_tracks select _low, _t - (_starts select _low), format ["%1:%2:%3", _station, _cycle, _low], _isClip select _low]

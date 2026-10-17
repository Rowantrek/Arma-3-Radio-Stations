/*
 * Per-client sound loop, run every 0.5 s. Starts, switches and stops the local sounds of
 * every radio that is on, based only on the networked station/volume variables and the synced clock.
 *
 * - The radio of the vehicle you sit in plays on the music channel: clear rather than
 *   muffled by the cabin, and follows the player's music volume. Radio volume uses fadeMusic.
 * - Placed radios play with playSound3D, which has a volume but stays where it started,
 *   so the sound restarts if the radio is moved.
 * - Vehicles heard from outside play with say3D, which follows the vehicle but has no volume,
 *   so a lower volume shortens how far they are heard instead.
 */
private _unit = call CBA_fnc_currentUnit;
private _vehicle = vehicle _unit;
private _ear = AGLToASL positionCameraToWorld [0, 0, 0];

// Sources are playSound3D ids (numbers) or say3D sound objects
private _stop = {
    if (_this isEqualType 0) then {stopSound _this} else {deleteVehicle _this};
};

// Radios that were deleted: stop their sound
{
    if (isNull (_x select 0)) then {(_x select 2) call _stop};
} forEach a3r_playing;
private _playing = a3r_playing select {!isNull (_x select 0)};

// Radios that are on, plus ones we are still playing (they may have just been turned off)
private _objects = (missionNamespace getVariable ["a3r_radios", []]) + (_playing apply {_x select 0});
_objects = (_objects arrayIntersect _objects) select {!isNull _x};

private _nowPlaying = [];
private _music = [];
private _musicVolume = 1;

{
    private _obj = _x;
    private _station = _obj getVariable ["a3r_station", ""];
    private _volume = _obj getVariable ["a3r_volume", 1];
    private _isPlaced = [_obj] call A3R_fnc_isPlacedRadio;
    private _range = [a3r_vehicleRange * _volume, a3r_radioRange] select _isPlaced;

    private _want = [];
    if (_station != "" && {alive _obj}) then {
        if (!_isPlaced && {_obj == _vehicle}) then {
            _music = [_station] call A3R_fnc_getTrackAt;
            _musicVolume = _volume;
        } else {
            if (_volume > 0 && {(getPosASL _obj) distance _ear < _range}) then {
                _want = [_station] call A3R_fnc_getTrackAt;
            };
        };
    };

    private _index = _playing findIf {(_x select 0) == _obj};
    private _current = if (_index >= 0) then {_playing select _index} else {[_obj, "", objNull, []]};
    _current params ["", "_key", "_source", "_pos"];

    if (_want isEqualTo []) then {
        _source call _stop;
    } else {
        _want params ["_track", "_offset", "_playKey"];
        // Restart on a new track or volume, or when a placed radio has moved
        private _wantKey = format ["%1|%2", _playKey, [_range, _volume] select _isPlaced];
        if (_wantKey == _key && {!_isPlaced || {(getPosASL _obj) distance _pos < 1}}) then {
            _nowPlaying pushBack _current;
        } else {
            _source call _stop;
            private _newSource = if (_isPlaced) then {
                playSound3D [[_track] call A3R_fnc_getSoundFile, _obj, false, getPosASL _obj, _volume, 1, _range, _offset, true]
            } else {
                _obj say3D [_track, _range, 1, false, _offset]
            };
            _nowPlaying pushBack [_obj, _wantKey, _newSource, getPosASL _obj];
        };
    };
} forEach _objects;

a3r_playing = _nowPlaying;

private _musicKey = if (_music isEqualTo []) then {""} else {_music select 2};
if (_musicKey != a3r_musicKey) then {
    if (_musicKey == "") then {
        playMusic "";
        0 fadeMusic a3r_missionMusicVolume; // give the mission its music volume back
    } else {
        if (a3r_musicKey == "") then {a3r_missionMusicVolume = musicVolume};
        0 fadeMusic _musicVolume;
        a3r_musicVolume = _musicVolume;
        playMusic [_music select 0, _music select 1];
    };
    a3r_musicKey = _musicKey;
};
if (_musicKey != "" && {_musicVolume != a3r_musicVolume}) then {
    0.3 fadeMusic _musicVolume;
    a3r_musicVolume = _musicVolume;
};

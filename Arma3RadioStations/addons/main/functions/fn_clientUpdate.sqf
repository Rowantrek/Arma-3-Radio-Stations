/*
 * Per-client sound loop, run every 0.5 s. Starts, switches and stops the local sounds of
 * every radio that is on, based only on the networked station variable and the synced clock.
 *
 * - The radio of the vehicle you sit in plays on the music channel: clear rather than
 *   muffled by the cabin, and follows the player's music volume.
 * - Every other radio is a 3D sound attached to its object.
 */
private _unit = call CBA_fnc_currentUnit;
private _vehicle = vehicle _unit;
private _ear = AGLToASL positionCameraToWorld [0, 0, 0];

// Radios that were deleted: stop their sound
{
    if (isNull (_x select 0)) then {deleteVehicle (_x select 2)};
} forEach a3r_playing;
private _playing = a3r_playing select {!isNull (_x select 0)};

// Radios that are on, plus ones we are still playing (they may have just been turned off)
private _objects = (missionNamespace getVariable ["a3r_radios", []]) + (_playing apply {_x select 0});
_objects = (_objects arrayIntersect _objects) select {!isNull _x};

private _nowPlaying = [];
private _music = [];

{
    private _obj = _x;
    private _station = _obj getVariable ["a3r_station", ""];
    private _isPlaced = [_obj] call A3R_fnc_isPlacedRadio;
    private _range = [a3r_vehicleRange, a3r_radioRange] select _isPlaced;

    private _want = [];
    if (_station != "" && {alive _obj}) then {
        if (!_isPlaced && {_obj == _vehicle}) then {
            _music = [_station] call A3R_fnc_getTrackAt;
        } else {
            if ((getPosASL _obj) distance _ear < _range) then {
                _want = [_station] call A3R_fnc_getTrackAt;
            };
        };
    };

    private _index = _playing findIf {(_x select 0) == _obj};
    private _current = if (_index >= 0) then {_playing select _index} else {[_obj, "", objNull]};
    _current params ["", "_key", "_source"];

    if (_want isEqualTo []) then {
        deleteVehicle _source;
    } else {
        _want params ["_track", "_offset", "_wantKey"];
        if (_wantKey == _key) then {
            _nowPlaying pushBack _current;
        } else {
            deleteVehicle _source;
            private _newSource = _obj say3D [_track, _range, 1, false, _offset];
            _nowPlaying pushBack [_obj, _wantKey, _newSource];
        };
    };
} forEach _objects;

a3r_playing = _nowPlaying;

private _musicKey = if (_music isEqualTo []) then {""} else {_music select 2};
if (_musicKey != a3r_musicKey) then {
    if (_musicKey == "") then {
        playMusic "";
    } else {
        playMusic [_music select 0, _music select 1];
    };
    a3r_musicKey = _musicKey;
};

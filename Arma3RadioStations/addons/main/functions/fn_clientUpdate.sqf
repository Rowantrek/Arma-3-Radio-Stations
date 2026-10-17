/*
 * Per-client sound loop, run every 0.5 s. Starts, switches and stops the local sounds of
 * every radio that is on, based only on the networked station/volume variables and the synced clock.
 *
 * Every radio plays on the effects channel, so the player's effects volume applies the same
 * inside and outside a vehicle.
 * - The radio of the vehicle you sit in plays with playSoundUI: not positional, so it's clear
 *   rather than muffled by the cabin.
 * - Placed radios play with playSound3D, which has a volume but stays where it started,
 *   so the sound restarts if the radio is moved.
 * - Vehicles heard from outside play with say3D, which follows the vehicle but has no volume,
 *   so a lower volume shortens how far they are heard instead.
 */
private _unit = call CBA_fnc_currentUnit;
private _vehicle = vehicle _unit;
private _ear = AGLToASL positionCameraToWorld [0, 0, 0];

// Sources are playSoundUI/playSound3D ids (numbers) or say3D sound objects
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

{
    private _obj = _x;
    private _station = _obj getVariable ["a3r_station", ""];
    // The volume knob goes 0-1 with 0.5 as the default: played at double, so 0.5 is normal loudness and 1 is twice that
    private _volume = 2 * (_obj getVariable ["a3r_volume", 0.5]);
    private _isPlaced = [_obj] call A3R_fnc_isPlacedRadio;
    private _isInside = !_isPlaced && {_obj == _vehicle};
    private _range = [a3r_vehicleRange * _volume, a3r_radioRange] select _isPlaced;

    private _want = [];
    if (_station != "" && {alive _obj} && {_volume > 0} && {_isInside || {(getPosASL _obj) distance _ear < _range}}) then {
        _want = [_station] call A3R_fnc_getTrackAt;
    };

    private _index = _playing findIf {(_x select 0) == _obj};
    private _current = if (_index >= 0) then {_playing select _index} else {[_obj, "", objNull, []]};
    _current params ["", "_key", "_source", "_pos"];

    if (_want isEqualTo []) then {
        _source call _stop;
    } else {
        _want params ["_track", "_offset", "_playKey"];
        // Restart on a new track, getting in or out, a volume change, or when a placed radio has moved
        private _wantKey = format ["%1|%2|%3", _playKey, _isInside, [_range, _volume] select (_isPlaced || _isInside)];
        if (_wantKey == _key && {!_isPlaced || {(getPosASL _obj) distance _pos < 1}}) then {
            _nowPlaying pushBack _current;
        } else {
            _source call _stop;
            private _newSource = call {
                if (_isInside) exitWith {
                    playSoundUI [[_track] call A3R_fnc_getSoundFile, _volume, 1, true, _offset]
                };
                if (_isPlaced) exitWith {
                    playSound3D [[_track] call A3R_fnc_getSoundFile, _obj, false, getPosASL _obj, _volume, 1, _range, _offset, true]
                };
                _obj say3D [_track, _range, 1, false, _offset]
            };
            _nowPlaying pushBack [_obj, _wantKey, _newSource, getPosASL _obj];
        };
    };
} forEach _objects;

a3r_playing = _nowPlaying;

/*
 * Per-client sound loop, run every 0.5 s. Starts, switches and stops the local sounds of
 * every radio that is on, based only on the networked station/volume variables and the synced clock.
 *
 * Every radio plays on the effects channel, so the player's effects volume applies the same
 * inside and outside a vehicle.
 * - The radio of the vehicle you sit in plays with playSoundUI: not positional, so it's clear
 *   rather than muffled by the cabin.
 * - Everything heard from outside plays with say3D, which follows its object but has no volume,
 *   so the volume knob sets how far it is heard instead. Loudness comes from the CfgSounds volume:
 *   1.25 for vehicles, or 3.25 (the track's _PA variant) for a vehicle's PA and for placed radios,
 *   which always sound like a PA.
 */
private _unit = call CBA_fnc_currentUnit;
private _vehicle = vehicle _unit;
private _ear = AGLToASL positionCameraToWorld [0, 0, 0];

// Sources are playSoundUI ids (numbers) or say3D sound objects
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
    // PA: a vehicle's outside speaker, louder (the track's _PA sound variant) with its own range. Placed radios always use it
    private _isPA = _isPlaced || {_obj getVariable ["a3r_pa", false]};
    private _range = ([a3r_vehicleRange, a3r_paRange] select _isPA) * _volume;

    private _want = [];
    if (_station != "" && {alive _obj} && {_volume > 0} && {_isInside || {(getPosASL _obj) distance _ear < _range}}) then {
        _want = [_station] call A3R_fnc_getTrackAt;
    };

    private _index = _playing findIf {(_x select 0) == _obj};
    private _current = if (_index >= 0) then {_playing select _index} else {[_obj, "", objNull]};
    _current params ["", "_key", "_source"];

    if (_want isEqualTo []) then {
        _source call _stop;
    } else {
        _want params ["_track", "_offset", "_playKey"];
        // Restart on a new track, getting in or out, a volume change or PA on/off (occupants don't hear the PA)
        private _wantKey = format ["%1|%2|%3", _playKey, _isInside, [[_range, _isPA], _volume] select _isInside];
        if (_wantKey == _key) then {
            _nowPlaying pushBack _current;
        } else {
            _source call _stop;
            // The radio you're in moved on to its next song or intermission: show it. A station
            // change already showed the hint itself, so only the same station counts
            if (_isInside && {_key != ""} && {(_key splitString "|") select 0 != _playKey} && {(_key splitString ":") select 0 == _station}) then {
                [_station, _obj getVariable ["a3r_volume", 0.5], _obj getVariable ["a3r_pa", false]] call A3R_fnc_showNowPlaying;
            };
            private _newSource = call {
                if (_isInside) exitWith {
                    playSoundUI [[_track] call A3R_fnc_getSoundFile, _volume, 1, true, _offset]
                };
                // Music add-ons imported before PA existed have no _PA variant: fall back to the normal sound
                private _sound = _track + "_PA";
                if !(_isPA && {isClass (["CfgSounds", _sound] call A3R_fnc_findConfig)}) then {_sound = _track};
                _obj say3D [_sound, _range, 1, false, _offset]
            };
            _nowPlaying pushBack [_obj, _wantKey, _newSource];
        };
    };
} forEach _objects;

a3r_playing = _nowPlaying;

/*
 * Returns a track's audio file in the form playSoundUI (and playSound3D) need: an absolute path for
 * mission files, and an addon path without the leading backslash for addon files.
 *
 * Arguments:
 * 0: Track class <STRING>
 *
 * Return: File path <STRING>
 */
params ["_track"];

private _file = a3r_soundFileCache get _track;
if (isNil "_file") then {
    private _cfg = missionConfigFile >> "CfgSounds" >> _track;
    if (isClass _cfg) then {
        _file = getArray (_cfg >> "sound") param [0, ""];
        // In description.ext a leading @ or \ points into an addon, anything else is relative to the mission
        _file = if (_file select [0, 1] in ["@", "\"]) then {_file select [1]} else {getMissionPath _file};
    } else {
        _file = getArray (configFile >> "CfgSounds" >> _track >> "sound") param [0, ""];
        if (_file select [0, 1] == "\") then {_file = _file select [1]};
    };
    a3r_soundFileCache set [_track, _file];
};

_file

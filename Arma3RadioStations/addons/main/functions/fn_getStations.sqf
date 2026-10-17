/*
 * Returns all stations that have at least one playable track, filtered by the
 * station source settings. Order: mission stations, built-in stations, add-on stations.
 *
 * Sources:
 * - Mission:  A3R_Stations in the mission's description.ext
 * - Built-in: A3R_Stations classes from the a3r_stations addon
 * - Add-on:   A3R_Stations classes from any other addon (music packs)
 *
 * Return: Station classes <ARRAY of STRINGs>
 */
private _flags = [
    missionNamespace getVariable ["a3r_missionStations", true],
    missionNamespace getVariable ["a3r_builtInStations", true],
    missionNamespace getVariable ["a3r_addonStations", true]
];
_flags params ["_useMission", "_useBuiltIn", "_useAddons"];

private _stations = a3r_stationsCache get str _flags;
if (isNil "_stations") then {
    _stations = [];
    if (_useMission) then {
        {
            _stations pushBackUnique configName _x;
        } forEach ("isArray (_x >> 'tracks')" configClasses (missionConfigFile >> "A3R_Stations"));
    };

    private _builtIn = [];
    private _addons = [];
    {
        if ("a3r_stations" in configSourceAddonList _x) then {
            _builtIn pushBack configName _x;
        } else {
            _addons pushBack configName _x;
        };
    } forEach ("isArray (_x >> 'tracks')" configClasses (configFile >> "A3R_Stations"));
    if (_useBuiltIn) then {{_stations pushBackUnique _x} forEach _builtIn};
    if (_useAddons) then {{_stations pushBackUnique _x} forEach _addons};

    _stations = _stations select {([_x] call A3R_fnc_getTrackAt) isNotEqualTo []};
    a3r_stationsCache set [str _flags, _stations];
};

+_stations

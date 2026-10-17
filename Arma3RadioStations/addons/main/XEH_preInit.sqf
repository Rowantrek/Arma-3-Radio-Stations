a3r_schedules = createHashMap;
a3r_radioClassCache = createHashMap;
a3r_stationsCache = createHashMap;

// Station sources. Force these per server (server settings) or per mission (Eden > Addon Options).
[
    "a3r_builtInStations", "CHECKBOX",
    ["Built-in stations", "Stations that come with Arma 3 Radio Stations."],
    ["Arma 3 Radio Stations", "Stations"], true, 1
] call CBA_fnc_addSetting;

[
    "a3r_missionStations", "CHECKBOX",
    ["Mission stations", "Stations defined in the mission's description.ext, with music in the mission folder."],
    ["Arma 3 Radio Stations", "Stations"], true, 1
] call CBA_fnc_addSetting;

[
    "a3r_addonStations", "CHECKBOX",
    ["Add-on mod stations", "Stations from music add-on mods."],
    ["Arma 3 Radio Stations", "Stations"], true, 1
] call CBA_fnc_addSetting;

[
    "a3r_vehicleRadios", "CHECKBOX",
    ["Vehicle radios", "Cars, tanks, boats and aircraft have a radio."],
    "Arma 3 Radio Stations", true, 1
] call CBA_fnc_addSetting;

[
    "a3r_radioRange", "SLIDER",
    ["Placed radio range", "Distance in metres a placed radio can be heard."],
    "Arma 3 Radio Stations", [5, 200, 40, 0], 1
] call CBA_fnc_addSetting;

[
    "a3r_vehicleRange", "SLIDER",
    ["Vehicle radio range (outside)", "Distance in metres a vehicle radio can be heard from outside. 0 = only occupants hear it."],
    "Arma 3 Radio Stations", [0, 100, 20, 0], 1
] call CBA_fnc_addSetting;

if (isServer) then {
    ["a3r_setStation", {_this call A3R_fnc_serverSetStation}] call CBA_fnc_addEventHandler;
};

if (hasInterface) then {
    // Default keys: Ctrl+] next, Ctrl+[ previous, Ctrl+\ off. Rebind under Configure > Controls > Configure Addons.
    {
        _x params ["_id", "_name", "_dir", "_dik"];
        [
            "Arma 3 Radio Stations", _id, _name,
            compile format ["
                private _target = [call CBA_fnc_currentUnit] call A3R_fnc_getTarget;
                if (isNull _target) exitWith {false};
                [_target, %1] call A3R_fnc_cycleStation;
                true
            ", _dir],
            "", [_dik, [false, true, false]]
        ] call CBA_fnc_addKeybind;
    } forEach [
        ["a3r_next", "Next station", 1, 0x1B],
        ["a3r_prev", "Previous station", -1, 0x1A],
        ["a3r_off", "Turn radio off", 0, 0x2B]
    ];
};

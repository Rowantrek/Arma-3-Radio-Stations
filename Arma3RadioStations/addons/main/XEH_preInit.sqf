a3r_schedules = createHashMap;
a3r_radioClassCache = createHashMap;
a3r_stationsCache = createHashMap;
a3r_soundFileCache = createHashMap;

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
    "a3r_paRange", "SLIDER",
    ["PA range", "Distance in metres a vehicle's PA, and every placed radio, can be heard at 50% radio volume. The volume knob scales it: 100% doubles it."],
    "Arma 3 Radio Stations", [0, 300, 50, 0], 1
] call CBA_fnc_addSetting;

[
    "a3r_vehicleRange", "SLIDER",
    ["Vehicle radio range (outside)", "Distance in metres a vehicle radio (PA off) can be heard from outside at 50% radio volume. The volume knob scales it: 100% doubles it. 0 = only occupants hear it."],
    "Arma 3 Radio Stations", [0, 100, 20, 0], 1
] call CBA_fnc_addSetting;

if (isServer) then {
    ["a3r_setStation", {_this call A3R_fnc_serverSetStation}] call CBA_fnc_addEventHandler;
    ["a3r_setVolume", {_this call A3R_fnc_serverSetVolume}] call CBA_fnc_addEventHandler;
    ["a3r_setPA", {_this call A3R_fnc_serverSetPA}] call CBA_fnc_addEventHandler;
};

if (hasInterface) then {
    // Vehicle radios only; placed radios use the scroll menu.
    // Default keys: Ctrl+] next, Ctrl+[ previous, Ctrl+; on/off, Ctrl+= louder, Ctrl+- quieter, Ctrl+' PA.
    // Rebind under Configure > Controls > Configure Addons.
    {
        _x params ["_id", "_name", "_action", "_dik"];
        [
            "Arma 3 Radio Stations", _id, _name,
            compile format ["
                private _target = [call CBA_fnc_currentUnit] call A3R_fnc_getTarget;
                if (isNull _target) exitWith {false};
                %1;
                true
            ", _action],
            "", [_dik, [false, true, false]]
        ] call CBA_fnc_addKeybind;
    } forEach [
        ["a3r_next", "Next station", "[_target, 1] call A3R_fnc_cycleStation", 0x1B],
        ["a3r_prev", "Previous station", "[_target, -1] call A3R_fnc_cycleStation", 0x1A],
        ["a3r_power", "Turn radio on/off", "[_target] call A3R_fnc_togglePower", 0x27],
        ["a3r_volUp", "Volume up", "[_target, 0.1] call A3R_fnc_adjustVolume", 0x0D],
        ["a3r_volDown", "Volume down", "[_target, -0.1] call A3R_fnc_adjustVolume", 0x0C],
        ["a3r_pa", "Play through PA (vehicles)", "[_target] call A3R_fnc_togglePA", 0x28]
    ];
};

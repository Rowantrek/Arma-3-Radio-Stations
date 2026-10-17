#include "script_version.hpp"

class CfgPatches {
    class a3r_main {
        name = "Arma 3 Radio Stations";
        author = "Rowantrek";
        units[] = {"A3R_Radio_FM"};
        weapons[] = {};
        requiredVersion = 2.18;
        requiredAddons[] = {"A3_Data_F_Decade_Loadorder", "cba_main", "cba_settings", "cba_keybinding"};
        version = MAJOR.MINOR; // YYYY.MM, see script_version.hpp
        versionStr = VERSION_STR;
        versionAr[] = {MAJOR, MINOR, PATCHLVL, BUILD};
    };
};

class Extended_PreInit_EventHandlers {
    class a3r_main {
        init = "call compileScript ['\z\a3r\addons\main\XEH_preInit.sqf']";
    };
};

class Extended_PostInit_EventHandlers {
    class a3r_main {
        init = "call compileScript ['\z\a3r\addons\main\XEH_postInit.sqf']";
    };
};

class CfgFunctions {
    class A3R {
        class main {
            file = "\z\a3r\addons\main\functions";
            class addPlayerActions {};
            class adjustVolume {};
            class clientUpdate {};
            class cycleStation {};
            class findConfig {};
            class getSoundFile {};
            class getStations {};
            class getTarget {};
            class getTrackAt {};
            class hasRadio {};
            class isPlacedRadio {};
            class serverSetStation {};
            class serverSetVolume {};
            class setStation {};
            class setVolume {};
            class showNowPlaying {};
        };
    };
};

// Stations come from the built-in addon (addons/stations), a mission's description.ext
// (.hemtt/missions/a3r_test.VR) or music add-on mods (AddonTemplate/ in the repository). Each class:
//   displayName = "Station name";
//   tracks[] = {"TrackClass", ...};   // each track in both CfgSounds and CfgMusic, with duration in CfgMusic
class A3R_Stations {};

class CfgEditorSubcategories {
    class A3R_Radios {
        displayName = "Radios";
    };
};

class CfgVehicles {
    class Land_FMradio_F;
    class A3R_Radio_FM: Land_FMradio_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "Music Radio";
        editorCategory = "EdCat_Things";
        editorSubcategory = "A3R_Radios";
        a3r_isRadio = 1; // any object class with this property works as a placeable radio

        class Attributes {
            class a3r_station {
                displayName = "Radio station";
                tooltip = "Station to play at mission start: a station class name (e.g. A3R_PulseFM), 'random', or empty for off.";
                property = "a3r_station";
                control = "Edit";
                typeName = "STRING";
                defaultValue = "''";
                expression = "if (isServer && {!is3DEN} && {_value != ''}) then {[_this, _value] call A3R_fnc_serverSetStation}";
            };
            class a3r_volume {
                displayName = "Radio volume";
                tooltip = "Volume at mission start. Players can change it in game.";
                property = "a3r_volume";
                control = "Slider";
                typeName = "NUMBER";
                defaultValue = "1";
                expression = "if (isServer && {!is3DEN} && {_value != 1}) then {[_this, _value] call A3R_fnc_serverSetVolume}";
            };
        };
    };
};

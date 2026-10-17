// Built-in stations. Regenerate from a music folder with (run from the repository root):
//   powershell -ExecutionPolicy Bypass -File tools\import_music.ps1 -Source <music folder> -Target Arma3RadioStations\addons\stations -ClassPrefix A3R
// Servers and missions can switch these off with the "Built-in stations" setting.

class CfgPatches {
    class a3r_stations {
        name = "Arma 3 Radio Stations - Built-in stations";
        author = "Rowantrek";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.18;
        requiredAddons[] = {"a3r_main"};
    };
};

class CfgSounds {
    #include "cfgSounds.hpp"
};

class CfgMusic {
    #include "cfgMusic.hpp"
};

class A3R_Stations {
    #include "stations.hpp"
};

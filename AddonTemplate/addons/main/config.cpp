// Music add-on for Arma 3 Radio Stations. Don't edit the .hpp files by hand: put music in the music
// folder and run import_music.ps1 from the Arma 3 Radio Stations tools folder (see the Arma 3 Radio Stations README).
#include "script_version.hpp"

class CfgPatches {
    class a3r_mymusic_main { // rename together with the prefix
        name = "My Radio Music";
        author = "Your Name";
        units[] = {};
        weapons[] = {};
        requiredVersion = 2.18;
        requiredAddons[] = {"a3r_main"};
        version = MAJOR.MINOR;
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

// Version is YYYY.MM.DD.N: release date, then the release number on that day (starting at 1).
// Keep MINOR (month) and PATCHLVL (day) two digits, e.g. 02 not 2: CfgPatches version = MAJOR.MINOR
// is a decimal number, and 2026.2 would sort above 2026.10.
// Set it with tools\bump_version.ps1 before each release.
#define MAJOR 2026
#define MINOR 10
#define PATCHLVL 18
#define BUILD 1

#define A3R_STRINGIFY(x) #x
#define A3R_TO_STRING(x) A3R_STRINGIFY(x)
#define VERSION_STR A3R_TO_STRING(MAJOR.MINOR.PATCHLVL.BUILD)

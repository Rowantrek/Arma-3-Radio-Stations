/*
 * Finds a class in the mission's description.ext first, then in addon config.
 *
 * Arguments:
 * 0: Root class, e.g. "CfgMusic" <STRING>
 * 1: Class name <STRING>
 *
 * Return: Config entry; check with isClass <CONFIG>
 */
params ["_root", "_name"];

private _cfg = missionConfigFile >> _root >> _name;
if (isClass _cfg) exitWith {_cfg};

configFile >> _root >> _name

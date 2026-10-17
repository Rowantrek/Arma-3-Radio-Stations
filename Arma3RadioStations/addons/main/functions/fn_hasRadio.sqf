/*
 * Whether a vehicle has a radio. By default every land vehicle, boat and aircraft does,
 * including modded ones, except static weapons, parachutes and drones.
 *
 * Overrides, highest priority first:
 * - Mission: _vehicle setVariable ["a3r_hasRadio", true/false, true]
 * - Config:  a3r_hasRadio = 0/1; in the vehicle class
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return: <BOOL>
 */
params ["_vehicle"];

private _override = _vehicle getVariable "a3r_hasRadio";
if (!isNil "_override") exitWith {_override};
if !(missionNamespace getVariable ["a3r_vehicleRadios", true]) exitWith {false};

private _type = typeOf _vehicle;
private _has = a3r_radioClassCache get _type;
if (isNil "_has") then {
    private _cfg = configOf _vehicle >> "a3r_hasRadio";
    _has = if (isNumber _cfg) then {
        getNumber _cfg == 1
    } else {
        ["LandVehicle", "Ship", "Air"] findIf {_vehicle isKindOf _x} >= 0
        && {!(_vehicle isKindOf "StaticWeapon")}
        && {!(_vehicle isKindOf "ParachuteBase")}
        && {getNumber (configOf _vehicle >> "isUav") != 1}
    };
    a3r_radioClassCache set [_type, _has];
};

_has

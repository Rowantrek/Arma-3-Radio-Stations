/*
 * Whether an object is a placed radio (as opposed to a vehicle radio).
 * True for classes with config a3r_isRadio = 1, or any object a mission marks with
 * _obj setVariable ["a3r_isRadio", true, true].
 *
 * Arguments:
 * 0: Object <OBJECT>
 *
 * Return: <BOOL>
 */
params ["_obj"];

_obj getVariable ["a3r_isRadio", getNumber (configOf _obj >> "a3r_isRadio") == 1]

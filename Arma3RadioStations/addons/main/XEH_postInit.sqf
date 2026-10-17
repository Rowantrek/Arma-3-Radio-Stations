if (!hasInterface) exitWith {};

a3r_playing = []; // [[radio, restartKey, soundSource], ...] - radio sounds this client is playing

[A3R_fnc_clientUpdate, 0.5] call CBA_fnc_addPerFrameHandler;

// Placed-radio scroll menu. Fires for the initial unit, after respawn and when Zeus remote-controls a unit
["unit", {[_this select 0] call A3R_fnc_addPlacedRadioActions}, true] call CBA_fnc_addPlayerEventHandler;

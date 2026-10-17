if (!hasInterface) exitWith {};

a3r_playing = []; // [[radio, restartKey, soundSource, startPosASL], ...] - radio sounds this client is playing

[A3R_fnc_clientUpdate, 0.5] call CBA_fnc_addPerFrameHandler;

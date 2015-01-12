if (isServer) then {
  A3W_fnc_hideObjectGlobal = {
    //diag_log format["%1 call A3W_fnc_hideObjectGlobal", _this];
    private["_left", "_right"];
    _left = _this select 0;
    _right = _this select 1;
    if (isNil "_left" || {typeName _left != typeName objNull || {isNull _left}}) exitWith {};
    if (isNil "_right" || {typeName _right != typeName false}) exitWith {};

    _left hideObjectGlobal _right;
  } call mf_compile;

  spawn_addon_setup_complete = true;
  publicVariable "spawn_addon_setup_complete";
};

if (!isServer) then {
  A3W_fnc_hideSpawning = {
    //diag_log format["%1 call A3W_fnc_hideSpawning", _this];

    private["_player", "_pos1", "_pos2"];
    _player = _this select 0;
    if (isNil "_player" || {isNull _player || {!(alive _player)}}) exitWith {};
    _pos1 = getPos _player;
    enableEnvironment false;
    0 fadeSound 0;

    _player hideObjectGlobal true;
    [[_player,true], "A3W_fnc_hideObjectGlobal",false, false] call BIS_fnc_MP;

    _player allowDamage false;

    private["_respawn_dialog"];
    waitUntil {
      if (isNil "_player" || {isNull _player}) exitWith {true};
      _pos2 = getPos _player;
      if ((_pos1 distance _pos2) > 50) exitWith {
        [[_player,false], "A3W_fnc_hideObjectGlobal",false, false] call BIS_fnc_MP;
        _player allowDamage true;
        enableEnvironment true;
        0 fadeSound 1;
        true
      };

      false
    };
  } call mf_compile;

  waitUntil {!isNull player};
  waitUntil {!isNil "spawn_addon_setup_complete"};

	player addEventHandler ["Respawn", { [(_this select 0)] spawn A3W_fnc_hideSpawning; }];
  [player] spawn A3W_fnc_hideSpawning;
};

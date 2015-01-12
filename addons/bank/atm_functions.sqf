#include "macro.h"
#include "defines.h"

if (!undefined(atm_functions_defined)) exitWith {};
diag_log format["Loading atm functions ..."];


atm_is_object_atm = {
  ARGVX4(0,_object,objNull,false);
  ([": atm",str(_object)] call BIS_fnc_inString)
};



atm_is_player_near = {
  private["_pos1", "_pos2"];
  _pos1 = (eyePos player);
  _pos2 = ([_pos1, call cameraDir] call BIS_fnc_vectorAdd);

  private["_objects"];
  _objects = lineIntersectsWith [_pos1,_pos2,objNull,objNull,true];
  if (isNil "_objects" || {typeName _objects != typeName []}) exitWith {false};


  private["_found"];
  _found = false;
  {
    if ([_x] call atm_is_object_atm) exitWith {
	    _found = true;
	  };
  } forEach _objects ;

  (_found)
};


atm_actions = [];

atm_remove_actions = {
	if (count atm_actions == 0) exitWith {};

	{
		private["_action_id"];
		_action_id = _x;
		player removeAction _action_id;
	} forEach atm_actions;
	atm_actions = [];
};

atm_is_out_of_service = {
  ARGVX4(0,_player,objNull,false);

  if (!isARRAY(bank_towns_whitelist)) exitWith {false};
  if (count(bank_towns_whitelist) == 0) exitWith {false};

  def(_town);
  _town = ((nearestLocations [_player,["NameCityCapital","NameCity","NameVillage"],10000]) select 0);
  if (isNil "_town") exitWith {false};

  def(_town_name);
  _town_name = text _town;
  if (_town_name in bank_towns_whitelist) exitWith {false};

  (not(_town_name in bank_towns_whitelist))
};

atm_nearest_town = {
  ARGVX3(0,_player,objNull);

  if (!isARRAY(bank_towns_whitelist)) exitWith {};
  if (count(bank_towns_whitelist) == 0) exitWith {};

  def(_nearest);
  init(_dist,1000000);

  {if(true) then {
    if (!isSTRING(_x)) exitWith {};

    def(_loc);
    _loc = [_x] call name2location;
    if (isNil "_loc") exitWith {};

    def(_pos);
    _pos = (locationPosition _loc);
    if (!isARRAY(_pos) || {count(_pos) < 2}) exitWith {};
    _pos set [2, 0];

    def(_cdist);
    _cdist = _player distance _pos;
    if (_cdist < _dist) then {
      _dist = _cdist;
      _nearest = text(_loc);
    };
  };} forEach bank_towns_whitelist;

  (OR(_nearest,nil))
};

atm_access = {
  init(_player, player);

  if ([_player] call atm_is_out_of_service) exitWith {
    //find the nearest city to the player
    def(_nearest_town);
    _nearest_town = [_player] call atm_nearest_town;

    if (!isSTRING(_nearest_town)) exitWith {
      player groupChat format ["%1, this ATM is out of service, and there is no ATM near, sorry.", (name _player)];
    };

    player groupChat format["%1, this ATM is out of service, the nearest working ATM is in ""%2"" city", (name _player), _nearest_town];
  };

  [player] call bank_menu_dialog;
};

atm_add_actions = {
	if (count atm_actions > 0) exitWith {};
	private["_player"];
	_player = _this select 0;

  private["_action_id", "_text"];
  _action_id = _player addAction ["<img image='addons\bank\icons\bank.paa'/> Access ATM", {call atm_access}];
  atm_actions = atm_actions + [_action_id];
};


atm_check_actions = {
  	private["_player"];
    _player = player;
    private["_vehicle", "_in_vehicle"];
    _vehicle = (vehicle _player);
    _in_vehicle = (_vehicle != _player);

    if (not(_in_vehicle || {not(alive _player) || {not(call atm_is_player_near)}})) exitWith {
      [_player] call atm_add_actions;
    };

   [_player] call atm_remove_actions;
};

atm_client_loop = {
	private ["_atm_client_loop_i"];
	_atm_client_loop_i = 0;

	while {_atm_client_loop_i < 5000} do {
		call atm_check_actions;
		sleep 0.5;
		_atm_client_loop_i = _atm_client_loop_i + 1;
	};
	[] spawn atm_client_loop;
};

[] spawn atm_client_loop;

atm_functions_defined = true;
diag_log format["Loading atm functions complete"];

//if (!isNil "parking_functions_defined") exitWith {};
diag_log format["Loading parking functions ..."];

#include "macro.h"

#define strM(x) ([x,","] call format_integer)

pp_marker_create = {
  ARGVX3(0,_name,"");
  ARGVX3(1,_location,[]);
  ARGVX3(2,_this,[]);
  
  ARGVX3(0,_shape,"");
  ARGVX3(1,_type,"");
  ARGVX3(2,_color,"");
  ARGVX3(3,_size,[]);
  ARGVX3(4,_text,"");

  private["_marker"];
  _marker = createMarker [_name,_location]; 

  _marker setMarkerShapeLocal _shape;
  _marker setMarkerTypeLocal _type;
  _marker setMarkerColorLocal _color;
  _marker setMarkerSizeLocal _size;
  _marker setMarkerTextLocal _text;
  (_marker)
};

pp_get_all_cities = {
  if (isARRAY(pp_all_cities)) exitWith {pp_get_all_cities};
  pp_get_all_cities = (nearestLocations [[0,0,0],["NameCityCapital","NameCity","NameVillage"],1000000]);
  (pp_get_all_cities)
};

pp_markers_list = OR(pp_markers_list,[]);
pp_terminals_list = OR(pp_terminals_list,[]);

{
  deleteVehicle _x;
} forEach pp_terminals_list;

{
  deleteMarker _x;
} forEach pp_markers_list;

pp_create_terminal = {
 //Land_Laptop_unfolded_F
  ARGVX3(0,_garage,objNull);
  
  def(_pos);
  def(_terminal);
  
  _pos = _garage modelToWorld [-5,0.45,-1.485];
  _garage allowDamage false;

  _terminal = createVehicle ["Land_CampingTable_small_F", _pos, [], 0, ""];
  _terminal setPos _pos;
  _terminal setVectorDirAndUp [([vectorDir _garage,90] call BIS_fnc_rotateVector2D), vectorUp _garage];
  _terminal attachTo [_garage, [0,0,0]];
  _terminal allowDamage false;
  //_terminal enableSimulation false;
  _terminal setVariable ["is_parking", true, true];
  _terminal setVariable ["R3F_LOG_disabled", true]; //don't allow players to move the table
  _terminal attachTo [_terminal, [0,0,0]];
  detach _terminal;

  def(_laptop);
  _laptop = createVehicle ["Land_Laptop_unfolded_F", _pos, [], 0, ""];
  _laptop setPos getPos _terminal;
  _laptop attachTo [_terminal, [0,-0.1,0.55]];
  _laptop setVariable ["is_parking", true, true];
  _laptop setVariable ["R3F_LOG_disabled", true]; //don't allow players to move the laptop

  
  pp_terminals_list pushBack _terminal;
  pp_terminals_list pushBack _laptop;

  (_pos)
};

pp_create_terminals = {
  def(_town);
  def(_town_pos);
  def(_town_name);
  def(_garage);
  def(_terminal);
  def(_model);
  def(_pos);
  def(_name);
  def(_marker);
  init(_i,0);
  
  
  {if (true) then {
    _town = _x;
    _town_name =  text(_town);
    _town_pos = position _town;
    if (isARRAY(pp_cities_whitelist) && {count(pp_cities_whitelist) > 0 && {not(_town_name in pp_cities_whitelist)}}) exitWith {};
  
    _garage = (nearestObjects [_town_pos, ["Land_i_Shed_Ind_F"], 300]) select 0;
    if (!isOBJECT(_garage)) exitWith {
      diag_log format["No garage in %1", _town_name];
    };
  
    _name = format["parking_terminal_%1", _i];
    _i = _i + 1;
  
   _pos = [_garage] call pp_create_terminal;
    
    diag_log format["Creating parking terminal at: %1 (%2)", _town_name, _pos];

    if (pp_markers_enabled) then {
      _marker = [_name, _pos, pp_markers_properties] call pp_marker_create;
      pp_markers_list pushBack _marker;
    };
    
  }} foreach (call pp_get_all_cities);
};

pp_get_near_vehicles = {
  ARGVX4(0,_player,objNull,[]);

  def(_vehicles);
  _vehicles = (nearestObjects [getPos _player, ["Helicopter", "Plane", "Ship_F", "Car", "Motorcycle", "Tank"], 50]);

  init(_filtered,[]);
  def(_uid);
  _uid = getPlayerUID player;

  def(_ownerUID);
  def(_vehicle);

  {if (true) then {
    _vehicle = _x;
    if (not(isOBJECT(_vehicle) && {alive _vehicle})) exitWith {};

    _ownerUID = _vehicle getVariable ["ownerUID", ""];
    if(!isSTRING(_ownerUID)) exitWith {};
    if (_ownerUID == "" || {_ownerUID == _uid}) exitWith {
      _filtered pushBack _vehicle;
    };

  };} forEach _vehicles;

  (_filtered)
};



pp_join_time = diag_tickTime; //time when the player joined the server

pp_get_wait_time = {
  ARGVX4(0,_vehicle_id,"",0);

  if (not(isSCALAR(pp_retrieve_wait)) || {pp_retrieve_wait <= 0}) exitWith {0};

  def(_cooldown_start_name);
  _cooldown_start_name =  format["%1_cooldown_start", _vehicle_id];


  def(_cooldown_start);
  _cooldown_start = missionNamespace getVariable _cooldown_start_name;

  if (!isSCALAR(_cooldown_start)) then {
    _cooldown_start = pp_join_time;
    missionNamespace setVariable [_cooldown_start_name, _cooldown_start];
  };

  def(_time_elapsed);
  _time_elapsed = diag_tickTime - _cooldown_start;

  def(_time_remaining);
  _time_remaining = pp_retrieve_wait - _time_elapsed;

  if (_time_remaining <= 0) then {
    missionNamespace setVariable [_cooldown_start_name, nil];
  };

  (_time_remaining)
};

pp_retrieve_transaction_ok = {
  ARGVX4(0,_player,objNull,true);
  ARGVX4(1,_cost,0,true);
  ARGVX3(2,_class,"",true)

  def(_cmoney);
  _cmoney = _player getVariable ["cmoney",0];
  if (_cost > _cmoney) exitWith {
    _player groupChat format["%1, you do not have enough money to retrieve the %2", (name _player), ([_class] call generic_display_name)];
    false
  };

  _player setVariable ["cmoney", _cmoney - _cost, true];
  true
};

pp_retrieve_allowed = {
  ARGVX4(0,_player,objNull, true);
  ARGVX4(1,_vehicle_id,"",true);
  ARGVX4(2,_class,"", true);

  //check if there is a cool-down period
  def(_wait_time);
  _wait_time = [_vehicle_id] call pp_get_wait_time;
  if (isSCALAR(_wait_time) && {_wait_time > 0 }) exitWith {
    _player groupChat format["%1, you have to wait %2 more sec(s) to retrieve the %3", (name _player), ceil(_wait_time), ([_class] call generic_display_name)];
    false
  };

  //check if thereis a price for retrieving the vehicle
  if (isSCALAR(pp_retrieve_cost) && {pp_retrieve_cost > 0}) exitWith {
    init(_cost,pp_retrieve_cost);
    _msg = format["It's going to cost you $%1 to retrieve the %2. Do you want to proceed?", strM(_cost), ([_class] call generic_display_name)];

    if (not([_msg, "Confirm", "Yes", "No"] call BIS_fnc_guiMessage)) exitWith {false};
    if (not([_player, _cost] call pp_retrieve_transaction_ok)) exitWith {false};

    true
  };

  true
};

pp_park_allowed = {
  ARGVX4(0,_player,objNull, true);
  ARGVX4(1,_vehicle_id,"",true);
  ARGVX4(2,_class,"", true);

  if (isARRAY(pp_disallowed_vehicle_classes) && {count(pp_disallowed_vehicle_classes) > 0 && { ({_class isKindOf _x} count pp_disallowed_vehicle_classes) > 0}}) exitWith {
    _msg = format["This vehicle (%1) is not allowed to be parked.", ([_class] call generic_display_name)];
    [_msg, "Illegal Parking", "Ok", false] call BIS_fnc_guiMessage;
    false
  };

  def(_parked_vehicles);
  _parked_vehicles = _player getVariable ["parked_vehicles", []];
  init(_count,count(_parked_vehicles));

  //check if the parking is full
  if (isSCALAR(pp_max_player_vehicles) && {pp_max_player_vehicles > 0 && {_count >= pp_max_player_vehicles}}) exitWith {
    _msg = format["You already have %1 vehicle(s) parked. There are no more parking spaces available.", _count];
    [_msg, "Full Parking", "Ok", false] call BIS_fnc_guiMessage;
    false
  };

  true
};



pp_park_vehicle_action = {
  init(_player,player);

  def(_vehicles);
  _vehicles = [_player] call pp_get_near_vehicles;

  def(_vehicle_id);
  _vehicle_id = ["Park Vehicle", _vehicles] call pp_interact_park_vehicle_wait;

  if (!isSTRING(_vehicle_id)) exitWith {
    //_player groupChat format["%1, you did not select any vehicle to park", (name _player)];
  };


  _vehicle = objectFromNetId _vehicle_id;
  if (!isOBJECT(_vehicle)) exitWith {
    _player groupChat format["%1, the vehicle you selected to park could not be found", (name _player)];
  };

  def(_class);
  _class =  typeOf _vehicle;

  if (not([_player, _vehicle_id, _class] call pp_park_allowed)) exitWith {};


  _player groupChat format["Please wait while we park your %1", ([typeOf _vehicle] call generic_display_name)];
  [_player, _vehicle] call pp_park_vehicle;
};

pp_retrieve_vehicle_action = {
  init(_player,player);

  def(_parked_vehicles);
  _parked_vehicles = _player getVariable "parked_vehicles";
  _parked_vehicles = if (isARRAY(_parked_vehicles)) then {_parked_vehicles} else {[]};


  def(_vehicle_id);
  _vehicle_id = ["Retrieve Vehicle", _parked_vehicles] call pp_interact_park_vehicle_wait;


  if (!isSTRING(_vehicle_id)) exitWith {
    //_player groupChat format["%1, you did not select any vehicle to retreive", (name _player)];
  };

  def(_vehicle_data);
  _vehicle_data = [_parked_vehicles, _vehicle_id] call fn_getFromPairs;

  if (!isARRAY(_vehicle_data)) exitWith {
    player groupChat format["ERROR: The selected vehicle (%1) was not found", _vehicle_id];
  };

  def(_class);
  _class = [_vehicle_data, "Class"] call fn_getFromPairs;

  if (not([_player, _vehicle_id, _class] call pp_retrieve_allowed)) exitWith {};

  _player groupChat format["Please wait while we retrieve your %1", ([_class] call generic_display_name)];
  [player, _vehicle_id] call pp_retrieve_vehicle;
};


pp_cameraDir = {
  ([(positionCameraToWorld [0,0,0]), (positionCameraToWorld [0,0,1])] call BIS_fnc_vectorDiff)
};

pp_is_object_parking = {
  ARGVX4(0,_obj,objNull,false);
  (_obj getVariable ["is_parking", false])
};

pp_is_player_near = {
  private["_pos1", "_pos2"];
  _pos1 = (eyePos player);
  _pos2 = ([_pos1, call pp_cameraDir] call BIS_fnc_vectorAdd);

  private["_objects"];
  _objects = lineIntersectsWith [_pos1,_pos2,objNull,objNull,true];
  if (isNil "_objects" || {typeName _objects != typeName []}) exitWith {false};


  private["_found"];
  _found = false;
  {
    if ([_x] call pp_is_object_parking) exitWith {
      _found = true;
    };
  } forEach _objects ;

  (_found)
};

pp_actions = OR(pp_actions,[]);

pp_remove_actions = {
  if (count pp_actions == 0) exitWith {};

  {
    private["_action_id"];
    _action_id = _x;
    player removeAction _action_id;
  } forEach pp_actions;
  pp_actions = [];
};

pp_add_actions = {
  if (count pp_actions > 0) exitWith {};
  private["_player"];
  _player = _this select 0;

  private["_action_id", "_text"];
  _action_id = _player addAction ["<img image='addons\parking\icons\parking.paa'/> Park Vehicle", {call pp_park_vehicle_action}];
  pp_actions = pp_actions + [_action_id];

  _action_id = _player addAction ["<img image='addons\parking\icons\parking.paa'/> Retrieve Vehicle", {call pp_retrieve_vehicle_action}];
  pp_actions = pp_actions + [_action_id];
};

pp_check_actions = {
    private["_player"];
    _player = player;
    private["_vehicle", "_in_vehicle"];
    _vehicle = (vehicle _player);
    _in_vehicle = (_vehicle != _player);

    if (not(_in_vehicle || {not(alive _player) || {not(call pp_is_player_near)}})) exitWith {
      [_player] call pp_add_actions;
    };

   [_player] call pp_remove_actions;
};

//this is a hack so that markers sync for JIP (Join in Progress) players
pp_sync_markers = {
  {
    _x setMarkerColor markerColor _x ;
  } forEach allMapMarkers;
};


pp_client_loop_stop = false;
pp_client_loop = {
  if (not(isClient)) exitWith {};
  private ["_pp_client_loop_i"];
  _pp_client_loop_i = 0;

  while {_pp_client_loop_i < 5000 && not(pp_client_loop_stop)} do {
    call pp_check_actions;
    sleep 0.5;
    _pp_client_loop_i = _pp_client_loop_i + 1;
  };
  [] spawn pp_client_loop;
};


pp_setup_terminals = {
  if (not(isClient)) then { //FIXME: Need to change this to not(isClient)
    diag_log format["Setting up parking terminals ... "];
    [] call pp_create_terminals;
    pp_setup_terminals_complete = true;
    publicVariable "pp_setup_terminals_complete";
    diag_log format["Setting up parking terminals complete"];

    ["pp_sync_markers", "onPlayerConnected", { [] spawn pp_sync_markers}] call BIS_fnc_addStackedEventHandler;
  };
  
  if (isClient) then {
    diag_log format["Waiting for parking terminals setup to complete ..."];
    waitUntil {not(isNil "pp_setup_terminals_complete")};
    diag_log format["Waiting for parking terminals setup to complete ... done"];
  };
};

[] call pp_setup_terminals;
[] spawn pp_client_loop;

parking_functions_defined = true;
diag_log format["Loading parking functions complete"];




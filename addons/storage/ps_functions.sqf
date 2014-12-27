if (!isNil "storage_functions_defined") exitWith {};
diag_log format["Loading storage functions ..."];

#include "macro.h"
#include "futura.h"

ps_marker_create = {
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

ps_get_all_cities = {
  if (isARRAY(ps_all_cities)) exitWith {ps_get_all_cities};
  ps_get_all_cities = (nearestLocations [[0,0,0],["NameCityCapital","NameCity","NameVillage"],1000000]);
  (ps_get_all_cities)
};


ps_create_boxes = {
  def(_town);
  def(_town_pos);
  def(_town_name);
  def(_garage);
  def(_box);
  def(_model);
  def(_pos);
  def(_name);
  def(_marker);
  init(_i,0);
  
  
  {if (true) then {
    _town = _x;
    _town_name =  text(_town);
    _town_pos = position _town;
    if (isARRAY(ps_cities_whitelist) && {count(ps_cities_whitelist) > 0 && {not(_town_name in ps_cities_whitelist)}}) exitWith {};
  
    _garage = (nearestObjects [_town_pos, ["Land_i_Garage_V2_F"], 300]) select 0;
    if (!isOBJECT(_garage)) exitWith {
      diag_log format["No garage in %1", _town_name];
    };
  
    _name = format["storage_box_%1", _i];
    _i = _i + 1;
  
  
    _pos = _garage modelToWorld [0,0,0];
  
    _model = ps_box_models call BIS_fnc_selectRandom;
  
    _box = createVehicle [_model, _pos, [], 0, ""];
    _box setPos _pos;
    _box setVectorDirAndUp [vectorDir _garage, vectorUp _garage];
    _box allowDamage false;
    _box enableSimulation false;
    _box setVariable ["is_storage", true, true];
    _box setVariable ["R3F_LOG_disabled", true]; //don't allow players to move the boxes

    if (ps_markers_enabled) then {
      _marker = [_name, _pos, ps_markers_properties] call ps_marker_create;
    };
  
    diag_log format["Creating Storage at: %1 (%2)", _town_name, _pos];
  }} foreach (call ps_get_all_cities);
};


ps_get_box = {
  def(_box);
  init(_player,player);
  _box = _player getVariable ["storage_box", objNull];
  if (isOBJECT(_box) && {not(isNull _box)}) exitWith {_box};
  
  _box = ps_container_class createVehicle [0,0, 1000];
  _player setVariable ["storage_box", _box, true];
  (_box)
};


ps_inventory_ui_mod = {
  disableSerialization;
  waitUntil {!(isNull (findDisplay IDD_FUTURAGEAR))};
  def(_display);
  _display = findDisplay IDD_FUTURAGEAR;
  

  def(_outside);
  _outside = [-1,-1,0.1,0.1];
  
  def(_filter);
  _filter = _display displayCtrl IDC_FG_GROUND_FILTER;
  
  def(_pos);
  def(_ground_tab);
  _ground_tab = _display displayCtrl IDC_FG_GROUND_TAB;
  _pos = (ctrlPosition _ground_tab);
  _ground_tab ctrlSetPosition _outside;
  _ground_tab ctrlCommit 0;
  
  def(_custom_text);
  _custom_text = _display ctrlCreate ["RscText", -1];
  _pos set [2, (ctrlPosition _filter) select 2];
  _custom_text ctrlSetPosition _pos;
  _custom_text ctrlSetText "Private Storage";
  _custom_text ctrlSetBackgroundColor [0,0,0,1];
  _custom_text ctrlSetTextColor [1,1,1,1];
  _custom_text ctrlSetActiveColor [1,1,1,1];
  _custom_text ctrlSetTooltip "This storage is visible to you only.<br />It's automatically saved in the database,<br />and can be accessed across maps.";
  _custom_text ctrlCommit 0;
  
  def(_chosen_tab);
  _chosen_tab = _display displayCtrl IDC_FG_CHOSEN_TAB;
  _chosen_tab ctrlSetPosition _outside;
  _chosen_tab ctrlCommit 0;
  
  
  waitUntil {
    isNull (findDisplay IDD_FUTURAGEAR)
  };
  
  private["_box"];
  _box = (call ps_get_box);
  detach _box;
  _box setPos [0,0,1000];
};

ps_access = {
  private["_box"];
  _box = (call ps_get_box);
  _box attachTo [player, [0,0,3]];
  player removeAllEventHandlers "InventoryOpened";
  player addEventHandler ["InventoryOpened", {
    if ((call ps_get_box) == (_this select 1)) exitWith {
      true
    };
	  false
  }];
  player action ["Gear",  (call ps_get_box)];
  player removeAllEventHandlers "InventoryOpened";
  [] spawn ps_inventory_ui_mod;
};

ps_cameraDir = {
  ([(positionCameraToWorld [0,0,0]), (positionCameraToWorld [0,0,1])] call BIS_fnc_vectorDiff)
};

ps_is_object_storage = {
  ARGVX4(0,_obj,objNull,false);
  (_obj getVariable ["is_storage", false])
};

ps_is_player_near = {
  private["_pos1", "_pos2"];
  _pos1 = (eyePos player);
  _pos2 = ([_pos1, call ps_cameraDir] call BIS_fnc_vectorAdd);

  private["_objects"];
  _objects = lineIntersectsWith [_pos1,_pos2,objNull,objNull,true];
  if (isNil "_objects" || {typeName _objects != typeName []}) exitWith {false};


  private["_found"];
  _found = false;
  {
    if ([_x] call ps_is_object_storage) exitWith {
	    _found = true;
	  };
  } forEach _objects ;

  (_found)
};

ps_actions = OR(ps_actions,[]);

ps_remove_actions = {
	if (count ps_actions == 0) exitWith {};

	{
		private["_action_id"];
		_action_id = _x;
		player removeAction _action_id;
	} forEach ps_actions;
	ps_actions = [];
};

ps_add_actions = {
	if (count ps_actions > 0) exitWith {};
	private["_player"];
	_player = _this select 0;

  private["_action_id", "_text"];
  _action_id = _player addAction ["<img image='addons\storage\icons\storage.paa'/> Access Storage", {call ps_access}];
  ps_actions = ps_actions + [_action_id];
};

ps_check_actions = {
  	private["_player"];
    _player = player;
    private["_vehicle", "_in_vehicle"];
    _vehicle = (vehicle _player);
    _in_vehicle = (_vehicle != _player);

    if (not(_in_vehicle || {not(alive _player) || {not(call ps_is_player_near)}})) exitWith {
      [_player] call ps_add_actions;
    };

   [_player] call ps_remove_actions;
};

//this is a hack so that markers sync for JIP (Join in Progress) players
ps_sync_markers = {
  {
    _x setMarkerColor markerColor _x ;
  } forEach allMapMarkers;
};


ps_client_loop_stop = false;
ps_client_loop = {
  if (not(isClient)) exitWith {};
	private ["_ps_client_loop_i"];
	_ps_client_loop_i = 0;

	while {_ps_client_loop_i < 5000 && not(ps_client_loop_stop)} do {
		call ps_check_actions;
		sleep 0.5;
		_ps_client_loop_i = _ps_client_loop_i + 1;
	};
	[] spawn ps_client_loop;
};


ps_setup_boxes = {
  if (isServer) then {
    diag_log format["Setting up storage boxes ... "];
    [] call ps_create_boxes;
    ps_setup_boxes_complete = true;
    publicVariable "ps_setup_boxes_complete";
    diag_log format["Setting up storage boxes complete"];

    ["ps_sync_markers", "onPlayerConnected", { [] spawn ps_sync_markers}] call BIS_fnc_addStackedEventHandler;
  };
  
  if (isClient) then {
    diag_log format["Waiting for storage boxes setup to complete ..."];
    waitUntil {not(isNil "ps_setup_boxes_complete")};
    diag_log format["Waiting for storage boxes setup to complete ... done"];
    [] call ps_get_box; //create the storage box if it does not already exist
  };
};

[] call ps_setup_boxes;
[] spawn ps_client_loop;

storage_functions_defined = true;
diag_log format["Loading storage functions complete"];




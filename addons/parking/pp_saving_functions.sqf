if (!isNil "parking_saving_functions_defined") exitWith {};
diag_log format["Loading parking saving functions ..."];

#include "macro.h"

if (not(isClient)) then {
  pp_notify = {
    //diag_log format["%1 call pp_notify", _this];
    ARGVX3(0,_player,objNull);
    ARGVX3(1,_msg,"");
    ARGV3(2,_dialog,"");


    pp_notify_request = [_msg,OR(_dialog,nil)];
    (owner _player) publicVariableClient "pp_notify_request";
  };

  pp_mark_vehicle = {
    //diag_log format["%1 call pp_create_mark_vehicle", _this];
    ARGVX3(0,_player,objNull);
    ARGVX3(1,_vehicle,objNull);

    pp_mark_vehicle_request = [_vehicle];
    (owner _player) publicVariableClient "pp_mark_vehicle_request";
  };

  pp_is_safe_position = {
    ARGVX3(0,_player,objNull);
    ARGVX3(1,_class,"");
    ARGVX3(2,_position,[]);

    def(_classes);
    _classes = ["Helicopter", "Plane", "Ship_F", "Car", "Motorcycle", "Tank"];

    def(_size);
    _size = sizeof _class;

    ((_position distance _player) < 30 && {
     (count(nearestObjects [_position, _classes , _size]) == 0)})
  };

  pp_park_vehicle_request_handler = {
    ARGVX3(1,_this,[]);
    ARGVX3(0,_player,objNull);
    ARGVX3(1,_vehicle,objNull);

    if (not(alive _vehicle)) exitWith {};

    def(_uid);
    _uid = getPlayerUID _player;

    diag_log format["Parking vehicle %1(%2) for player %3(%4)", typeOf _vehicle, netId _vehicle,  (name _player), _uid];

    def(_parked_vehicles);
    _parked_vehicles = _player getVariable "parked_vehicles";
    _parked_vehicles = OR(_parked_vehicles,[]);

    def(_added);
    _added = [_parked_vehicles, _vehicle, false] call v_addSaveVehicle;
    if (isNil "_added") exitWith {
      diag_log format["ERROR: Could not park vehicle %1(%2) for player %3(%4)", typeOf _vehicle, netId _vehicle,  (name _player), _uid];
      [_player, format["The %1 needs to be saved before you can park it.", ([typeOf _vehicle] call generic_display_name)], "Parking Error"] call pp_notify;
    };

    def(_display_name);
    _display_name = [typeOf _vehicle] call generic_display_name;

    deleteVehicle _vehicle;

    _player setVariable ["parked_vehicles", _parked_vehicles, true];
    [_player, format["%1, your %2 has been parked.", (name _player), _display_name]] call pp_notify;
  };

  pp_retrieve_vehicle_request_handler = {
    ARGVX3(1,_this,[]);
    ARGVX3(0,_player,objNull);
    ARGVX3(1,_vehicle_id, "");

    def(_uid);
    _uid = getPlayerUID _player;

    diag_log format["Retrieving parked vehicle %1 for player %2(%3)", _vehicle_id,  (name _player), _uid];

    def(_parked_vehicles);
    _parked_vehicles = _player getVariable "parked_vehicles";
    _parked_vehicles = OR(_parked_vehicles,[]);

    def(_vehicle_data);
    _vehicle_data = [_parked_vehicles, _vehicle_id] call fn_getFromPairs;

    if (!isARRAY(_vehicle_data)) exitWith {
      diag_log format["ERROR: Could not retrieve vehicle %1 for player %2(%3)", _vehicle_id,  (name _player), _uid];
      [_player, format["Your vehicle (%2) could not be retrieved. Please report this error to A3Armory.com.", _vehicle_id], "Retrieval Error"] call pp_notify;
    };

    def(_position);
    _position = [_vehicle_data, "Position"] call fn_getFromPairs;

    def(_class);
    _class = [_vehicle_data, "Class"] call fn_getFromPairs;

    def(_create_array);
    if (not([_player,_class,_position] call pp_is_safe_position)) then {
      //we don't have an exact safe position, let the game figure one out
      _create_array = [_class, getPos _player, [], 30, "NONE"];
    };

    def(_vehicle);
    _vehicle = [[_vehicle_id, _vehicle_data], true,OR(_create_array,nil)] call v_restoreVehicle;

    if (isNil "_vehicle") exitWith {
      diag_log format["ERROR: Could not restore vehicle %1 for player %2(%3)", _vehicle_id,  (name _player), _uid];
      [_player, format["Your vehicle (%1) could not be restored. Please report this error to A3Armory.com.", _vehicle_id], "Restoring Error"] call pp_notify;
    };

    [_parked_vehicles, _vehicle_id] call fn_removeFromPairs;
    _player setVariable ["parked_vehicles", _parked_vehicles, true];

    def(_display_name);
    _display_name = [typeOf _vehicle] call generic_display_name;
    [_player, format["%1, your %2 has been retrieved (marked on map)", (name _player), _display_name]] call pp_notify;
    [_player, _vehicle] call pp_mark_vehicle;
  };

  "pp_park_vehicle_request" addPublicVariableEventHandler {_this call pp_park_vehicle_request_handler;};
  "pp_retrieve_vehicle_request" addPublicVariableEventHandler {_this call pp_retrieve_vehicle_request_handler;};

};

if (isClient) then {
  pp_notify_request_handler = {_this spawn {
    //diag_log format["%1 call pp_notify_request_handler", _this];
    ARGVX3(1,_this,[]);
    ARGVX3(0,_msg,"");
    ARGV3(1,_dialog,"");

    if (isSTRING(_dialog)) exitWith {
      [_msg, _dialog, "OK", false] call BIS_fnc_guiMessage;
    };

    player groupChat _msg;
  };};

  "pp_notify_request" addPublicVariableEventHandler {_this call pp_notify_request_handler};

  pp_mark_vehicle_request_handler = {_this spawn {
    //diag_log format["%1 call pp_mark_vehicle_request_handler", _this];
    ARGVX3(1,_this,[]);
    ARGVX3(0,_vehicle,objNull);

    sleep 3; //give enough time for the vehicle to be move to the correct location (before marking)
    def(_class);
    _class = typeOf _vehicle;

    def(_name);
    _name = [_class] call generic_display_name;

    def(_pos);
    _pos = getPos _vehicle;

    def(_marker);
    _marker = format["pp_vehicle_marker_%1", ceil(random 1000)];
    _marker = createMarkerLocal [_marker, _pos];
    _marker setMarkerTypeLocal "waypoint";
    _marker setMarkerPosLocal _pos;
    _marker setMarkerColorLocal "ColorBlue";
    _marker setMarkerTextLocal _name;

    [_marker] spawn {
      ARGVX3(0,_marker,"");
      sleep 60;
      deleteMarkerLocal _marker;
    };
  };};

  "pp_mark_vehicle_request" addPublicVariableEventHandler {_this call pp_mark_vehicle_request_handler};

  pp_park_vehicle = {
    pp_park_vehicle_request = _this;
    publicVariableServer "pp_park_vehicle_request";
  };

  pp_retrieve_vehicle = {
    pp_retrieve_vehicle_request = _this;
    publicVariableServer "pp_retrieve_vehicle_request";
  };
};


diag_log format["Loading parking saving functions complete"];
parking_saving_functions_defined = true;
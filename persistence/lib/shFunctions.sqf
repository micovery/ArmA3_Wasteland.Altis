if (!isNil "shFunctions_loaded") exitWith {};
diag_log "shFunctions loading ...";

#include "macro.h"


sh_isSaveableVehicle = {
  ARGVX4(0,_obj,objNull,false);

  init(_result, false);
  {
    if (_obj isKindOf _x) exitWith {
      _result = true;
    };
  } forEach A3W_saveable_vehicles_list;

  (_result)
};

sh_strToSide = {
  def(_result);
  _result = switch (toUpper _this) do {
    case "WEST":  { BLUFOR };
    case "EAST":  { OPFOR };
    case "GUER":  { INDEPENDENT };
    case "CIV":   { CIVILIAN };
    case "LOGIC": { sideLogic };
    default       { sideUnknown };
  };
  (_result)
};


sh_restoreVariables = {
  ARGVX3(0,_obj,objNull);
  ARGVX3(1,_variables,[]);

  def(_name);
  def(_value);

  {
    _name = _x select 0;
    _value = _x select 1;

    if (!isNil "_value") then {
      switch (_name) do {
        case "side": { _value = _value call sh_strToSide};
        case "R3F_Side": { _value = _value call sh_strToSide };
        case "ownerName": {
          switch (typeName _value) do {
            case "ARRAY": { _value = toString _value };
            case "STRING": { /* do nothing, it's already a string */ };
            default { _value = "[Unknown]" };
          };
        };
      };
    };

    _obj setVariable [_name, OR(_value,nil), true];
  } forEach _variables;
};

sh_isStaticWeapon = {
  ARGVX4(0,_obj,objNull,false);
  init(_class,typeOf _obj);
  (_class isKindOf "StaticWeapon")
};

sh_isBeacon = {
  ARGVX4(0,_obj,objNull,false);
  (_obj getVariable ["a3w_spawnBeacon", false])
};

sh_isCamera = {
  ARGVX4(0,_obj,objNull,false);
  (_obj getVariable ["a3w_cctv_camera", false])
};

sh_isBox = {
  ARGVX4(0,_obj,objNull,false);
  init(_class,typeOf _obj);
  (_class isKindOf "ReammoBox_F")
};

sh_isWarchest = {
  ARGVX4(0,_obj,objNull,false);
  (
    _obj getVariable ["a3w_warchest", false] && {
    (_obj getVariable ["side", sideUnknown]) in [WEST,EAST]}
  )
};

sh_mineAmmo2Vehicle = {
  ARGVX3(0,_class,"");

  _class = (([_class, "_"] call BIS_fnc_splitString) select 0);

  //hopefully after splitting, and taking the first part, we have the actual vehicle class name
  (_class)
};


sh_isSaveableMine ={
  ARGVX2(0,_arg);

  def(_class);
  if (isOBJECT(_arg)) then {
    _class = typeOf _arg;
  }
  else { if(isSTRING(_arg)) then {
    _class = _arg;
  };};

  (!(isNil "_class") && {_class in minesList})
};




/**
 * KillzoneKid's way for creating Charges, and Claymores ... very hacky
 */
sh_placeCharge = {
  ARGVX3(0,_charge,"");
  ARGVX3(1,_position,[]);
  ARGV2(2,_vectors_or_dir);

  def(_unit);
  def(_group);
  _group = createGroup sideLogic;
  _unit = _group createUnit ["B_Soldier_F", _position,[], 0, "CAN_COLLIDE"];
  _unit hideObjectGlobal true;
  if (isARRAY(_vectors_or_dir)) then {
    _unit setVectorDirAndUp _vectors;
  }
  else { if (isSCALAR(_vectors_or_dir)) then {
    _unit setDir _vectors;
  };};

  def(_muzzle);
  def(_mag);
  _mag = format["%1_Remote_Mag", _charge];
  _muzzle = if (["directional", _charge, true] call BIS_fnc_inString) then {"DirectionalMineRemoteMuzzle"} else {"DemoChargeMuzzle"};

  _unit playActionNow "PutDown";
  _unit addMagazine format["%1_Remote_Mag", _charge];
  _unit selectWeapon _muzzle;
  _unit fire [_muzzle, _muzzle, _mag];
  _unit setWeaponReloadingTime [_unit, _muzzle, 0];


  [_unit,_group] spawn {
    sleep 3;
	  deleteVehicle (_this select 0);
    deleteGroup (_this select 1);
  };
};

sh_isCharge = {
  ARGVX2(0,_arg);

  def(_class);
  if (isOBJECT(_arg)) then {
    _class = typeOf _arg;
  }
  else { if(isSTRING(_arg)) then {
    _class = _arg;
  };};

 ((["charge", _class, true] call BIS_fnc_inString) || {(["claymore", _class, true] call BIS_fnc_inString)})
};

sh_isMine = {
  ARGVX2(0,_arg);

  def(_class);
  if (isOBJECT(_arg)) then {
    _class = typeOf _arg;
  }
  else { if(isSTRING(_arg)) then {
    _class = _arg;
  };};

  if (isNil "_class") exitWith {false};

  _class = [_class] call sh_mineAmmo2Vehicle;

  (_class isKindOf "MineBase")
};

sh_isAMissionVehicle = {
  ARGVX4(0,_obj,objNull,false);
  def(_mission);
  _mission = _obj getVariable "A3W_missionVehicle";
  (isBOOLEAN(_mission) && {_mission})
};


sh_isAPurchasedVehicle = {
  ARGVX4(0,_obj,objNull,false);
  def(_purchased);
  _purchased = _obj getVariable "A3W_purchasedVehicle";
  (isBOOLEAN(_purchased) && {_purchased})
};

sh_isUAV = {
  ARGVX4(0,_obj,objNull,false);
  (getNumber(configFile >> "CfgVehicles" >> typeOf _obj >> "isUav") > 0)
};



sh_getVehicleTurrets = {
  def(_default);
  _default = [nil,nil,nil];
  ARGVX4(0,_veh,objNull,_default);

  def(_all_turrets);
  _all_turrets = [magazinesAmmo _veh, [], []];

  def(_class);
  _class = typeOf _veh;

  def(_turretMags);
  def(_turretMags2);
  def(_turretMags3);

  _turretMags = _all_turrets select 0;
  _turretMags2 = _all_turrets select 1;
  _turretMags3 = _all_turrets select 2;

  def(_hasDoorGuns);
  _hasDoorGuns = isClass (configFile >> "CfgVehicles" >> _class >> "Turrets" >> "RightDoorGun");

  def(_turrets);
  _turrets = allTurrets [_veh, false];

  if !(_class isKindOf "B_Heli_Transport_03_unarmed_F") then {
    _turrets = [[-1]] + _turrets; // only add driver turret if not unarmed Huron, otherwise flares get saved twice
  };

  if (_hasDoorGuns) then {
    // remove left door turret, because its mags are already returned by magazinesAmmo
    {
      if (_x isEqualTo [1]) exitWith {
        _turrets set [_forEachIndex, 1];
      };
    } forEach _turrets;

    _turrets = _turrets - [1];
  };


  {if (true) then {
    _path = _x;
    if (str(_path) == "[0]") exitWith {}; //don't look at the mags from the first turret again

    {
      if (([_turretMags, _x, -1] call fn_getFromPairs == -1) || {_hasDoorGuns}) then {
        if (_veh currentMagazineTurret _path == _x && {count _turretMags3 == 0}) then {
          _turretMags3 pushBack [_x, _path, [_veh currentMagazineDetailTurret _path] call getMagazineDetailAmmo];
        }
        else {
          _turretMags2 pushBack [_x, _path];
        };
      };
    } forEach (_veh magazinesTurret _path);
  }} forEach _turrets;

  (_all_turrets)
};


sh_restoreVehicleTurrets = {
  ARGVX3(0,_veh,objNull);
  ARGV3(1,_turret0,[]);
  ARGV3(2,_turret1,[]);
  ARGV3(3,_turret2,[]);

  //legacy data did not contain turret information, in that case, don't attempt to restore them
  if (isNil "_turret0" && {isNil "_turret1" && {isNil "_turret3"}}) exitWith {};

  _veh setVehicleAmmo 0;

  if (!isNil "_turret2") then {
    {
      _veh addMagazineTurret [_x select 0, _x select 1];
      _veh setVehicleAmmo (_x select 2);
    } forEach _turret2;
  };

  if (!isNil "_turret0") then {
    { _veh addMagazine _x } forEach _turret0;
  };

  if (!isNil "_turret1") then {
    { _veh addMagazineTurret _x } forEach _turret1;
  };

};

sh_calcualte_vectors = {
  ARGVX3(0,_data,[]);
  private["_direction","_angle","_pitch"];

  _direction = _data select 0;
  _angle = _data select 1;
  _pitch = _data select 2;

  _vecdx = sin(_direction) * cos(_angle);
  _vecdy = cos(_direction) * cos(_angle);
  _vecdz = sin(_angle);

  _vecux = cos(_direction) * cos(_angle) * sin(_pitch);
  _vecuy = sin(_direction) * cos(_angle) * sin(_pitch);
  _vecuz = cos(_angle) * cos(_pitch);

  private["_dir_vector"];
  private["_up_vector"];
  _dir_vector = [_vecdx,_vecdy,_vecdz];
  _up_vector = [_vecux,_vecuy,_vecuz];

  ([_dir_vector,_up_vector])
};

sh_set_heading = {
  ARGVX3(0,_object,objNull);
  ARGVX3(1,_data,[]);

  if (typeName (_data select 0) == typeName []) exitWith {
    _object setVectorDirAndUp _data;
  };

  def(_vectors);
  _vectors = [_data] call sh_calcualte_vectors;
  _object setVectorDirAndUp _vectors;
};

sh_fake_attach = {
  ARGVX3(0,_source,objNull);
  ARGVX3(1,_target,objNull);
  ARGVX3(2,_offset,[]);
  ARGV3(3,_heading,[]);
  ARGV4(4,_attached,false,false);

  if (isNil "_heading") then {
    _heading = [0,0,0];
  };

  _source attachTo [_target, _offset];

  [_source, _heading] call sh_set_heading;

  if (not(_attached)) then {
    //hack to have the objects not being attached
    _source attachTo [_source,[0,0,0]];
    detach _source;
  };
};

sh_create_setPos_reference = {
  if (!isNil "setPos_reference") exitWith {};
  setPos_reference = "Sign_Sphere10cm_F" createVehicleLocal [0,0,0];
  setPos_reference setPos [0,0,0];

  [setPos_reference,[0,0,0]] call sh_set_heading;
};

[] call sh_create_setPos_reference;

sh_fake_setPos = {
  //player groupChat format["camera_fake_setPos %1",_this];
  ARGVX3(0,_object,objNull);
  ARGVX3(1,_position,[]);
  ARGV3(2,_heading,[]);

  [_object,setPos_reference, (setPos_reference worldToModel _position),OR(_heading,nil)] call object_fake_attach;
};

sh_getValueFromPairs = {
  ARGVX3(0,_object_data,[]);
  ARGVX3(1,_searchForKey,"");

  def(_result);
  def(_key);
  def(_value);

  {
    _key = _x select 0;
    _value = _x select 1;
    if (_key == _searchForKey) exitWith {
      _result = OR(_value,nil)
    };
  } forEach _object_data;
  
  if (isNil "_result") exitWith {
    //diag_log format ["Error: %1 does not have %2!", _x, _searchForKey];
    nil
  };


  (_result);
};

sh_fillMagazineData = {
  ARGVX3(0,_container,objNull);
  ARGVX3(1,_full_mags,[]);
  ARGVX3(2,_partial_mags,[]);

  def(_mag);
  def(_ammo);

  {if (true) then {
    _mag = _x select 0;
    _ammo = _x select 1;

    if (_ammo == getNumber (configFile >> "CfgMagazines" >> _mag >> "count")) exitWith {
      [_full_mags, _mag, 1] call fn_addToPairs;
    };

    if (_ammo > 0) exitWith {
      _partial_mags pushBack [_mag, _ammo];
    };
  }} forEach (magazinesAmmoCargo _container);
};

shFunctions_loaded = true;
diag_log "shFunctions loading complete";
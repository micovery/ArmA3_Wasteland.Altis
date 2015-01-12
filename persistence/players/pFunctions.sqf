//	@file Version: 0.1
//	@file Name: pFunctions.sqf
//	@file Author: micovery
//	@file Description: Player loading

diag_log "pFunctions.sqf loading ...";

#include "macro.h"

//Some wrappers for logging
p_log_severe = {
  ["p_functions", _this] call log_severe;
};
p_log_info = {
  ["p_functions", _this] call log_info;
};
p_log_fine = {
  ["p_functions", _this] call log_fine;
};
p_log_finer = {
  ["p_functions", _this] call log_finer;
};
p_log_finest = {
  ["p_functions", _this] call log_finest;
};
p_log_set_level = {
  ["p_functions", _this] call log_set_level;
};
//Set default logging level for this component
LOG_INFO_LEVEL call p_log_set_level;
p_resetPlayerData = {
  removeAllWeapons player;
  removeAllAssignedItems player;
  removeUniform player;
  removeVest player;
  removeBackpack player;
  removeGoggles player;
  removeHeadgear player;
};

p_restoreBackpack = {
  ARGVX3(0,_value,"");
  removeBackpack player;

  if (_value == "") exitWith {};

  if (_value isKindOf "Weapon_Bag_Base") exitWith {
	player addBackpack "B_AssaultPack_rgr"; // NO SOUP FOR YOU
  };

  player addBackpack _value;
};

p_restoreBackpackWeapons = {
  ARGVX3(0,_value,[]);
 { (backpackContainer player) addWeaponCargoGlobal _x } forEach _value
};


p_restoreBackpackItems = {
  ARGVX3(0,_value, []);
  { (backpackContainer player) addItemCargoGlobal _x } forEach _value
};


p_restoreBackpackMagazines = {
  ARGVX3(0,_value,[]);
  { (backpackContainer player) addMagazineCargoGlobal _x } forEach _value
};


p_restorePrimaryWeapon = {
  ARGVX3(0,_value,"");
  player addWeapon _value; removeAllPrimaryWeaponItems player;
};


p_restoreSecondaryWeapon = {
  ARGVX3(0,_value,"");
  player addWeapon _value;
};


p_restoreHandgunWeapon = {
  //diag_log format["%1 call _restoreHandgunWeapon", _this];
  ARGVX3(0,_value,"");
  player addWeapon _value; removeAllHandgunItems player;
};

p_restoreLoadedMagazines = {
  ARGVX3(0,_value,[]);
 { player addMagazine _x } forEach _value;
};

p_restoreUniform = {
  ARGV4(0,_value,"","");

  if (_value == "") exitWith {
    player addUniform ([player, "uniform"] call getDefaultClothing);
  };

  if (player isUniformAllowed _value) exitWith {
	  player addUniform _value;
  };

  // If uniform cannot be worn by player due to different team, try to convert it, else give default instead
  def(_newUniform);
  _newUniform = [player, _value] call uniformConverter;

  if (player isUniformAllowed _newUniform) exitWith {
    player addUniform _newUniform;
  };

  player addUniform ([player, "uniform"] call getDefaultClothing);
};

p_restoreVest = {
  ARGVX3(0,_value,"");
  if (_value == "") exitWith {};
  player addVest _value;
};


p_copy_pairs = {
  ARGVX3(0,_target,[]);
  ARGVX3(1,_source,[]);
  {
    _target pushBack _x;
  } forEach _source;
};

p_restorePosition = {
  ARGV3(0,_position,[]);

  def(_nearSpawn);
  _nearSpawn = (isPOS(_position) && {(player distance _position) < 100});

  if (isPOS(_position) && {not(_nearSpawn)}) exitWith {
    player setPosATL _position;
  };

  if (_nearSpawn) then {
    diag_log format["WARNING: Saved position is too near the spawn. Putting player at a random safe location."];
    player groupChat format["WARNING: Saved position is too near the spawn. Putting you at a random safe location."];
  }
  else {
    diag_log format["WARNING: No position available. Putting player at a random safe location."];
    player groupChat format["WARNING: No position available. Putting you at a random safe location."];
  };

  [nil,false] spawn spawnRandom;
};

p_restorePrimaryWeaponItems = {
  ARGVX3(0,_items,[]);
  {
    if (_x != "") then {
      player addPrimaryWeaponItem _x;
    };
  } forEach _items
};

p_restoreSecondaryWeaponItems = {
  ARGVX3(0,_items,[]);
  {
    if (_x != "") then {
      player addSecondaryWeaponItem _x;
    };
  } forEach _items;
};

p_restoreHandgunWeaponItems = {
  ARGVX3(0,_items,[]);

  {
    if (_x != "") then {
      player addHandgunItem _x;
    };
  } forEach _items;
};

p_restoreGoggles = {
  ARGVX3(0,_goggles,"");
  if (_goggles == "") exitWith {};
  player addGoggles _goggles;
};

p_restoreHeadgear = {
  ARGVX3(0,_headgear,"");

  // If wearing one of the default headgears, give the one belonging to actual team instead
  def(_defHeadgear);
  def(_defHeadgears);

  _defHeadgear = [player, "headgear"] call getDefaultClothing;
  _defHeadgears =
  [
    [typeOf player, "headgear", BLUFOR] call getDefaultClothing,
    [typeOf player, "headgear", OPFOR] call getDefaultClothing,
    [typeOf player, "headgear", INDEPENDENT] call getDefaultClothing
  ];

  if (_headgear != _defHeadgear && {_defHeadgear != ""} && {{_headgear == _x} count _defHeadgears > 0}) then {
    player addHeadgear _defHeadgear;
  }
  else {
    player addHeadgear _headgear;
  };
};

p_restoreAssignedItems = {
  ARGVX3(0,_assigned_items,[]);

  {
    if ([player, _x] call isAssignableBinocular) then {
      player addWeapon _x;
    }
    else {
      player linkItem _x;
    };
  } forEach _assigned_items;
};


fn_applyPlayerData = {
  ARGVX3(0,_data,[]);
  format["%1 call fn_applyPlayerData;", _this] call p_log_finest;

  def(_loaded_magazines);
  def(_backpack_class);
  def(_backpack_weapons);
  def(_backpack_items);
  def(_backpack_magazines);
  def(_partial_magazines);
  def(_primary_weapon);
  def(_secondary_weapon);
  def(_handgun_weapon);
  def(_uniform_class);
  def(_vest_class);
  def(_vehicle_key);
  def(_position);
  def(_primary_weapon_items);
  def(_secondary_weapon_items);
  def(_handgun_weapon_items);
  def(_headgear);
  def(_goggles);
  def(_assigned_items);


  //iterate through the data, and extract the hash variables into local variables
  {
    init(_name,_x select 0);
    init(_value,_x select 1);

    switch (_name) do {
      case "Backpack": { _backpack_class = _value;};
      case "LoadedMagazines": { _loaded_magazines = _value; };
      case "BackpackWeapons": { _backpack_weapons = _value};
      case "BackpackItems": { _backpack_items = _value; };
      case "BackpackMagazines": { _backpack_magazines = _value };
      case "PrimaryWeapon": { _primary_weapon = _value };
      case "SecondaryWeapon": {_secondary_weapon = _value};
      case "HandgunWeapon": { _handgun_weapon = _value};
      case "Uniform":{ _uniform_class = _value};
      case "Vest": { _vest_class = _value};
      case "InVehicle": { _vehicle_key = _value};
      case "Position": {if (isPOS(_value)) then {_position = _value;}};
      case "PrimaryWeaponItems": {_primary_weapon_items = OR_ARRAY(_value,nil)};
      case "SecondaryWeaponItems": {_secondary_weapon_items = OR_ARRAY(_value,nil)};
      case "HandgunItems": {_handgun_weapon_items = OR_ARRAY(_value,nil)};
      case "Headgear": {_headgear = OR_STRING(_value,nil)};
      case "Goggles": {_goggles = OR_STRING(_value,nil)};
      case "AssignedItems": {_assigned_items = OR_ARRAY(_value,nil)};

    };
  } forEach _data;

  //Restore the weapons, backpack, uniform, and vest in correct order
  player addBackpack "B_Carryall_Base"; // add a temporary backpack for holding loaded weapon magazines
  [OR(_headgear,nil)] call p_restoreHeadgear;
  [OR(_assigned_items,nil)] call p_restoreAssignedItems;
  [OR(_goggles,nil)] call p_restoreGoggles;
  [OR(_loaded_magazines,nil)] call p_restoreLoadedMagazines;
  [OR(_primary_weapon,nil)] call p_restorePrimaryWeapon;
  [OR(_secondary_weapon,nil)] call p_restoreSecondaryWeapon;
  [OR(_handgun_weapon,nil)] call p_restoreHandgunWeapon;
  [OR(_primary_weapon_items,nil)] call p_restorePrimaryWeaponItems;
  [OR(_secondary_weapon_items,nil)] call p_restoreSecondaryWeaponItems;
  [OR(_handgun_weapon_items,nil)] call p_restoreHandgunWeaponItems;
  removeBackpack player;  //remove the temporary backpack

  //Restore backpack, and stuff inside
  if (isSTRING(_backpack_class) && {_backpack_class != ""}) then {
    //diag_log format["Restoring backpack: %1", _backpack_class];
    [_backpack_class] call p_restoreBackpack;

    //restore the stuff inside the backpack
    [OR(_backpack_weapons,nil)] call p_restoreBackpackWeapons;
    [OR(_backpack_magazines,nil)] call p_restoreBackpackMagazines;
    [OR(_backpack_items,nil)] call p_restoreBackpackItems;
  };

  [OR(_uniform_class,nil)] call p_restoreUniform;
  [OR(_vest_class,nil)] call p_restoreVest;

  [OR(_position,nil)] call p_restorePosition;

  //restore other stuff that is not order-dependent
  def(_name);
  def(_value);
  {
    _name = _x select 0;
    _value = _x select 1;

    switch (_name) do {
      case "Damage": { if (isSCALAR(_value)) then {player setDamage _value;};};
      case "HitPoints": { { player setHitPointDamage _x } forEach (OR(_value,[])) };
      case "Hunger": { hungerLevel = OR(_value,nil); };
      case "Thirst": { thirstLevel = OR(_value,nil); };
      case "Money": { player setVariable ["cmoney", OR(_value,0), true] };
      case "Direction": { if (defined(_value)) then {player setDir _value} };
      case "CurrentWeapon": { player selectWeapon OR(_value,"") };
      case "Animation": { if (isSTRING(_value) && {_value != ""}) then {[player, _value] call switchMoveGlobal};};
      case "UniformWeapons": { { (uniformContainer player) addWeaponCargoGlobal _x } forEach (OR(_value,[])) };
      case "UniformItems": { { (uniformContainer player) addItemCargoGlobal _x } forEach (OR(_value,[])) };
      case "UniformMagazines": { { (uniformContainer player) addMagazineCargoGlobal _x } forEach (OR(_value,[])) };
      case "VestWeapons": { { (vestContainer player) addWeaponCargoGlobal _x } forEach (OR(_value,[])) };
      case "VestItems": { { (vestContainer player) addItemCargoGlobal _x } forEach (OR(_value,[])) };
      case "VestMagazines": { { (vestContainer player) addMagazineCargoGlobal _x } forEach (OR(_value,[])) };
      case "PartialMagazines": { { player addMagazine _x } forEach _value };
      case "WastelandItems": { { [_x select 0, _x select 1, true] call mf_inventory_add } forEach (OR(_value,[])) };
    };
  } forEach _data;
};

fn_savePlayerData = {
  trackMyVitals =
  [
    player,
    [
      ["thirstLevel", thirstLevel],
      ["hungerLevel", hungerLevel]
    ]
  ];

  publicVariableServer "trackMyVitals";
};


fn_deletePlayerData = {
	deletePlayerData = player;
	publicVariableServer "deletePlayerData";
	playerData_gear = "";
};


fn_applyPlayerInfo = {
  diag_log format["%1 call fn_applyPlayerInfo;",_this];
  init(_data,_this);
  def(_name);
  def(_value);

  _data = _this;

  {
    _name = _x select 0;
    _value = _x select 1;

    switch (_name) do
    {
      case "Donator": { player setVariable ["isDonator", _value > 0] };
      case "BankMoney": { player setVariable ["bmoney", OR(_value,0), true] };
    };
  } forEach _data;
};

fn_applyPlayerStorage = {
  if (!isARRAY(_this)) exitWith {
    diag_log format["WARNING: No player private storage data"];
  };
  init(_data,_this);
  init(_player,player;)

  diag_log "#############################################";
  diag_log "Dumping _storageData";
  [_data] call p_dumpHash;

  def(_hours_alive);
  _hours_alive = [_data, "HoursAlive"] call fn_getFromPairs;


  if (isSCALAR(_hours_alive) && {A3W_storageLifetime > 0 && {_hours_alive > A3W_storageLifetime}}) exitWith {
    player commandChat format["WARNING: Your private storage is over %1 hours, it has been reset"];
    diag_log format["Private storage for %1 (%2) has been alive for %3 (max=%4), resetting it", (name player), (getPlayerUID player), _hours_alive, A3W_storageLifetime];
    _player setVariable ["private_storage", nil, true];
  };

  _player setVariable ["private_storage", _data, true];

  _player setVariable ["storage_spawningTime", diag_tickTime];
  if (isSCALAR(_hours_alive)) then {
    _player setVariable ["storage_hoursAlive", _hours_alive];
  };
};



p_recreateStorageBox = {
  //diag_log format["%1 call p_recreateStorageBox", _this];

  ARGVX3(0,_player,objNull);
  ARGVX3(1,_box_class,"");


  def(_data);
  _data = _player getVariable ["private_storage", []];

  def(_class);
  def(_cargo_backpacks);
  def(_cargo_magazines);
  def(_cargo_items);
  def(_cargo_weapons);
  def(_full_magazines);
  def(_partial_magazines);

  def(_name);
  def(_value);
  {
    _name = _x select 0;
    _value = _x select 1;

    switch (_name) do
    {
      case "Class": {_class = OR(_value,nil)};
      case "Weapons": { _cargo_weapons = OR(_value,nil);};
      case "Items": { _cargo_items = OR(_value,nil);};
      case "Magazines": { _cargo_magazines = OR(_value,nil);}; //keep this for a while for legacy reasons
      case "FullMagazines": { _full_magazines = OR(_value,nil);};
      case "PartialMagazines": { _partial_magazines = OR(_value,nil);};
      case "Backpacks": { _cargo_backpacks = OR(_value,nil);};
    };
  } forEach _data;

  if (!isSTRING(_class) || {_class == "" || {_class != _box_class}}) then {
    _class = _box_class;
  };


  def(_obj);
  _obj = _class createVehicleLocal [0,0,1000];
  if (!isOBJECT(_obj)) exitWith {
    diag_log format["WARNING: Could not create storage container of class ""%1""", _class];
  };

  removeAllWeapons _obj;
  removeAllItems _obj;
  clearWeaponCargo _obj;
  clearMagazineCargo _obj;
  clearBackpackCargo _obj;
  clearItemCargo _obj;
  _obj hideObject true;

  if (isARRAY(_cargo_weapons)) then {
    { _obj addWeaponCargoGlobal _x } forEach _cargo_weapons;
  };

  if (isARRAY(_cargo_backpacks)) then {
    {
      if (not((_x select 0) isKindOf "Weapon_Bag_Base")) then {
        _obj addBackpackCargoGlobal _x
      };
    } forEach _cargo_backpacks;
  };

  if (isARRAY(_cargo_items)) then {
    { _obj addItemCargoGlobal _x } forEach _cargo_items;
  };

  if (isARRAY(_cargo_magazines)) then { //FIXME: this is legacy code, need to remove eventually
    { _obj addMagazineCargoGlobal _x } forEach _cargo_magazines;
  };

  if (isARRAY(_full_magazines)) then {
    { _obj addMagazineCargoGlobal _x } forEach _full_magazines;
  };

  if (isARRAY(_partial_magazines)) then {
    { _obj addMagazineAmmoCargo  [(_x select 0), 1, (_x select 1)] } forEach _partial_magazines;
  };

  _obj setVariable ["is_storage_box", true];

  _obj
};



p_trackStorageHoursAlive = {
  ARGVX3(0,_player,objNull);

  def(_spawnTime);
  def(_hoursAlive);

  _spawnTime = _player getVariable "storage_spawningTime";
  _hoursAlive = _player getVariable "storage_hoursAlive";

  if (isNil "_spawnTime") then {
    _spawnTime = diag_tickTime;
    _player setVariable ["storage_spawningTime", _spawnTime, true];
  };

  if (isNil "_hoursAlive") then {
    _hoursAlive = 0;
    _player setVariable ["storage_hoursAlive", _hoursAlive, true];
  };

  def(_totalHours);
  _totalHours = _hoursAlive + (diag_tickTime - _spawnTime) / 3600;

  (_totalHours)
};

p_saveStorage = {
  //diag_log format["%1 call p_getPlayerInfo", _this];
  ARGVX3(0,_player,objNull);
  ARGVX3(1,_obj,objNull);


  if (isNull _obj) exitWith {};

  def(_hours_alive);
  _hours_alive = [_player] call p_trackStorageHoursAlive;

  init(_weapons,[]);
  init(_partial_magazines,[]);
  init(_full_magazines,[]);
  init(_items,[]);
  init(_backpacks,[]);

  // Save weapons & ammo
  _weapons = (getWeaponCargo _obj) call cargoToPairs;
  _items = (getItemCargo _obj) call cargoToPairs;
  _backpacks = (getBackpackCargo _obj) call cargoToPairs;
  [_obj, _full_magazines, _partial_magazines] call sh_fillMagazineData;

  def(_storage);
  _storage =
  [
    ["Class", typeOf _obj],
    ["HoursAlive", _hours_alive],
    ["Weapons", _weapons],
    ["Items", _items],
    ["Backpacks", _backpacks],
    ["PartialMagazines", _partial_magazines],
    ["FullMagazines", _full_magazines]
  ];

  _player setVariable ["private_storage", _storage, true];
  (_storage)
};

fn_applyPlayerParking = {
  if (!isARRAY(_this)) exitWith {
    diag_log format["WARNING: No player private parking data"];
  };
  init(_data,_this);


  diag_log "#############################################";
  diag_log "Dumping _parkingData";
  [_data] call p_dumpHash;

  init(_parked_vehicles,[]);

  def(_vehicle_info);
  {if (true) then {
    _vehicle_info = _x;
    if (!isARRAY(_vehicle_info) || {count(_vehicle_info) < 2}) exitWith {};

    def(_vehicle_id);

    _vehicle_id = _vehicle_info select 0;
    if (!isSTRING(_vehicle_id)) exitWith {};

    def(_vehicle_data);
    _vehicle_data = _vehicle_info select 1;
    if (!isCODE(_vehicle_data)) exitWith {};
    _parked_vehicles pushBack [_vehicle_id, (call _vehicle_data)];
  };} forEach _data;

  player setVariable ["parked_vehicles",_parked_vehicles,true];
};


p_restoreInfo = {
  ARGVX2(0,_hash);
  if (!isCODE(_hash)) exitWith {};
  format["%1 call p_restoreInfo;", _this] call p_log_finest;
  def(_data);
  _data = call _hash;

  OR(_data,nil) call fn_applyPlayerInfo;
};

p_restoreStorage = {
  ARGVX2(0,_hash);
  if (!isCODE(_hash)) exitWith {};
  format["%1 call p_restoreStorage;", _this] call p_log_finest;
  def(_data);
  _data = call _hash;

  OR(_data,nil) call fn_applyPlayerStorage;
};

p_restoreParking = {
  ARGVX2(0,_hash);
  if (!isCODE(_hash)) exitWith {};
  format["%1 call p_restoreParking;", _this] call p_log_finest;
  def(_data);
  _data = call _hash;

  OR(_data,nil) call fn_applyPlayerParking;
};



p_restoreScore = {
  ARGVX2(0,_hash);
  if (!isCODE(_hash)) exitWith {};
  diag_log format["%1 call p_restoreScore;",_this];
  def(_data);
  _data = call _hash;

  def(_key);
  def(_value);

  {if (true) then {
    if (!isARRAY(_x)) exitWith {};

    _key = _x select 0;
    _value = _x select 1;
    if (!isSCALAR(_value)) exitWith {};

    diag_log format["Restoring %1 = %2", _key, _value];

    [player, _key, _value] call fn_setScore;
  };} forEach _data;

};

p_preloadEnabled = {
  (profileNamespace getVariable ["A3W_preloadSpawn", true])
};

p_preloadPosition = {
  ARGV3(0,_pos,[]);

  if (!(call p_preloadEnabled || {undefined(_pos)})) exitWith {
    player groupChat "Loading previous location...";
  };

  _pos set [2,OR(_pos select 2,0)];
   player groupChat "Preloading previous location...";
   waitUntil {sleep 0.1; preloadCamera _pos};
};

p_firstSpawn = {
  player enableSimulation true;
  player allowDamage true;
  player setVelocity [0,0,0];
  format["%1 call p_firstSpawn;", _this] call p_log_finest;

  execVM "client\functions\firstSpawn.sqf";
};

p_restoreData = {
  diag_log format["%1 call p_restoreData",_this];
  ARGV2(0,_data);
  format["%1 call p_restoreData;", _this] call p_log_finest;

  def(_exit);
  _exit = {
    player allowDamage true;
    call p_firstSpawn;
    playerData_loaded = true;
  };

  def(_dataValid);
  _dataValid = (isARRAY(_data) && {count(_data) > 0});

  if (!_dataValid) exitWith {
    format["Saved data for %1 is not valid;", player] call p_log_finest;
    call _exit;
  };

   playerData_alive = true;
   [_data] call fn_applyPlayerData;
   call _exit;
};

p_getScope = {
  ARGVX3(0,_id,"");
  format["%1 call p_getScope;", _this] call p_log_finest;
  waitUntil {not(isNil "PDB_PlayerFileID")};
  (format["%1%2",PDB_PlayerFileID,_id])
};

p_dumpHash = {
  ARGVX3(0,_data,[]);

  def(_key);
  def(_value);
  {
    _key = _x select 0;
    _value = _x select 1;
    diag_log (_key + " = " + str(OR(_value,nil)));
  } forEach _data;
};

fn_requestPlayerData = {[] spawn {
  init(_player,player);
  init(_uid,getPlayerUID player);
  init(_scope,[_uid] call p_getScope);
  format["%1 call fn_requestPlayerData;", _this] call p_log_finest;


  playerData_alive = nil;
  playerData_loaded = nil;
  playerData_resetPos = nil;
  init(_genericDataKey, "PlayerSave");
  init(_infoKey, "PlayerInfo");
  init(_scoreKey, "PlayerScore");
  init(_storageKey, "PlayerStorage");
  init(_parkingKey, "PlayerParking");


  def(_worldDataKey);
  _worldDataKey = format["%1_%2", _genericDataKey, worldName];

  def(_pData);
  _pData = [_scope, [_genericDataKey, nil], [_worldDataKey, nil], [_infoKey, nil], [_storageKey, nil], [_parkingKey, nil], [_scoreKey, nil]] call stats_get;
  if (not(isARRAY(_pData))) exitWith {
    //player data did not load, force him back to lobby
    endMission "LOSER";
  };

  def(_worldData);
  def(_genericData);

  def(_key);
  {
    _key = xGet(_x,0);
    switch(_key) do {
      case _genericDataKey: {
        _genericData = xGet(_x,1);
      };
      case _worldDataKey: {
        _worldData = xGet(_x,1);
      };
      case _storageKey: {
        [xGet(_x,1)] call p_restoreStorage;
      };
      case _parkingKey: {
        [xGet(_x,1)] call p_restoreParking;
      };
      case _infoKey: {
        [xGet(_x,1)] call p_restoreInfo;
      };
      case _scoreKey: {
        [xGet(_x,1)] call p_restoreScore;
      };
    };
  } forEach _pData;

  //merge the world specific data, with the generic data
  _genericData = OR(call _genericData,[]);
  _worldData = OR(call _worldData,[]);

  /**
   * If the world is Stratis, ignore the legacy generic "Position".
   * The legacy "Position" field should only be used for "Altis"
   */
  if (worldName == "Stratis") then {
    [_genericData, "Position"] call hash_remove_key;
  };

  diag_log "#############################################";
  diag_log "Dumping _genericData";
  [_genericData] call p_dumpHash;

  diag_log "#############################################";
  diag_log "Dumping _worldData";
  [_worldData] call p_dumpHash;

  def(_allData);
  _allData = [_genericData, _worldData] call hash_set_all;
  [_allData] call p_restoreData;

};};



p_handle_mprespawn = {
  	ARGV3(0,_unit,objNull);
  	ARGV3(1,_corpse,objNull);
    //diag_log format["%1 call p_handle_mprespawn;", _this];

    if (not(local _unit)) exitWith {};
    trackMe = [_unit];
    publicVariableServer "trackMe";
};


player addMPEventHandler ["MPRespawn",{ _this call p_handle_mprespawn }];



diag_log "pFunctions.sqf loading complete";

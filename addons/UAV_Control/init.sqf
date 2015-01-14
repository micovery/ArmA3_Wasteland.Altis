if (isServer) exitWith {};

call compile preprocessFileLineNumbers "addons\UAV_Control\config.sqf";

if (A3W_onlyUavOwner) then
{
  [] spawn {
    while {true} do {
      waitUntil {sleep 0.1; !(isNull (getConnectedUAV player))};
      _uav = getConnectedUAV player;
      //Add keychain check in future
      if (((_uav getVariable ["ownerUID",""]) != (getPlayerUID player)) && !(_uav isKindOf "UAV_01_base_F")) then {
        player connectTerminalToUAV objNull;
        ["You can't control this UAV. It doesn't belong to you", 5] call mf_notify_client;	
      };
    };
  };
};
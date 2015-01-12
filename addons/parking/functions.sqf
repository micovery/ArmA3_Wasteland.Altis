call compile preprocessFileLineNumbers "addons\parking\config.sqf";

{
  call compile preprocessFileLineNumbers format["addons\parking\%1_functions.sqf", _x];
} forEach ["misc", "list_simple_menu", "pp_interact", "pp_saving", "pp_actions"];

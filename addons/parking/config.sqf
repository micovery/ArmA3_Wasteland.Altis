
//List of cities where private parking is available (empty or unset means all cities)
pp_cities_whitelist = ["Katalaki", "Agios Konstantinos", "Ioannina", "Panagia"];

//whether or not to show map markers for private parking locations
pp_markers_enabled = true; 

//shape, type, color, size, text (for map markers, if enabled)
pp_markers_properties = ["ICON", "mil_dot", "ColorKhaki", [1.2,1.2], "Parking"];

//number of seconds to wait (after joining the sever) before a vehicle can be retrieved (0 = no wait)
pp_retrieve_wait = 60;

//amount of money to charge player for retrieving a vehicle from parking (0 = no charge)
pp_retrieve_cost = 1500;

//maximum number of vehicles that a player can park (0 = no limit)
pp_max_player_vehicles = 2;

//List of class names for vehicles that are not allowed to be parked
pp_disallowed_vehicle_classes = [];

/**
 * * Name: Bash model for the basic scenario
 * * Annotation: The current model is for documentation purpose only since no data are online available 
* 
*/


model bornstedt_rdt_last_mile_basic_scenario


global  {
 	int counter_1st_try;
 	int counter_2nd_try;
 	int counter_3rd_try;
	int temp_counter <- 0;
	file waw_classifier <- text_file("C:/Users/diego/smartuplab/smartuplab/SmartUpLab/includes/waw_classifier.R");
	file wew_classifier <- text_file("C:/Users/diego/smartuplab/smartuplab/SmartUpLab/includes/wew_classifier.R");
	file wfw_classifier <- text_file("C:/Users/diego/smartuplab/smartuplab/SmartUpLab/includes/wfw_classifier.R");

// headless relevant variables
	bool include_new_bus_line;	
// input strings for loading and saving data
	string people_df;
	string scenario_name;
// load environment from shapefile
	file shape_file_bounds <- file("C:/Users/diego/smartuplab/smartuplab/SmartUpLab/includes/___BORNSTEDT/EPSG25833/Bornstedt_100m_BufferEPSG25833.shp");
	geometry shape <- envelope(shape_file_bounds);

// time related variables
	float step <- 1 #s;
	date starting_date <- date([2020,10,21,3,59,50]);
	
// define range of working time
	int mean_work_start <- 8;
	float std_work_start <- 1.0;
	int mean_work_end <- 17; 
	float std_work_end <- 1.0;

// define the netowrks and the related variables
	
	// motor vehicle network
	graph road_network;
	list<intersections> driving_intersections;
	list<road> driving_roads;
		
	// pedestrian network
	graph pedestrian_network;
	list<intersections> cycling_intersections;
	
	// bike network
	graph bike_network;
	list<intersections> walking_intersections;
	
	// Bus departure times matrix
	matrix bus_departures;
	matrix rdt_departures;
	file departure_csv <- csv_file("C:/Users/diego/smartuplab/smartuplab/SmartUpLab/includes/___BORNSTEDT/EPSG25833/relevant_departure_times.csv", ';', string, true);
	//file rdt_departure_csv <- csv_file("C:/Users/diego/smartuplab/smartuplab/SmartUpLab/includes/___BORNSTEDT/EPSG25833/rdt_departure_times.csv", ';', string, true);
	file rdt_departure_csv;
	
	list bus_departure_hours;
	list rdt_departure_hours;
	list bus_departure_minutes;
	list rdt_departure_minutes;
	list bus_departure_lines;
	list rdt_departures_lines;
	list bus_departure_hour_min;
	list rdt_departure_hour_min;
	map<string,string> bus_schedule;
	
	// all pt stops and datas
	list<intersections> bus_stops;
	list<tram_stops>all_tram_stops;
	list<intersections> pt_stops;
	list<intersections> bus_exits;
	list<intersections> bus_entries;
	intersections tram_exit;
	intersections bus_south_exit;
	list<intersections>intersections_closest_to_tram_stops;
	list<intersections>intersections_closest_to_tram_stops_92;
	list<intersections>intersections_closest_to_tram_stops_96;
	map<tram_stops,intersections>tram_stop_pedestrian_goals;
	map<string,list> bus_lines_map;
	
	// Bus 609 vehicle network
	graph bus609_network;
	list<intersections> bus609_intersections;
	list<road> bus609_roads;
	list<intersections> bus609a_stops;
	list<intersections> bus609b_stops;
	
	// Bus 612 vehicle network
	graph bus612_network;
	list<intersections> bus612_intersections;
	list<road> bus612_roads;
	list<intersections> bus612a_stops;
	list<intersections> bus612b_stops;
	
	// Bus 614 vehicle network
	graph bus614_network;
	list<intersections> bus614_intersections;
	list<road> bus614_roads;
	list<intersections> bus614a_stops;
	list<intersections> bus614b_stops;
	
	// Bus 638 vehicle network
	graph bus638_network;
	list<intersections> bus638_intersections;
	list<road> bus638_roads;
	list<intersections> bus638a_stops;
	list<intersections> bus638b_stops;
	
	// Bus 650 vehicle network
	graph bus650_network;
	list<intersections> bus650_intersections;
	list<road> bus650_roads;
	list<intersections> bus650a_stops;
	list<intersections> bus650b_stops;
	
	// Bus 692 vehicle network
	graph bus692_network;
	list<intersections> bus692_intersections;
	list<road> bus692_roads;
	list<intersections> bus692a_stops;
	list<intersections> bus692b_stops;
	
	// Bus 697 vehicle network
	graph bus697_network;
	list<intersections> bus697_intersections;
	list<road> bus697_roads;
	list<intersections> bus697a_stops;
	list<intersections> bus697b_stops;
	
	// Bus 698 vehicle network
	graph bus698_network;
	list<intersections> bus698_intersections;
	list<road> bus698_roads;
	list<intersections> bus698a_stops;
	list<intersections> bus698b_stops;
	
	// Tram 92
	graph tram92_network;
	list<tram_stops>tram92a_stops;
	list<tram_stops>tram92b_stops;	
	// Tram 96
	graph tram96_network;
	list<tram_stops>tram96a_stops;
	list<tram_stops>tram96b_stops;
	
	// Bus line created from the interface
	list<intersections> new_busa_stops;
	list<intersections> new_busb_stops;
	list<intersections> rdt2bus_switching_stations;
	list<intersections> bus2rdt_switching_stations;
	list<intersections> tram2rdt_switching_stations;
	list<intersections> rdt2tram_switching_stations;
	tram_stops tram_lines_crossing_station;
	intersections intersection_tram_lines_crossing_station;
	int perc_pick_up_service;
	int rdt_capacity;
	
// vehicles related variables
	list<intersections> commuters_doors_entry;
	list<intersections> commuters_doors_exit;
	list<intersections> commuters_doors_exit_for_cars;
	map<intersections, float> commuters_doors_exit_map;
	map<intersections, float> commuters_doors_exit_for_cars_map;
	map<road, float>motor_speed_map;
	map<road,float>not_motor_speed_map;
// define n_of_agents_driving_through
	int time_to_change <- 30;
	
// infrastructures related variables
	list<buildings> possible_working_places;
	list<buildings> possible_shopping_places;
	list<buildings> possible_leisure_places;
	
// display related variables
	
	// stats and saving
 	bool block_stats <- false;
 	
 	// modal stats
 	int working_car; 
 	int working_bike;
 	int working_pt;
 	int working_pedestrian;
	int shopping_car; 
 	int shopping_bike;
 	int shopping_pt;
 	int shopping_pedestrian;
 	int leisure_car; 
 	int leisure_bike;
 	int leisure_pt;
 	int leisure_pedestrian;
  	int school_car; 
 	int school_bike;
 	int school_pt;
 	int school_pedestrian;
 	
 	// highlighting & displaying
 	string display_switcher_roads;
 	string display_switcher_buildings;
 
 	// bus line modifications / interactions
 	float max_dist_to_bus_stop ;
 	float max_dist_to_tram_stop;
 	float max_dist_to_pt_stop;
 	float max_dist_to_shopping ;
 	float median_dist_build_pt;
 
   	// Distance to the stop considerable acceptable
	int walking_to_bus_tollerance <- 300°m; // value defined following the definition of the city of potsdam 
	int walking_to_tram_tollerance <- 350°m; // value defined following the definition of the city of potsdam	
	 // r related
	list<people> deciding_agents;
	
	// sql related
	map<string,string> PARAMS <- ['host'::'localhost', 'dbtype'::'Postgres', 'database'::'Bornstedt_Data', 'port'::'5432', 'user'::'postgres', 'passwd'::'root'];		
	
	////////////////////
	// Initialisation //
	////////////////////
	
	init {
		write rdt_capacity;
		

		
			
		///// CREATE A RESULT DF IN POSTGRES
		create (DB_accessor) {
			// save modal split data
				do executeUpdate (params: PARAMS, updateComm: "DROP TABLE IF EXISTS results_" + scenario_name + "_modal_split ");
				do executeUpdate params: PARAMS updateComm: "CREATE TABLE results_" + scenario_name + "_modal_split (
																											cycle 	INTEGER,
																											working_car INTEGER,
																											working_bike INTEGER,  
																											working_pedestrian INTEGER, 
																											working_pt INTEGER, 
																											shopping_car INTEGER, 
																											shopping_bike INTEGER, 
																											shopping_pedestrian INTEGER,
																											shopping_pt INTEGER, 			 
																											leisure_car INTEGER, 
																											leisure_bike INTEGER,
																											leisure_pedestrian INTEGER, 
																											leisure_pt INTEGER, 
																											school_car INTEGER, 
																											school_bike INTEGER, 
																											school_pedestrian INTEGER, 
																											school_pt INTEGER);";
			// save rdt data																								
				do executeUpdate (params: PARAMS, updateComm: "DROP TABLE IF EXISTS results_" + scenario_name + "_rdt_data ");
				do executeUpdate params: PARAMS updateComm: "CREATE TABLE results_" + scenario_name + "_rdt_data (
																											start_trip_time 	TEXT,
																											trip_duration INT,
																											pick_up_calls_times TEXT, 
																											door_delivery_times TEXT,
																											pick_up_counter INTEGER, 
																											door_delivery_counter INTEGER, 
																											passengers_by_stop TEXT);";

			// save people data																								
				do executeUpdate (params: PARAMS, updateComm: "DROP TABLE IF EXISTS results_" + scenario_name + "_people_data ");
				do executeUpdate params: PARAMS updateComm: "CREATE TABLE results_" + scenario_name + "_people_data (
																											Personal_ID TEXT,
																											modi TEXT,
																											currently_doing TEXT,
																											origin_x NUMERIC,
																											origin_y NUMERIC,
																											destination_x NUMERIC,
																											destination_y NUMERIC,
																											rdt_passenger BOOL, 
																											rdt_pick_up_candidate BOOL,
																											n_of_vehicle_switch INT,
																											start_trip_time 	TEXT,
 																											trip_duration INT,
																											waiting_time_in_sec INT,
																											waiting_time_in_sec2 INT,
																											reach_the_vehicle_duration INT,
																											reach_the_destination_duration INT,
																											time_in_vehicle INT,
																											time_in_vehicle2 INT);";
			}
		

		///// CREATE INTERSECTIONS /////
		
		// a global variable determine, wheter the column with the new bus line has to be selected
		string QUERY_intersections <- "SELECT gid, type, traf_light, stop_sign, is_entry, is_exit, entries, exits, bus609a, bus609b, bus612a, bus612b, bus614a, bus614b, bus638a, bus638b,
												bus650a, bus650b, bus692a, bus692b, bus697a, bus697b, bus698a, bus698b,
												ST_AsEWKB(geom) as geom FROM bornstedt_nodes_epsg25833_v2;";
				ask DB_accessor {
					create intersections from: select(PARAMS, QUERY_intersections)
									 with:[id::"gid",
									 		type::"type",
											is_traffic_light::"traf_light",
											is_stop_sign::"stop_sign",
											is_entry::"is_entry",
											is_exit::"is_exit",
											entries::"entries",
											exits::"exits",
											bus609a::"bus609a",
											bus609b::"bus609b",
											bus612a::"bus612a",
											bus612b::"bus612b",
											bus614a::"bus614a",
											bus614b::"bus614b",
											bus638a::"bus638a",
											bus638b::"bus638b",
											bus650a::"bus650a",
											bus650b::"bus650b",
											bus692a::"bus692a",
											bus692b::"bus692b",
											bus697a::"bus697a",
											bus697b::"bus697b",
											bus698a::"bus698a",
											bus698b::"bus698b",
											shape::"geom"];
				 }
		ask intersections {
			/////// temp adjustment
			is_stop_sign <- false;
		}
			 
		// if data for a customized bus line are provided, they are read from the database and matched with the node layer
		if include_new_bus_line = true {
			string QUERY_intersections_options <- "SELECT fid, new_bus_line FROM " + scenario_name + "_nodes_df;";
			matrix new_bus_line_matrix;
			list<string> fid_list;
			list<string> new_bus_line_list;
			ask (DB_accessor) {
	               list<list> temp <- self.select(params:PARAMS, 
	                         select:QUERY_intersections_options);
	                new_bus_line_matrix <- matrix(transpose(matrix(temp[2])));
	                loop i from: 0 to: new_bus_line_matrix.rows -1 {
						add string(int(new_bus_line_matrix[0,i])) to: fid_list;
						add string(int(new_bus_line_matrix[1,i])) to: new_bus_line_list;
					}    
	           }
	           ask intersections where (each.id in fid_list) {
	           		int temp <- fid_list index_of self.id;
	           		self.new_bus_line <- new_bus_line_list at temp;
	           }
	           // read the capacity value
	           string QUERY_simulation_options <- "SELECT capacity, perc_of_door_pick_up FROM " + scenario_name + "_options_df;";
	           	ask (DB_accessor) {
	               list<list<list>> temp <- self.select(params:PARAMS, 
	                         select:QUERY_simulation_options);
	                string temp_cap <- temp[2];
	                temp_cap <- replace(temp_cap, "[","");
	                temp_cap <- replace(temp_cap, "]","");
	                list temp_list <- temp_cap split_with(",", false);
					rdt_capacity <- temp_list[0];
					perc_pick_up_service <- temp_list[1];
	           }
		}

		// reduce the traffic lights to close to one other
		map grouped_intersections <- list(intersections) group_by (each.location);
		loop group over: grouped_intersections.values {
			if length(group) > 1 {
				intersections to_keep <- group first_with (each.is_traffic_light);
				if to_keep = nil {to_keep <- first(group);}
				ask (group - to_keep) {
					do die;
				}
			}
		}
		
		// To initialize red and green signal of traffic light: intersections have 50% chance to have the roads_in filled filled and beeing hence red
		ask intersections where each.is_traffic_light {
			stop << flip(0.5) ? roads_in : [] ;
		}
		
		// create sequences of bus stops for the already existing bus lines		
		bus609a_stops <- (intersections where (each.bus609a > 0)) sort_by (intersections(each).bus609a);
		bus609b_stops <- (intersections where (each.bus609b > 0)) sort_by (intersections(each).bus609b);
		bus612a_stops <- (intersections where (each.bus612a > 0)) sort_by (intersections(each).bus612a);
		bus612b_stops <- (intersections where (each.bus612b > 0)) sort_by (intersections(each).bus612b);
		bus614a_stops <- (intersections where (each.bus614a > 0)) sort_by (intersections(each).bus614a);
		bus614b_stops <- (intersections where (each.bus614b > 0)) sort_by (intersections(each).bus614b);
		bus638a_stops <- (intersections where (each.bus638a > 0)) sort_by (intersections(each).bus638a);
		bus638b_stops <- (intersections where (each.bus638b > 0)) sort_by (intersections(each).bus638b);
		bus650a_stops <- (intersections where (each.bus650a > 0)) sort_by (intersections(each).bus650a);
		bus650b_stops <- (intersections where (each.bus650b > 0)) sort_by (intersections(each).bus650b);
		bus692a_stops <- (intersections where (each.bus692a > 0)) sort_by (intersections(each).bus692a);
		bus692b_stops <- (intersections where (each.bus692b > 0)) sort_by (intersections(each).bus692b);
		bus697a_stops <- (intersections where (each.bus697a > 0)) sort_by (intersections(each).bus697a);
		bus697b_stops <- (intersections where (each.bus697b > 0)) sort_by (intersections(each).bus697b);
		bus698a_stops <- (intersections where (each.bus698a > 0)) sort_by (intersections(each).bus698a);
		bus698b_stops <- (intersections where (each.bus698b > 0)) sort_by (intersections(each).bus698b);
		
		// to be activated if a customized bus line has to be included
		if include_new_bus_line {
			new_busa_stops <- (intersections where (each.new_bus_line > 0)) sort_by (intersections(each).new_bus_line);
			new_busb_stops <- reverse(new_busa_stops);
		}
		
		///// CREATE TRAM LINES /////
		string QUERY_tram_lines <- "SELECT tram96, tram92, ST_AsEWKB(geom) as geom FROM Bornstedt_tram_lines__EPSG25833;";
		
		ask DB_accessor {
			create tram_lines from: select(PARAMS, QUERY_tram_lines)
							 with:[tram96::"tram96",
							 		tram92::"tram92",
									shape::"geom"];
		 }
				
		///// CREATE TRAM STOPS /////
		string QUERY_tram_stops <- "SELECT tram96, tram92, ST_AsEWKB(geom) as geom FROM Bornstedt_tram_stops_EPSG25833;";
		
		ask DB_accessor {
			create tram_stops from: select(PARAMS, QUERY_tram_stops)
							 with:[tram96::"tram96",
							 		tram92::"tram92",
									shape::"geom"];
		 }
		 
		///// CREATE EDUCATIONAL BUILDINGS /////
		string QUERY_educational_building <- "SELECT is_kita, is_school, kita_id, schul_nr, blk_idz, ST_AsEWKB(geom) as geom FROM bornstedt_buildings_kita_school_epsg25833;";
		
		ask DB_accessor {
			create educational_buildings from: select(PARAMS, QUERY_educational_building)
							 with:[is_kita::"is_kita",
							 		is_school::"is_school",
									kita_id::"kita_id",
									school_id::"schul_nr",
									block::"blk_idz",
									shape::"geom"];
		 }
		 // unify the ids
		 ask educational_buildings {
		 	if kita_id != nil {
				id <- kita_id;
			} else if school_id != nil {
				id <- school_id;
			}
		 }
		
		///// CREATE FUNCTIONAL BUILDINGS (working, shopping, leisure places) /////
		string QUERY_functional_building <- "SELECT rec_id, is_shoppin, is_working, is_leisure, is_educati, blk_idz, ST_AsEWKB(geom) as geom FROM bornstedt_buildings_working_shopping_leisure_v2;";
		
		ask DB_accessor {
			create functional_buildings from: select(PARAMS, QUERY_functional_building)
							 with:[id::"rec_id",
							 		is_shopping::"is_shoppin",
									is_working_place::"is_working",
									is_leisure::"is_leisure",
									is_education::"is_educati",
									block::"blk_idz",
									shape::"geom"];
		 }
				
		///// CREATE LIVING BUILDINGS /////
		string QUERY_living_building <- "SELECT __oid, blk_idz, bus_cost, tram_cost, kita_cost, schul_cost, shop_cost,
											bus_node, tram_id, schul_id, kita_id, shop_id, housetyp, wohnungen,
											ST_AsEWKB(geom) as geom FROM bornstedt_buildings_living_epsg25833_2021_08_14_v5;";
		
		ask DB_accessor {
			create living_building from: select(PARAMS, QUERY_living_building)
							 with:[id::"__oid",
							 		block::"blk_idz",
									walk_dist_to_bus_stop::"bus_cost",
									walk_dist_to_tram_stop::"tram_cost",
									walk_dist_to_kita::"kita_cost",
									walk_dist_to_school::"schul_cost",
									walk_dist_to_shopping_place::"shop_cost",
									closest_school::"schul_id",
									closest_kita::"kita_id",
									closest_shop::"shop_id",
									house_type::"housetyp",
									n_households::"wohnungen",
									shape::"geom"];
		 }
		 ask living_building {
		 	write id + " " + block + " " + n_households;
		 }
		 
		 ask living_building where (each.walk_dist_to_bus_stop > 0) {
				if walk_dist_to_bus_stop > walk_dist_to_tram_stop {
					walk_dist_to_pt_stop <- self.walk_dist_to_tram_stop;
				} else {
					walk_dist_to_pt_stop <- self.walk_dist_to_bus_stop;
				}
		 }
			
		// create a list of possible living, working, shopping and leisure places in the research area
		possible_working_places <- functional_buildings where (each.is_working_place = true);
		possible_shopping_places <- functional_buildings where (each.is_shopping = true);
		possible_leisure_places <- functional_buildings where (each.is_leisure = true);
		
		///// CREATE ROADS /////
		string QUERY_roads <- "SELECT fclass, oneway, maxspeed, lanes, motorAllow, bikeAllow, pedAllow,
											bus609, bus612, bus614, bus638, bus650, bus692, bus697, bus698,
											ST_AsEWKB(geom) as geom FROM bornstedt_roads_2021_08_03_epsg25833;";
													
		// import
		ask DB_accessor {
			create road from: select(PARAMS, QUERY_roads)
							 with:[road_type::"fclass",
							 		oneway::"oneway",
									maxspeed:: 'maxspeed',
									lanes::"lanes",
									motor_vehicles_allowed::"motorallow",
									bikes_allowed::"bikeallow",
									pedestrians_allowed::"pedallow",
									bus609::"bus609",
									bus612::"bus612",
									bus614::"bus614",
									bus638::"bus638",
									bus650::"bus650",
									bus692::"bus692",
									bus697::"bus697",
									bus698::"bus698",
									shape::"geom"];
		}
		
		ask road
		// add colors based on fclass following osm convention
		{
			if display_switcher_roads = "Open street map" {
				if road_type="primary" {
					color <- rgb(254, 215, 161) ; 
				} else if road_type="secondary"{
					color <- rgb(247, 250, 187) ;
				} else if road_type="motorway_link"{
					color <- rgb(233, 144, 161) ;
				} else if road_type="residential"{
					color <- rgb(255, 255, 255) ;
				} else if road_type="tertiary"{
					color <- rgb(255, 255, 255) ;
				} else if road_type="service"{
					color <- rgb(255, 255, 255) ;
				} else if road_type="footway"{
					color <- rgb(249, 160, 149) ;
				} else if road_type="living_street"{
					color <- rgb(237, 238, 237) ;
				} else if road_type="cycleway"{
					color <- rgb(82, 81, 251) ;
				} else if road_type="unclassified"{
					color <- rgb(255, 255, 255) ;
				} else if road_type="primary_link"{
					color <- rgb(255, 226, 186) ;
				} else if road_type="path"{
					color <- rgb(248, 190, 182) ;
				} else if road_type="track_grade1"{
					color <- rgb(196, 152, 66) ;
				} else if road_type="track_grade2"{
					color <- rgb(196, 152, 66) ;
				} else if road_type="track_grade3"{
					color <- rgb(196, 152, 66) ;
				} else if road_type="track_grade4"{
					color <- rgb(196, 152, 66) ;
				} else if road_type="track_grade5"{
					color <- rgb(196, 152, 66) ;
				} else if road_type="track"{
					color <- rgb(164, 118, 16) ;
				} else if road_type="steps"{
					color <- rgb(248, 179, 168) ;
				} else if road_type="pedestrian"{
					color <- rgb(254, 118, 100) ;
				} else if road_type="motorway"{
					color <- rgb(234, 144, 160) ;
				} else {
					color <- #gray ;
				}
			// add colors for distinguishing bus lines paths
			} else if display_switcher_roads =  "Public transport" {
				color <- #gray;
				if bus609=true {
					color <- #black ;
				}
				if bus612=true {
					color <- #black ;
				}
				if bus614=true {
					color <- #black;	
				}
				if bus638=true {
					color <- #black;
				}
				if bus650=true {
					color <- #black ;
				}
				if bus692=true {
					color <- #black ;
				}
				if bus697=true {
					color <- #black ;
				}
				if bus698=true {
					color <- #black ;
				}				
			// add colors for distinguishing roads based on car-free or car-dedicated
			} else if display_switcher_roads = "Road vehicle categories" {
				if motor_vehicles_allowed = true {
					color <- #orange;
				} else {
					color <- #darkgreen;
				}
			}	
		}
   
		//////// CREATE ROAD NETWORK FOR CARS ////////
		
		/// first a network with all roads is initialized
		road_network <- (as_driving_graph(road, intersections));
		// each intersections check if it is connected from al least one side to a road that is allowed for motor vehicles
		ask intersections {
			list<road> temp <- self.roads_in;
			if  temp count (each.motor_vehicles_allowed = true) > 0 {
				self.has_motor_vehicles_allowed_roads_in <- true;
			}
			list<road> temp <- self.roads_out;
			if  temp count (each.motor_vehicles_allowed = true) > 0 {
				self.has_motor_vehicles_allowed_roads_out <- true;
			}
			if has_motor_vehicles_allowed_roads_in = true or has_motor_vehicles_allowed_roads_out = true {
				has_motor_vehicles_allowed_one_of <- true;
			}
		}
		
		// Having information about road that can be driven by car...
		// a list of entry and exit doors is created and accessible from other agents, moreover a map with exit doors and ajusted proabilities is prepared and will be used to define exits
		do set_entry_exit_doors;
	
		// a list of intersections and roads that allows motor vehicles is created		
		driving_intersections <- intersections where (each.has_motor_vehicles_allowed_roads_in = true and each.has_motor_vehicles_allowed_roads_in = true);
		driving_roads <- road where (each.motor_vehicles_allowed = true and
			(each.road_type != "path" or each.road_type != "cycleway" or each.road_type != "footway" or each.road_type != "pedestrian" or each.road_type != "steps" or each.road_type != "track" or each.road_type != "track_grade2" or each.road_type != "track_grade3"));
		
		// create a map (dictionnary) with the driving road and speed_limit as the weight coefficient
		motor_speed_map <- driving_roads as_map (each::(each.shape.perimeter  / each.maxspeed));
		not_motor_speed_map <- road as_map (each::each.shape.perimeter);
		
		// overwrite the road network to become a motor vechicle network with only driving roads and intersections
		road_network <- (as_driving_graph(driving_roads, driving_intersections) with_weights motor_speed_map);
		road_network <- main_connected_component(road_network);
		driving_intersections <- road_network.vertices;
		
		//////// CREATE THE PEDESTRIAN NETWORK ////////
		pedestrian_network <- as_edge_graph (road where (each.pedestrians_allowed = true)) with_weights not_motor_speed_map;
		pedestrian_network <- main_connected_component(pedestrian_network);
		
		//////// CREATE THE BIKE NETWORK //////// 	
		bike_network <- as_edge_graph (road where (each.bikes_allowed = true)) with_weights not_motor_speed_map;
		bike_network <- main_connected_component(bike_network);
		
		// set closest_intersec when the final moving / driving networks are defined
		do set_closest_intersec_buildings;
			
		//////// CREATE THE BUS NETWORK ////////

		// create the 609 bus network
		bus609_intersections <- intersections where (each.bus609a >= 0 or each.bus609b >= 0);
		bus609_roads <- clean_network(road where (each.bus609 = true), 12.0, true, true);
		bus609_network <- (as_driving_graph(bus609_roads, bus609_intersections) with_weights motor_speed_map);

		// create the 612 bus network
		bus612_intersections <- intersections where (each.bus612a >= 0 or each.bus612b >= 0);
		bus612_roads <- clean_network(road where (each.bus612 = true), 14.0, true, false);
		bus612_network <- (as_driving_graph(bus612_roads, bus612_intersections) with_weights motor_speed_map);

		// create the 614 bus network
		bus614_intersections <- intersections where (each.bus614a >= 0 or each.bus614b >= 0);
		bus614_roads <- clean_network(road where (each.bus614 = true), 3.0, true, false);
		bus614_network <- (as_driving_graph(bus614_roads, bus614_intersections) with_weights motor_speed_map);
		
		// create the 638 bus network
		bus638_intersections <- intersections where (each.bus638a >= 0 or each.bus638b >= 0);
		bus638_roads <- clean_network(road where (each.bus638 = true), 10.0, true, false);
		bus638_network <- (as_driving_graph(bus638_roads, bus638_intersections) with_weights motor_speed_map);
	
		// create the 650 bus network
		bus650_intersections <- intersections where (each.bus650a >= 0 or each.bus650b >= 0);
		bus650_roads <- clean_network(road where (each.bus650 = true), 4.0, true, false);
		bus650_network <- (as_driving_graph(bus650_roads, bus650_intersections) with_weights motor_speed_map);
		
		// create the 692 bus network
		bus692_intersections <- intersections where (each.bus692a >= 0 or each.bus692b >= 0);
		bus692_roads <- clean_network(road where (each.bus692 = true), 12, true, false);
		bus692_network <- (as_driving_graph(bus692_roads, bus692_intersections) with_weights motor_speed_map);
		
		// create the 697 bus network
		bus697_intersections <- intersections where (each.bus697a >= 0 or each.bus697b >= 0);
		bus697_roads <- clean_network(road where (each.bus697 = true), 10, true, false);
		bus697_network <- (as_driving_graph(bus697_roads, bus697_intersections) with_weights motor_speed_map);
		
		// create the 698 bus network
		bus698_intersections <- intersections where (each.bus698a >= 0 or each.bus698b >= 0);
		bus698_roads <- clean_network(road where (each.bus698 = true), 10, true, false);
		bus698_network <- (as_driving_graph(bus698_roads, bus698_intersections) with_weights motor_speed_map);
		
		//////// CREATE THE TRAM NETWORKS ////////
		// tram 92
		tram92a_stops <- tram_stops where (each.tram92 > 0 and each.tram92 < 9) sort_by (tram_stops(each).tram92);
		tram92b_stops <- tram_stops where (each.tram92 >= 9) sort_by (tram_stops(each).tram92);
		tram92_network <- as_edge_graph (tram_lines where (each.tram92 = true));
		// tram 96
		tram96a_stops <- tram_stops where (each.tram96 > 0 and each.tram96 < 10) sort_by (tram_stops(each).tram96);
		tram96b_stops <- tram_stops where (each.tram96 >= 10) sort_by (tram_stops(each).tram96);
		tram96_network <- as_edge_graph (tram_lines where (each.tram96 = true));
		
		// all tram stops
		all_tram_stops <- tram92a_stops union
							tram92b_stops union
							tram96a_stops union
							tram96b_stops;
		// identify the closest intersection on the pedestrian network for tram 92
		loop i over:tram92a_stops {
			intersections temp <- intersections closest_to i;
			add temp to: intersections_closest_to_tram_stops_92;
			ask temp {
				self.tram92a <- 1;
				self.tram92b <- 1;
			}
		}
		
		// identify the closest intersection on the pedestrian network for tram 96
		loop i over:tram96a_stops {
			intersections temp <- intersections closest_to i;
			add temp to: intersections_closest_to_tram_stops_96;
			ask temp {
				self.tram96a <- 1;
				self.tram96b <- 1;
			}
		}
		
		// all pedestrian tram stop goals
		intersections_closest_to_tram_stops <- intersections_closest_to_tram_stops_96 union 
												intersections_closest_to_tram_stops_92;
		// map with tram stop and corresponding intersection
		tram_stop_pedestrian_goals  <- create_map(all_tram_stops, intersections_closest_to_tram_stops);
		
		// set the tram exit
		tram_exit <- first(intersections_closest_to_tram_stops_96); // since it is equal to intersections_closest_to_tram_stops_96b
		// set the bus exit
		bus_south_exit <- last(bus692b_stops);
		
		// By executing the action set_intersections_for_pt a list of all bus stops is created and intersections receive the list of their bus lines
		do set_intersections_for_pt;
		
		// identify the tram stop for switching with the new bus line
		if include_new_bus_line {			
			ask new_busa_stops {
				
				// identifiy the rdt stops that have a tram stop close to self (less than 50m)
				intersections closest_tram_stop <- intersections_closest_to_tram_stops at_distance (50) closest_to self;
				if closest_tram_stop != nil {
					add self to: rdt2tram_switching_stations;
					add closest_tram_stop to:tram2rdt_switching_stations;
				}		
				// identifiy the rdt stops that have a bus stop close to self (less than 50m)
				intersections closest_bus_stop <- bus_stops at_distance (50) closest_to self;
				if closest_bus_stop != nil {
					add self to: rdt2bus_switching_stations;
					add closest_bus_stop to:bus2rdt_switching_stations;
				}
			}
		}	
		
		///// CREATE THE PARKING AREAS /////
		string QUERY_parking_areas<- "SELECT capacity, ST_AsEWKB(geom) as geom FROM bornstedt_parking_areas_epsg25833;";
		
		ask DB_accessor {
			create parking_areas from: select(PARAMS, QUERY_parking_areas)
							 with:[ available_parking_places::"capacity", shape::"geom"];
		 }
		
		ask parking_areas {
			// if the percentage of parking places has been reduced, the new amount of parking places is going to be calculated, else it is simply took from shp
			available_parking_places <- available_parking_places;
			parking_areas_capacity <- available_parking_places;
		}		
		
		///// CREATE THE PEOPLE /////
		// the input csv is tranformed into a matrix
		string QUERY_people <- "SELECT  block, Personal_ID, age, age_class, household_size, household_category,
									today_activity_plan, household, has_children,employed_status, working_frequency, working_age,
									start_work, minute_start_work, end_work, minute_end_work, leisure_frequency, shopping_frequency,
									start_shopping, minute_start_shopping, end_shopping, minute_end_shopping,
									start_leisure, minute_start_leisure, end_leisure, minute_end_leisure,
									is_commuter, is_leisure_outside, is_shopping_outside, my_working_place_id,
									my_leisure_place_id, my_exit_id, has_car, has_bike,
									consecutive_activity, consecutive_activity_2
								FROM " + people_df + ";";

		ask DB_accessor {
			create people from: select(PARAMS, QUERY_people)
								 with:[ //location::'"{" + "location.x" +","+ "location.y" + "," + "location.z" + "}"', 
								 	block::"block",
								 	Personal_ID::"Personal_ID",
								 	age:: "age",
								 	age_class:: "age_class",
								 	household_size:: "household_size",
								 	household_category:: "household_category",
								 	today_activity_plan:: "today_activity_plan",
								 	household:: "household",
								 	has_children:: "has_children",
								 	employed_status::"employed_status",
								 	working_frequency :: "working_frequency",
								 	shopping_frequency :: "shopping_frequency",
								 	leisure_frequency :: "leisure_frequency",
								 	working_age::"working_age",
								 	start_work:: "start_work",
								 	minute_start_work:: "minute_start_work",
								 	end_work:: "end_work",
								 	minute_end_work:: "minute_end_work",
								 	is_commuter:: "is_commuter",
								 	is_leisure_outside:: "is_leisure_outside",
								 	leisure_frequency:: "leisure_frequency",
								 	start_leisure:: "start_leisure",
								 	minute_start_leisure:: "minute_start_leisure",
								 	end_leisure:: "end_leisure",
								 	minute_end_leisure:: "minute_end_leisure",
								 	start_shopping:: "start_shopping",
								 	minute_start_shopping:: "minute_start_shopping",
								 	end_shopping:: "end_shopping",
								 	minute_end_shopping:: "minute_end_shopping",
								 	shopping_frequency:: "shopping_frequency",
								 	is_shopping_outside::"is_shopping_outside",
								 	my_working_place_id:: "my_working_place_id",
								 	my_leisure_place_id:: "my_leisure_place_id",						 	
								 	my_exit_id:: "my_exit_id",
								 	has_car:: "has_car",
								 	has_bike:: "has_bike",
								 	consecutive_activity:: "consecutive_activity",
								 	consecutive_activity_2:: "consecutive_activity_2"
								 	]
								 {	
								 	write Personal_ID + " " + block ;
								 	// defining walking speed on age based on page 6 of:
									// Bartels, B., & Erbsmehl, C. (2014). Bewegungsverhalten von Fußgängern im Straßenverkehr, Teil 1. FAT-Schriftenreihe, (267).
									// speed divided by 100
									if age >= 0 and age < 4 {
										//walking_speed <- rnd(min_walking_speed,max_walking_speed) ;
										self.walking_speed <- 0.025 °m/°s;
									} else if age = 4 {
										self.walking_speed <- 0.025 °m/°s;
									} else if age = 5 {
										self.walking_speed <- 0.0260 °m/°s;
									} else if age > 5 and age <60 {
										self.walking_speed <- rnd(0.0270,0.0280) °m/°s;
									} else if age >= 60 and age <= 75 {
										self.walking_speed <- rnd(0.0260,0.0260) °m/°s;
									} else if age >= 70 {
										self.walking_speed <- 0.0250 °m/°s;
									}
									self.bike_speed <- rnd(0.15 #km / #h, 0.2 #km / #h);


								 	// set living place and location as in my_living_place
								 	//my_living_place <- shuffle(living_building) first_with (each.id = my_living_place_id);
								 	//location <- my_living_place.location;
								 	
									// manipulate today activity plan strings
									string temp <- today_activity_plan;
									temp <- replace(temp, "[","");
									temp <- replace(temp, "]","");
									temp <- replace(temp, "'","");
									temp <- replace(temp, "\\","");
									today_activity_plan <- temp split_with(",") as list<string>;
									
									
									
								 	// manipulate frequency strings
								 	string temp <- working_frequency;
								 	temp <- replace(temp, "[","");
								 	temp <- replace(temp, "]","");
								 	temp <- replace(temp, "'","");
								 	temp <- replace(temp, "\\","");
								 	working_frequency <- temp split_with(",") as list<int>;
								 	
							 		string temp <- shopping_frequency;
							 		temp <- replace(temp, "[","");
								 	temp <- replace(temp, "]","");
								 	temp <- replace(temp, "'","");
								 	temp <- replace(temp, "\\","");
								 	shopping_frequency <- temp split_with(",") as list<int>;
							 		
							 		string temp <- leisure_frequency;
							 		temp <- replace(temp, "[","");
								 	temp <- replace(temp, "]","");
								 	temp <- replace(temp, "'","");
								 	temp <- replace(temp, "\\","");
								 	leisure_frequency <- temp split_with(",") as list<int>;
								 	
								 	// working and leisure place defined from dataframe
									if	 my_working_place_id != "nil" {
												my_working_place <- shuffle(functional_buildings) first_with (each.id = my_working_place_id);
									}
									if	 my_leisure_place_id != "nil" {
									 		my_leisure_place <- shuffle(functional_buildings) first_with (each.id = my_leisure_place_id);
									}


									if	 my_exit_id != "nil" {
											my_exit <- shuffle(intersections) first_with (each.id = my_exit_id);
									}
								 	
							}
						}
		
		ask people {
			family_members_id <- people where (each.household = self.household);
			
		}
		///// attribution of an house to the households based on the house capacity
		list<people> temp_people <- people;
		ask temp_people {
		if my_living_place = nil {
				my_living_place <- shuffle(living_building) first_with ((each.block = self.block) and (each.n_households > 0));
			 	if my_living_place != nil {
			 		counter_1st_try <- counter_1st_try + 1;
			 		write "counter_1st_try: " + counter_1st_try;
			 		
			 	} else if my_living_place = nil {
			 		write Personal_ID + " could not find a living building with capacity > 0 and found " + my_living_place ;
			 		my_living_place <- shuffle(living_building) first_with (each.n_households > 0);
					counter_2nd_try <- counter_2nd_try + 1;
			 		write "counter_2nd_try: " + counter_2nd_try;
			 		 if my_living_place = nil {
			 		 	my_living_place <- first(shuffle(living_building));
			 		 	counter_3rd_try <- counter_3rd_try + 1;
			 			write "counter_3rd_try: " + counter_3rd_try;
			 		 }
			 	}
			 	write Personal_ID + " " + my_living_place ;
			 	ask my_living_place {
			 		self.n_households <- n_households - 1;
			 		myself.my_living_place_id <- self.id;
			 	}
			 	ask family_members_id {
			 				write "Agent: " + self.Personal_ID + " // " + self.household;
			 				self.my_living_place <- myself.my_living_place;
			 				self.my_living_place_id <- myself.my_living_place_id;
			 		}
			}
			remove self from: temp_people;
			remove family_members_id from: temp_people;
			location <- my_living_place.location;
			// set shopping place as the shopping place of my living place aka the precalculated closest shop
			my_shopping_place <- functional_buildings where (each.is_shopping = true) closest_to(my_living_place);
			// under 18 get the closest kita / school as working place
			if age <= 5 {
				my_working_place <- educational_buildings where (each.is_kita = true) closest_to(my_living_place);
			} else if age >= 6 and age <= 18 {
				my_working_place <- educational_buildings where (each.is_school = true) closest_to(my_living_place);
			}
		}
		// create a list of car owners and use it to define the number of cars that must be created
		list<people> car_owner <- people where (each.has_car=true);

		// create a list of bike owners and use it to define the number of bike that must be created
		list<people> bike_owner <- people where (each.has_bike=true);
    			
		// calculate how many cars and bikes should be created
		int nb_bikes <- length(bike_owner);
		int nb_cars <- length(car_owner);

				
		///// CREATE THE CARS /////
		create car number: nb_cars {
			vehicle_length <- gauss(4.4#m,0.5#m);
			vehicle_width <- gauss(1.8#m,0.1#m);
			right_side_driving <- true;
			proba_lane_change_up <-  rnd(0.1, 1.0); // probability to change lane to a upper lane (left lane if right side driving) if necessary
			proba_lane_change_down <- rnd(0.5, 1.0); // probability to change lane to a lower lane (right lane if right side driving) if necessary
			security_distance_coeff <- 5 / 9 * 3.6 * rnd(1.5); // the coefficient for the computation of the the min distance between two drivers
			// (according to the vehicle speed - safety_distance =max(min_safety_distance, safety_distance_coeff * min(self.real_speed, other.real_speed) )
			proba_respect_priorities <- rnd(1.0, 1.0); // probability to respect priority (right or left) laws
			proba_respect_stops <- [1.0,1.0]; // probability to respect stop laws - first value for red stop, second for stop sign
			proba_block_node <- 0.0; // probability to block a node (do not let other driver cross the crossroad)
			proba_use_linked_road <- 0.1; // probability to change lane to a linked road lane if necessary
			max_acceleration <- 4 / 3.6 ; // maximum acceleration of the car for a cycle
			max_speed <- (rnd(35,50) °km / °h); // max speed of the car for a cycle
			min_security_distance <- 1.5 #m; // the minimal distance to another driver
			speed_coeff <- rnd(0.7, 1.0); // speed coefficient for the speed that the driver want to reach (according to the max speed of the road)
			owner <- first(shuffle(car_owner));
			
			ask owner {
				self.my_car <- myself;
			}
			
			remove self.owner from: car_owner;
			my_parking_place <- ((parking_areas where (each.available_parking_places >= 1) at_distance 500) closest_to owner.my_living_place.location);
			// optimized by looking at closed distance
	    	    if (my_parking_place = nil) { // if nothing is available at closed distance than it looks all available cars
	    	    	my_parking_place <- parking_areas where (each.available_parking_places >= 1) closest_to owner.my_living_place.location;
	    	    }
			location <- any_location_in(my_parking_place);
			ask my_parking_place {
				self.available_parking_places <- self.available_parking_places - 1;
			}
		}
		
		///// CREATE THE BUS MANAGER FOR NORMAL BUSSES /////
		
		// The bus manager is an agent that have all departure times for a given line and create a bus at the given moment
		
// The bus manager is an agent that have all departure times for a given line and create a bus at the given moment
		//matrix bus_departures2;
		// import the data as a matrix
		//ask (DB_accessor) {
               //list<list> temp <- self.select(params:PARAMS, 
             //            select:"SELECT route_short_name, departure_hour, departure_minute FROM relevant_departure_times;");
          //      bus_departures <- matrix(transpose(matrix(temp[2])));
        //   }
		
		// default bus lines
		
		//convert the departure file into a matrix
		bus_departures <- matrix(departure_csv);
		//convert the departure file into a matrix
		loop i from: 0 to: bus_departures.rows -1 {
				add bus_departures[0,i] to: bus_departure_lines;
			}
		
		// create a unique list of the lines
		bus_departure_lines <- remove_duplicates(bus_departure_lines);
		
		// loop over the unique list of lines and create a manager agent for each line		
		loop i over: bus_departure_lines {
			create pt_manager number: 1 {
					bus_departure_lines <- i;
					if bus_departure_lines contains "bus" {
						pt_category <- "bus";
					} else {
						pt_category <- "tram";
					}	
				}
			}
				
		// each bus manager take only the departure hours and minutes corresponding to its line id
		ask pt_manager {
			loop i from: 0 to: bus_departures.rows -1 {
				if bus_departures[0,i] = bus_departure_lines {
					add bus_departures[1,i] to: list_bus_departure_hours;
					add bus_departures[2,i] to: list_bus_departure_minutes;
				}
			}
			string temp <- list_bus_departure_hours;
			temp <- replace(temp, "24", "0");
			list_bus_departure_hours <- temp split_with (',', false);
		}

		///// CREATE THE BUS MANAGER FOR CUSTOM BUSSES /////
		
		// The bus manager is an agent that have all departure times for a given line and create a bus at the given moment
		//convert the departure file into a matrix
		//ask (DB_accessor) {
               //list<list> temp <- self.select(params:PARAMS, 
             //            select:"SELECT route_short_name, departure_hour, departure_minute FROM relevant_departure_times;");
          //      bus_departures <- matrix(transpose(matrix(temp[2])));
        //   }
        
        if include_new_bus_line = true {
	        rdt_departure_csv <- csv_file("C:/Users/diego/python-workspace/drt_route_planning_app/apps/output/" + scenario_name + "_rdt_timetable.csv", ',', string, true);
			rdt_departures <- matrix(rdt_departure_csv);
			//convert the departure file into a matrix
			loop i from: 0 to: rdt_departures.rows -1 {
					add rdt_departures[0,i] to: rdt_departures_lines;
				}
			// create a unique list of the lines
			rdt_departures_lines <- remove_duplicates(rdt_departures_lines);
			// loop over the unique list of lines and create a manager agent for each line		
			loop i over: rdt_departures_lines {
				create rdt_manager number: 1 {
							rdt_departures_lines <- i;
						}
					}	
			// each bus manager take only the departure hours and minutes corresponding to its line id
				ask rdt_manager {
					loop i from: 0 to: rdt_departures.rows -1 {
						if rdt_departures[0,i] = rdt_departures_lines {
							add rdt_departures[1,i] to: rdt_departure_hours;
							add rdt_departures[2,i] to: rdt_departure_minutes;
						}
					}
				}
		}
		
		ask living_building  {
			do calc_dist_building;
		}	
		// calculate max distances
		max_dist_to_bus_stop <- living_building max_of(each.walk_dist_to_bus_stop);
		max_dist_to_tram_stop <- living_building max_of(each.walk_dist_to_tram_stop);
		max_dist_to_pt_stop <- living_building max_of(each.walk_dist_to_pt_stop);
		//max_dist_to_shopping <- living_building max_of(each.walk_dist_to_shopping_place);
		
		
		//////// CREATE BLOCKS ///////////
		string QUERY_blocks<- "SELECT blk_idz, bewohnt, ST_AsEWKB(geom) as geom FROM bornstedt_blk_31122020_epsg25833_v2;";
		
		ask DB_accessor {
			create blocks from: select(PARAMS, QUERY_blocks)
							 with:[ block::"blk_idz",
										bewohnt::"bewohnt",
							 			shape::"geom" ];
		 }
		
		//n_of_buildings_in_block <- length(living_building where (each.block = self.block)) + length(functional_building where (each.block = self.block)) + length(educational_building where (each.block = self.block));
		
		/// Calc block stats (if parameter block_stats set to true)
		if block_stats {
			ask blocks{
				living_places_in_block <- living_building where (each.block = self.block);
				functional_buildings_in_block <- functional_buildings where (each.block = self.block);
				kitas_in_block <-  educational_buildings where (each.block = self.block and each.is_kita = true);
				schools_in_block <-  educational_buildings where (each.block = self.block and each.is_school = true);
				n_of_living_places_in_block <- length(living_places_in_block);
				n_of_functional_buildings_in_block <- length(functional_buildings_in_block);
				n_of_schools_in_block <-  length(schools_in_block);
				n_of_kitas_in_block <- length(kitas_in_block);
				people_in_block <- people where (each.block = self.block);
				avg_walk_dist_to_bus_stop <- mean(living_places_in_block collect (each.walk_dist_to_bus_stop));
				avg_walk_dist_to_tram_stop <- mean(living_places_in_block collect (each.walk_dist_to_tram_stop));
				avg_walk_dist_to_kita <- mean(living_places_in_block collect (each.walk_dist_to_kita));
				avg_walk_dist_to_school <- mean(living_places_in_block collect (each.walk_dist_to_school));
				avg_walk_dist_to_pt_stop <- mean(living_places_in_block collect (each.walk_dist_to_pt_stop));
				household_categories_in_block <- (people_in_block collect (each.household_category));
				house_types_in_block <- (living_places_in_block collect (each.house_type));
			}	
		}
		
		
		// for the modal deicision module > define the distance category
		do rank_building_by_dist_to_pt;	
	}


	////////////////////////////
	/// GENERIC ACTIONS ///
	////////////////////////////
	
	/// action to attribute a closest_intersection to each building in order to spare computation during the simulation
	action set_closest_intersec_buildings {	
		ask living_building {
			closest_intersection_2_building <- pedestrian_network.vertices at_distance 50 closest_to self;
			if (closest_intersection_2_building = nil) {closest_intersection_2_building <- pedestrian_network.vertices closest_to self;}
		}
		ask functional_buildings {
			closest_intersection_2_building <- pedestrian_network.vertices at_distance 50 closest_to self;
			if (closest_intersection_2_building = nil) {closest_intersection_2_building <- pedestrian_network.vertices closest_to self;}
		}
		ask educational_buildings {
			closest_intersection_2_building <- pedestrian_network.vertices at_distance 50 closest_to self;
			if (closest_intersection_2_building = nil) {closest_intersection_2_building <- pedestrian_network.vertices closest_to self;}
		}

	}
	
	// to adapt for the discrete choice model
	action rank_building_by_dist_to_pt {
			ask living_building {
				if self.walk_dist_to_pt_stop > walking_to_bus_tollerance {
					self.dist_to_pt_category <- "Weit von ÖPNV";
				} else if self.walk_dist_to_pt_stop <= walking_to_bus_tollerance {
					self.dist_to_pt_category <- "Nah ÖPNV";
				}
			}
		}
	
	

	
	// a list of all bus stops is created and accessible from all other agents, furthermore each bus stop has a list of the bus lines passing through
	action set_intersections_for_pt {		
		
		tram_lines_crossing_station <- tram_stops(8);
		intersection_tram_lines_crossing_station <- intersections(39);
		
		// create a single list of bus stops that can be used by travel agents
		bus_stops <- remove_duplicates(
			bus609a_stops union bus609b_stops
			union bus612a_stops union bus612b_stops
			union bus614a_stops union bus614b_stops
			union bus638a_stops union bus638b_stops
			union bus650a_stops union bus650b_stops
			union bus692a_stops union bus692b_stops
			union bus697a_stops union bus697b_stops
			union bus698a_stops union bus698b_stops
			union new_busa_stops union new_busb_stops);
			
		// a list of bus and tram_stops
		pt_stops <- bus_stops union intersections_closest_to_tram_stops;
		
		// a list of pt stops that are used as exits  > info from qgis
		bus_exits <- [
			last(bus612b_stops),
			last(bus614b_stops),
			last(bus614a_stops),
			last(bus638b_stops),
			last(bus650b_stops),
			last(bus650a_stops),
			last(bus692b_stops),
			last(bus697b_stops)];
		// and the corresponding entries > info from qgis	
		bus_entries <- [
			first(bus612a_stops),
			first(bus614a_stops),
			first(bus614b_stops),
			first(bus638a_stops),
			first(bus650a_stops),
			first(bus650b_stops),
			first(bus692a_stops),
			first(bus698a_stops)];
		
			
		// define each intersection as bus_stop true or false
		ask intersections {
			if self in pt_stops {
				self.is_pt_stop <- true;
			} else {
				self.is_pt_stop <- false;
			}
		}
		
		ask pt_stops {
			if self.bus609a > 0 {
				add "bus_609a" to: self.lines_passing_through;	
			}
			if self.bus609b > 0 {
				add "bus_609b" to: self.lines_passing_through;	
			}
			if self.bus612a > 0 {
				add "bus_612a" to: self.lines_passing_through;	
			}
			if self.bus612b > 0 {
				add "bus_612b" to: self.lines_passing_through;	
			}
			if self.bus614a > 0 {
				add "bus_614a" to: self.lines_passing_through;	
			}
			if self.bus614b > 0 {
				add "bus_614b" to: self.lines_passing_through;	
			}
			if self.bus638a > 0 {
				add "bus_638a" to: self.lines_passing_through;	
			}
			if self.bus638b > 0 {
				add "bus_638b" to: self.lines_passing_through;	
			}
			if self.bus650a > 0 {
				add "bus_650a" to: self.lines_passing_through;	
			}
			if self.bus650b > 0 {
				add "bus_650b" to: self.lines_passing_through;	
			}
			if self.bus692a > 0 {
				add "bus_692a" to: self.lines_passing_through;	
			}
			if self.bus692b > 0 {
				add "bus_692b" to: self.lines_passing_through;	
			}
			if self.bus697a > 0 {
				add "bus_697a" to: self.lines_passing_through;	
			}
			if self.bus697b > 0 {
				add "bus_697b" to: self.lines_passing_through;	
			}
			if self.bus698a > 0 {
				add "bus_698a" to: self.lines_passing_through;	
			}
			if self.bus698b > 0 {
				add "bus_698b" to: self.lines_passing_through;	
			}
			if self.new_bus_line > 0 {
				add "new_bus_line" to: self.lines_passing_through;	
			}
			if self.tram92a > 0 {
				add "tram_92a" to: self.lines_passing_through;	
			}
			if self.tram92b > 0 {
				add "tram_92b" to: self.lines_passing_through;	
			}
			if self.tram96a > 0 {
				add "tram_96a" to: self.lines_passing_through;	
			}
			if self.tram96b > 0 {
				add "tram_96b" to: self.lines_passing_through;	
			}
			if self.new_bus_line > 0 {
				add "new_bus_line" to: self.lines_passing_through;	
			}
		}
		
		// create a map to quickly access bus stops using the line as a key
		bus_lines_map <- create_map(["609a","609b","612a","612b","614a","614b","638a","638b","650a","650b","692a","692b","697a","697b","698a","698b","new_busa","new_busb"],
			[bus609a_stops,bus609b_stops,bus612a_stops,bus612b_stops,bus614a_stops,bus614b_stops,bus638a_stops,bus638b_stops,bus650a_stops,bus650b_stops,bus692a_stops,bus692b_stops,bus697a_stops,bus697b_stops,bus698a_stops,bus698b_stops,new_busa_stops,new_busb_stops]
		); 
	}
	
	// a list of entry and exit doors is created and accessible from other agents
	action set_entry_exit_doors {
		// create a list of the possible commuters_doors (to be adjusted as soon as there are many exits)
		commuters_doors_entry <- intersections where (each.is_entry);
		commuters_doors_exit <- intersections where (each.is_exit);
		
		commuters_doors_exit_for_cars <- intersections where (each.is_exit and each.has_motor_vehicles_allowed_one_of = true);
		
		// 1st calculate for all doors
		// adjust the data abouts exits for the cases that no data are available		
		ask commuters_doors_exit where (each.exits = 0) {
			self.exits <- rnd(0,commuters_doors_entry where (each.exits > 0) min_of(each.exits));
		}
		// calculate the sum in order to calc probabilities
		int sum_exits <- commuters_doors_exit sum_of(each.exits);
		// create a map with the intersections and probability
		commuters_doors_exit_map <- commuters_doors_exit as_map (each::((each.exits / sum_exits)));
		
		// 2nd calculate for all doors suitable for cars
		// adjust the data abouts exits for the cases that no data are available		
		ask commuters_doors_exit_for_cars where (each.exits = 0) {
			self.exits <- rnd(0,commuters_doors_exit_for_cars where (each.exits > 0) min_of(each.exits));
		}
		// calculate the sum in order to calc probabilities
		int sum_exits_car <- commuters_doors_exit_for_cars sum_of(each.exits);
		// create a map with the intersections and probability
		commuters_doors_exit_for_cars_map <- commuters_doors_exit_for_cars as_map (each::((each.exits / sum_exits)));
	}
}

	///////////////////////////
	// Definition of species //
	///////////////////////////

	//-----------//
	// VEHICLES //
	//-----------//

species DB_accessor skills: [SQLSKILL] {
		reflex save_modal_data  when: (cycle + 1) mod 300 = 0 {  // save data into Postgres
				do insert (params: PARAMS, into: "results_" + scenario_name + "_modal_split" , 
               columns: ["cycle", "working_car", "working_bike", "working_pt", "working_pedestrian", 
               	"shopping_car", "shopping_bike", "shopping_pt", "shopping_pedestrian",
               	"leisure_car", "leisure_bike", "leisure_pt", "leisure_pedestrian",
               	"school_car", "school_bike", "school_pt", "school_pedestrian"], 
               values: [cycle, working_car, working_bike, working_pt, working_pedestrian,
               	shopping_car, shopping_bike, shopping_pt, shopping_pedestrian,
               	leisure_car, leisure_bike, leisure_pt, leisure_pedestrian,
               	school_car, school_bike, school_pt, school_pedestrian]);		    	
		}
}
	
// define cars variables and behavior
species car skills: [advanced_driving] control: fsm {
	rgb color <- #orange ;
	rgb color_passengers <- #darkred;
    intersections car_target <- nil ;
    int passengers_on_board <- 0;
    people owner <- nil;
    bool is_outside <- false;
	parking_areas my_parking_place;
	bool is_commuter_car <- false;
	bool is_leaving_the_area <- false;
	float vehicle_width;
	float waiting_time_stop <- 3 #seconds;
	
	state stand_by initial: true{
		if is_outside = true and !empty(members) {
			color <- #transparent;
			release members as: people  { // passengers are released as people when the car is less than 30-45 nt away from goal
				myself.passengers_on_board <- myself.passengers_on_board - 1; // increase car_passengers_on_boardy
					myself.is_outside <- true;
					state <- "stand_by";
					self.location <- myself.location;
					self.color <- #purple;
			}
		} else if is_outside = false and color != #orange  {
			color <- #orange ;
		}
	}
	
	state driving initial: false{
		ask my_parking_place {
			self.available_parking_places <- self.available_parking_places + 1;
		}
		do drive;
		
		// the road Graf-von-Schwerin-Straße makes problem
		if current_road != nil {
			if (current_road.name = "Graf-von-Schwerin-Straße" or current_road = road(2668) or current_road = road(4829) or current_road = road(5246)) and real_speed = 0.0{
				location <- intersections(31).location;
				current_path <- compute_path(graph: road_network, target: self.car_target);	
			}
		}
		
		transition to: parking when: !empty(targets) and final_target = nil and is_leaving_the_area = false {
			if (current_road != nil) {
				ask road(current_road) {
					do unregister(myself);
				}
			}
			ask car_target {
				myself.my_parking_place <- parking_areas where (each.available_parking_places >= 1) at_distance 200 closest_to (self) ; // select the parking place
				if myself.my_parking_place = nil {
						myself.my_parking_place <- parking_areas where (each.available_parking_places >= 1) closest_to (self) ; // select the parking place
				}
			}
		}
		
		transition to: stand_by when: !empty(targets) and final_target = nil and is_leaving_the_area = true {
			if (current_road != nil) {
				ask road(current_road) {
					do unregister(myself);
				}
			}
			is_outside <- true;	
		}
	}
	
	state parking initial: false{
		self.location <- any_location_in(my_parking_place);
		release members as: people  { // passengers are released as people when the car is less than 30-45 nt away from goal
				myself.passengers_on_board <- myself.passengers_on_board - 1; // increase car_passengers_on_boardy
				if ((will_drive_out = true) and (my_exit = myself.car_target)) {
					the_target <- nil;
					myself.is_outside <- true;
					state <- "stand_by";
				} else {
					ask building_target {
						myself.the_target <- self.closest_intersection_2_building;
					}
					//the_target <- building_target;
					state <- "get_off_and_walk";
				}
				self.location <- myself.location;
			}
			car_target <- nil;
			current_path <- nil;
			current_road <- nil;
			current_target <- nil;
			targets <- [];
		
		transition to:stand_by {}
	}
    
	// define cars_passengers as subspecies of people
	species car_passengers  parent: people schedules: [];
	
	point calcul_loc {
			float val <- (road(current_road).lanes - current_lane) + 0.5;
			val <- on_linked_road ? val * - 1 : val;
			if (val = 0) {
				return location; 
			} else {
				return (location + {cos(heading + 90) * val, sin(heading + 90) * val});
			}
		}
   
   reflex time_in_vehicle_counter when: length(self.car_passengers) > 0 {
    	ask self.car_passengers {
    		time_in_vehicle <- time_in_vehicle + 1;
    	}
    }

	aspect base {
			if (! is_outside) {
				if  empty(car_passengers) {
						point loc <- calcul_loc();
						draw rectangle(vehicle_length, vehicle_width) at: loc rotate:  heading color: color;
				} else {
						point loc <- calcul_loc();
						draw rectangle(vehicle_length, vehicle_width) at: loc rotate:  heading color: color_passengers;
						}
				} else {
						draw rectangle(1,1) color: #blue;
				}
			}			
}

// bus managers is used to create busses only on the given time, the bus managers have far less data and store stats for lines
species pt_manager {
	string bus_departure_lines;
	string pt_category;
	list<int> list_bus_departure_hours;
	list<int> list_bus_departure_minutes;
	
	// Reflex to create busses at the right time
	reflex initiate_bus when: (pt_category = "bus") and // if it is a bus shpuld contain a or b, else it is a tram
		(list_bus_departure_hours contains current_date.hour) and // check if it is departure hour
		(list_bus_departure_minutes contains current_date.minute) and // check if it is departure minute
		(current_date.second = 0) { // check if the bus for the current minute is already been created
		list temp <- list_bus_departure_hours all_indexes_of current_date.hour; // create a list of the indexes of the current minute
		loop i over: temp { // loop over the list
			if list_bus_departure_minutes at i = current_date.minute { // check if at the given indexes the hour also correspond to the current hour
			create bus number: 1 {
				self.line_id <- myself.bus_departure_lines; // if true, a bus of the corresponding line is created
				vehicle_length <- 16 #m;
				vehicle_width <- 5 #m;
				right_side_driving <- true;
				proba_lane_change_up <-  rnd(0.1, 1.0); // probability to change lane to a upper lane (left lane if right side driving) if necessary
				proba_lane_change_down <- rnd(0.5, 1.0); // probability to change lane to a lower lane (right lane if right side driving) if necessary
				security_distance_coeff <- 5 / 9 * 3.6 * rnd(1.5); // the coefficient for the computation of the the min distance between two drivers
				// (according to the vehicle speed - safety_distance =max(min_safety_distance, safety_distance_coeff * min(self.real_speed, other.real_speed) )
				proba_respect_priorities <- rnd(1.0, 1.0); // probability to respect priority (right or left) laws
				proba_respect_stops <- [1.0,1.0]; // probability to respect stop laws - first value for red stop, second for stop sign
				proba_block_node <- 0.0; // probability to block a node (do not let other driver cross the crossroad)
				proba_use_linked_road <- 0.1; // probability to change lane to a linked road lane if necessary
				max_acceleration <- 4 / 3.6 ; // maximum acceleration of the car for a cycle
				max_speed <- (rnd(25,35) °km / °h); // max speed of the car for a cycle
				min_security_distance <- 1.5 #m; // the minimal distance to another driver
				speed_coeff <- rnd(0.6, 0.8); // speed coefficient for the speed that the driver want to reach (according to the max speed of the road)
				n_of_passengers_on_board <- gauss(20,5); // it must be adjusted as soon as data are available
				stop_counter <- 0;
				route_planned <- false;		
				
				if self.line_id = "bus_609a"{ 
					location <- first(bus609a_stops).location;
					self.my_route_outward <- copy(bus609a_stops);
					self.my_graph <- bus609_network;
				} else if self.line_id = "bus_609b"{
					location <- first(bus609b_stops).location;
					self.my_route_outward <- copy(bus609b_stops);
					self.my_graph <- bus609_network;
				} else if self.line_id = "bus_612a"{
					location <- first(bus612a_stops).location;
					self.my_route_outward <- copy(bus612a_stops);
					self.my_graph <- bus612_network;
				} else if self.line_id = "bus_612b"{
					location <- first(bus612b_stops).location;
					self.my_route_outward <- copy(bus612b_stops);
					self.my_graph <- bus612_network;
				} else if self.line_id = "bus_614a"{
					location <- first(bus614a_stops).location;
					self.my_route_outward <- copy(bus614a_stops);
					self.my_graph <- bus614_network;
				} else if self.line_id = "bus_614b"{
					location <- first(bus614b_stops).location;
					self.my_route_outward <- copy(bus614b_stops);
					self.my_graph <- bus614_network;
				} else if self.line_id = "bus_638a"{
					location <- first(bus638a_stops).location;
					self.my_route_outward <- copy(bus638a_stops);
					self.my_graph <- bus638_network;
				} else if self.line_id = "bus_638b"{
					location <- first(bus638b_stops).location;
					self.my_route_outward <- copy(bus638b_stops);
					self.my_graph <- bus638_network;
				} else if self.line_id = "bus_650a"{
					location <- first(bus650a_stops).location;
					self.my_route_outward <- copy(bus650a_stops);
					self.my_graph <- bus650_network;
				} else if self.line_id = "bus_650b"{
					location <- first(bus650b_stops).location;
					self.my_route_outward <- copy(bus650b_stops);
					self.my_graph <- bus650_network;
					route_planned <- true;
				} else if self.line_id = "bus_692a"{
					location <- first(bus692a_stops).location;
					self.my_route_outward <- copy(bus692a_stops);
					self.my_graph <- bus692_network;
				} else if self.line_id = "bus_692b"{
					location <- first(bus692b_stops).location;
					self.my_route_outward <- copy(bus692b_stops);
					self.my_graph <- bus692_network;
				} else if self.line_id = "bus_697a"{
					location <- first(bus697a_stops).location;
					self.my_route_outward <- copy(bus697a_stops);
					self.my_graph <- bus697_network;
				} else if self.line_id = "bus_697b"{
					location <- first(bus697b_stops).location;
					self.my_route_outward <- copy(bus697b_stops);
					self.my_graph <- road_network; // exception - otherwise on bus697_network is not able to drive for some reasons
				} else if self.line_id = "bus_698a"{
					location <- first(bus698a_stops).location;
					self.my_route_outward <- copy(bus698a_stops);
					self.my_graph <- bus698_network;
				} else if self.line_id = "bus_698b"{
					location <- first(bus698b_stops).location;
					self.my_route_outward <- copy(bus698b_stops);
					self.my_graph <- bus698_network;
				}
			}
			}
		}
		if length(list_bus_departure_hours) = 0 and length(list_bus_departure_minutes) = 0 {
			do die;
		}
	} 
	
	
	// Reflex to create busses at the right time
	reflex initiate_tram when: (pt_category = "tram") and // if it is a tram
		(list_bus_departure_hours contains current_date.hour) and // check if it is departure hour
		(list_bus_departure_minutes contains current_date.minute) and // check if it is departure minute
		(current_date.second = 0) { // check if the bus for the current minute is already been created
		list temp <- list_bus_departure_hours all_indexes_of current_date.hour; // create a list of the indexes of the current minute
		loop i over: temp { // loop over the list
			if list_bus_departure_minutes at i = current_date.minute { // check if at the given indexes the hour also correspond to the current hour
			create tram number: 1 { 
				self.line_id <- myself.bus_departure_lines; // if true, a bus of the corresponding line is created
				n_of_passengers_on_board <- gauss(20,5); // it must be adjusted as soon as data are available
				stop_counter <- 0;
				route_planned <- false;
				if self.line_id = "tram_92a"{
					location <- first(tram92a_stops).location;
					self.my_route <- copy(tram92a_stops);
					// since the tram route and stops are not inside the normal network, a mirroring list of the intersections related to each tram stop is created
					self.my_route_for_pedestrian <- copy(intersections_closest_to_tram_stops_92);
					self.my_graph <- tram92_network;
				}	else if self.line_id = "tram_92b"{
					location <- first(tram92b_stops).location;
					self.my_route <- copy(tram92b_stops);
					// since the tram route and stops are not inside the normal network, a mirroring list of the intersections related to each tram stop is created
					self.my_route_for_pedestrian <- copy(reverse(intersections_closest_to_tram_stops_92));
					self.my_graph <- tram92_network;
				}  else if self.line_id = "tram_96a"{
					location <- first(tram96a_stops).location;
					self.my_route <- copy(tram96a_stops);
					// since the tram route and stops are not inside the normal network, a mirroring list of the intersections related to each tram stop is created
					self.my_route_for_pedestrian <- copy(intersections_closest_to_tram_stops_96);
					self.my_graph <- tram96_network;
				} if self.line_id = "tram_96b"{
					location <- first(tram96b_stops).location;
					self.my_route <- copy(tram96b_stops);
					// since the tram route and stops are not inside the normal network, a mirroring list of the intersections related to each tram stop is created
					self.my_route_for_pedestrian <- copy(reverse(intersections_closest_to_tram_stops_96));
					self.my_graph <- tram96_network;
				}
				route_planned <- true;
			}
		}
	}
	if length(list_bus_departure_hours) = 0 and length(list_bus_departure_minutes) = 0 {
		do die;
	}
	}
	
	aspect base {
	
	}
}

// bus managers is used to create busses only on the given time, the bus managers have far less data and store stats for lines
species rdt_manager {
	string rdt_departures_lines;
	list<int> rdt_departure_hours;
	list<int> rdt_departure_minutes;
	
	// Reflex to create busses at the right time
	reflex initiate_bus when:
		(rdt_departure_hours contains current_date.hour) and // check if it is departure hour
		(rdt_departure_minutes contains current_date.minute) and // check if it is departure minute
		(current_date.second = 0) { // check if the bus for the current minute is already been created
		list temp <- rdt_departure_hours all_indexes_of current_date.hour; // create a list of the indexes of the current minute
		loop i over: temp { // loop over the list
			if rdt_departure_minutes at i = current_date.minute { // check if at the given indexes the hour also correspond to the current hour
			create rdt_bus number: 1 {
				self.line_id <- myself.rdt_departures_lines; // if true, a bus of the corresponding line is created
				if self.line_id = "new_bus_a"{ 
					location <- first(new_busa_stops).location;
					self.my_route_outward <- copy(new_busa_stops);
				} else if self.line_id = "new_bus_b"{
					location <- first(new_busb_stops).location;
					self.my_route_outward <- copy(new_busb_stops);
				}
				vehicle_length <- 16 #m;
				vehicle_width <- 5 #m;
				right_side_driving <- true;
				proba_lane_change_up <-  rnd(0.1, 1.0); // probability to change lane to a upper lane (left lane if right side driving) if necessary
				proba_lane_change_down <- rnd(0.5, 1.0); // probability to change lane to a lower lane (right lane if right side driving) if necessary
				security_distance_coeff <- 5 / 9 * 3.6 * rnd(1.5); // the coefficient for the computation of the the min distance between two drivers
				// (according to the vehicle speed - safety_distance =max(min_safety_distance, safety_distance_coeff * min(self.real_speed, other.real_speed) )
				proba_respect_priorities <- rnd(1.0, 1.0); // probability to respect priority (right or left) laws
				proba_respect_stops <- [1.0,1.0]; // probability to respect stop laws - first value for red stop, second for stop sign
				proba_block_node <- 0.0; // probability to block a node (do not let other driver cross the crossroad)
				proba_use_linked_road <- 0.1; // probability to change lane to a linked road lane if necessary
				max_acceleration <- 4 / 3.6 ; // maximum acceleration of the car for a cycle
				max_speed <- (rnd(25,35) °km / °h); // max speed of the car for a cycle
				min_security_distance <- 1.5 #m; // the minimal distance to another driver
				speed_coeff <- rnd(0.3, 0.5); // speed coefficient for the speed that the driver want to reach (according to the max speed of the road)
				n_of_passengers_on_board <- gauss(20,5); // it must be adjusted as soon as data are available
				stop_counter <- 0;
				route_planned <- false;
				start_trip_time <- current_date;
				
				}
			}
		}
	if length(rdt_departure_hours) = 0 and length(rdt_departure_minutes) = 0 {
		do die;
	}
	} 

	aspect base {
	
	}
}

// define busses variables and behavior
species rdt_bus skills: [advanced_driving] frequency: 1 control: fsm {
	
	// vehicle related
	int counter_stucked <- 0;
	int threshold_stucked;
	int vehicle_width;
	string line_id;
	rgb color <- #green ;
	bool is_outside <- false;
	list<intersections> my_route_outward;
	list<intersections> my_route_backward;
	intersections bus_target;
	intersections on_hold_stop;
	intersections on_hold_get_off;
	people calling_agent;
	rdt_bus_passengers agent_to_be_dropped;
	int stop_counter <-  gauss(25,5) / step;
	float counter <- 0.0;
	float waiting_time_stop <- 3 #seconds;
	bool route_planned;
	map<people, geometry> to_be_picked_up;
	int pick_up_counter;
	int door_delivery_counter;
	int trip_duration;
	date start_trip_time <- nil;
	date end_trip_time <- nil;
	list<int> pick_up_calls_times;
	list<int> door_delivery_times;
	date start_pick_up_time <- nil;
	date end_pick_up_time <- nil;
	date start_door_delivery_time <- nil;
	date end_door_delivery_time <- nil;
	map<intersections, int> passengers_by_stop;
	list<people> passengers_getting_on update:
		(people) where ((each.at_bus_stop = true) and // 1st condition > people are at the bus stop
		(each.my_get_on_stop = self.bus_target) and // 2nd condition > people are at the bus stop
		((self.my_route_outward contains (each.my_get_off_stop)) or (each.my_get_off_stop = nil))); 
		// 3rd condition > the bus drive through the desired get off bus stop
	list<rdt_bus_passengers> passengers_getting_off update: (rdt_bus_passengers) where (each.my_get_off_stop = self.bus_target);
	list<path> path_list;
	bool driving;
	bool arrived <- false;
	// stats
    int n_of_passengers_on_board;

	state on_call initial: false{
		if start_pick_up_time = nil {
			start_pick_up_time <- current_date;
		}
		// first agent to be picked up
		calling_agent <- first(self.to_be_picked_up.keys);
		remove first(self.to_be_picked_up.keys) from: self.to_be_picked_up.keys;
		bus_target <- first(self.to_be_picked_up.values);
		remove first(self.to_be_picked_up.values) from: self.to_be_picked_up.values;		
		current_path <- compute_path(graph: road_network, target: self.bus_target);
		
		transition to: driving {}
	}
	
	state resume_route initial: false{
		bus_target <- on_hold_stop;
		on_hold_stop <- nil;

		if calling_agent.my_get_off_stop = nil {
			// if the bus is still driving though switching stations
				if my_route_outward contains_any rdt2tram_switching_stations {
				write "Agent: " + calling_agent.Personal_ID + " is using the rdt to reach the tram to leave the area and using the pick up function";
				// it looks if the upcoming stops are in the list tram_switching_stations
				loop x over: my_route_outward {
					if rdt2tram_switching_stations contains x {
						// if yes, than this is my get off stop
						calling_agent.my_get_off_stop <- x;
						capture calling_agent as:rdt_bus_passengers;
						break;
					}
				}
		// for the case that the agent is using the rdt bus to leave the area and want to switch to the bus
			} else if my_route_outward contains_any rdt2bus_switching_stations {
				write "Agent: " + calling_agent.Personal_ID + " is using the rdt to reach the tram to leave the area and using the pick up function";
				// it looks if the upcoming stops are in the list bus_switching_stations
				loop x over: my_route_outward {
					if rdt2bus_switching_stations contains x {
						// if yes, than this is my get off stop
						calling_agent.my_get_off_stop <- x;
						capture calling_agent as:rdt_bus_passengers;
						break;
					}
				}
			}
		} else if calling_agent.my_get_off_stop != nil {
			capture calling_agent as:rdt_bus_passengers;
		}
		end_pick_up_time <- current_date;
		add milliseconds_between(start_pick_up_time, end_pick_up_time) / 1000 to: pick_up_calls_times;
		pick_up_counter <- pick_up_counter + 1;
		start_pick_up_time <- nil;
		end_pick_up_time <- nil;		
		current_path <- compute_path(graph: road_network, target: self.bus_target);
		transition to: driving {
		}
	}
	
	state drop_single_agent initial: false {
			// release agents that are driven directly to the door of their destination
			release agent_to_be_dropped as:people {
				self.location <- any_location_in(self.building_target);
				self.state <- "stand_by";
				self.n_of_vehicle_switch <- n_of_vehicle_switch + 1;
				self.at_bus_stop <- false;
			}
			agent_to_be_dropped <- nil;
			end_door_delivery_time <- current_date;
			add milliseconds_between(start_door_delivery_time, end_door_delivery_time) / 1000 to: door_delivery_times;
			door_delivery_counter <- door_delivery_counter + 1;
			start_door_delivery_time <- nil;
			end_door_delivery_time <- nil;
			
		transition to: calculate_route {
		}
			
	}

	state calculate_route initial:true {
		// if there are still some stops to go on the outward journey
		if !(empty(my_route_outward)) {
			// the bus target is defined as the next stop
			bus_target <- first(self.my_route_outward);
			// the list of passengers supposed to get off at the next stop is defined
			passengers_getting_off<- rdt_bus_passengers where (each.my_get_off_stop = self.bus_target);
			// check if some agents should be delivered at the door
			if !(empty(passengers_getting_off)) {
				// if there are some passengers on board that have rigth to be driven until their destination
				agent_to_be_dropped <- first(passengers_getting_off where ((each.rdt_pick_up_candidate = true) and
					(each.will_drive_out = false) and
					(!(rdt2tram_switching_stations contains each.my_get_off_stop) or !(rdt2bus_switching_stations contains each.my_get_off_stop))));
				// the bus target is defined as the building target of the agent to be dropped
				if agent_to_be_dropped != nil {
					start_door_delivery_time <- current_date;
					ask agent_to_be_dropped {
						intersections temp;
						ask building_target {
							temp <- self.closest_intersection_2_building;
						write "Debug: " + temp;
						}
						bus_target <- temp;
						write "Debug: " + bus_target;
					}
					write "Agent: " + agent_to_be_dropped.Personal_ID + " should be dropped at the door by " + bus_target;
					// if not the bus_target is not changed and removed from the list
				} else {
					remove first(self.my_route_outward) from: self.my_route_outward;
				}
				// if not the bus_target is not changed and removed from the list (two times - since the first case is "there are agents but have not door delivery rigth", the second case is "there are agents and have door delivery rigth"
			} else {
					remove first(self.my_route_outward) from: self.my_route_outward;
			}
		// if there are no more stops to go on the outward journey, the stop of the backward journey are progressively selected
		} else if empty(my_route_outward) and !(empty(my_route_backward)) and agent_to_be_dropped = nil {
			bus_target <- first(self.my_route_backward);
			remove first(self.my_route_backward) from: self.my_route_backward;
		// if both route are done
		} else if empty(my_route_outward) and empty(my_route_backward) and agent_to_be_dropped = nil {
			// if someone is still on the bus, throw him/her out
			if !(empty(passengers_getting_off)) {
				n_of_passengers_on_board <- n_of_passengers_on_board - length(passengers_getting_off);
				release passengers_getting_off as: people {
					rdt_passenger <- true;
					driving_back <- false;
					self.at_bus_stop <- false;
					self.location <- myself.location;
					self.n_of_vehicle_switch <- n_of_vehicle_switch + 1;
					// permit multimodal switch to bus
					if (self.will_drive_out = true) and (self.my_exit != self.my_get_off_stop) {
						do switch_to_tram;
					} else if (self.will_drive_out = true) and (self.my_exit =  self.my_get_off_stop) {
						the_target <- nil;
						state <- "stand_by";
					} else if will_drive_out = false {
						the_target <- building_target;
						//the_target <- building_target;
						state <- "get_off_and_walk";
					}
				}
			}
			end_trip_time <- current_date;
			trip_duration <- milliseconds_between(start_trip_time, end_trip_time) / 1000;
			write "Rdt bus: " + self + " the route took " + trip_duration;
			ask DB_accessor {
				do insert (params: PARAMS, into: "results_" + scenario_name + "_rdt_data" , 
	               columns: ["start_trip_time", "trip_duration", "pick_up_calls_times", "door_delivery_times", "pick_up_counter",  "door_delivery_counter", "passengers_by_stop"], 
	               values: [myself.start_trip_time, myself.trip_duration, myself.pick_up_calls_times, myself.door_delivery_times, myself.pick_up_counter, myself.door_delivery_counter, myself.passengers_by_stop]);
			}
			do die;
		}
		current_path <- compute_path(graph: road_network, target: self.bus_target);
		//if current_path = nil {
			//do compute_path(graph: road_network, target: bus_target); // calculate the path to the target
			//if current_path = nil {
				//location <- (driving_intersections closest_to self).location;
				//current_path <- compute_path(graph: road_network, target: self.bus_target);
			//} 
			//if current_path = nil {
				//list<intersections> test <- (driving_intersections at_distance 500);
				//loop i over: test {
					//location <- i.location;
					//current_path <- compute_path(graph: road_network, target: self.bus_target);
					//if current_path != nil { break; }	
				//}
			//}
		//}

		transition to: driving {
		}
	}

	state driving initial:false {
		do drive;
		
		//function who determines what agents do when they arrive at an intersection (Source: Taillandier)
		float external_factor_impact(float remaining_time) {
			proba_respect_stops[1] <- 1.0;
			//define the current intersection as the target node of the current_road
			intersections current_intersection <- intersections(road(current_road).target_node);
			
			//if the current intersection is a stop, than it will wait until waiting_time_stop is over
			if (current_intersection.is_stop_sign) {
				//if the counter is equal or bigger than the waiting time
				if (counter >= waiting_time_stop) {
					counter <- 0.0;
					proba_respect_stops[1] <- 0.0;
				// if not, just wait and increase the counter
				} else {
					counter <- counter + step;
					
				}
			}
			return remaining_time; // the time that the car has to wait before advancing
		}
		
		// function to orientate car (Source:Taillandier)
		point calcul_loc {
			float val <- (road(current_road).lanes - current_lane) + 0.5;
			val <- on_linked_road ? val * - 1 : val;
			if (val = 0) {
				return location; 
			} else {
				return (location + {cos(heading + 90) * val, sin(heading + 90) * val});
			}
		}
		
		if current_road != nil {
			if (current_road.name = "Graf-von-Schwerin-Straße" or current_road = road(2668) or current_road = road(4829) or current_road = road(5246)) and real_speed = 0.0{
				//write "RDT Bus: " + self + "  stucked at: " + self.current_road;
				location <- intersections(31).location;
				current_path <- compute_path(graph: road_network, target: self.bus_target);	
			}
		}
		
		if real_speed = 0 and state = 'driving' and current_road != nil and current_path != nil {
			//write "RDT Bus: " + self + "  stucked at: " + self.current_road + " and wil try with some magic";
			list<road> test <- (driving_roads at_distance 100);
				loop i over: test {
					location <- i.location;
					current_path <- compute_path(graph: road_network, target: self.bus_target);
					if current_path != nil { break; }	
				}
		}
		
		transition to: passengers_get_on_off when: final_target = nil  and on_hold_stop = nil and agent_to_be_dropped = nil{	
		}
		
		transition to: on_call when: final_target = nil  and on_hold_stop != nil and length(to_be_picked_up.keys) > 0 {	
		}
		
		transition to: drop_single_agent when: final_target = nil  and agent_to_be_dropped != nil {	
		}
		
		transition to: resume_route when: final_target = nil  and on_hold_stop != nil and length(to_be_picked_up.keys) = 0 {	
		}
	}
	
	state passengers_get_on_off initial:false {
		
		color <- #darkorange;
		// in order to avoid to get stucked by the roads
		if (current_road != nil) {
			ask road(current_road) {
				do unregister(myself);
			}	
		}
		// people getting off
		if !(empty(passengers_getting_off)) {
			n_of_passengers_on_board <- n_of_passengers_on_board - length(passengers_getting_off);
			release passengers_getting_off as: people {
				rdt_passenger <- true;
				driving_back <- false;
				self.at_bus_stop <- false;
				self.location <- myself.location;
				self.n_of_vehicle_switch <- n_of_vehicle_switch + 1;
				// permit multimodal switch to bus
				if (self.will_drive_out = true) and (self.my_exit != self.my_get_off_stop) {
					do switch_to_tram;
				} else if (self.will_drive_out = true) and (self.my_exit =  self.my_get_off_stop) {
					the_target <- nil;
					state <- "stand_by";
				} else if will_drive_out = false {
					the_target <- building_target;
					//the_target <- building_target;
					state <- "get_off_and_walk";
				}
			}
		}
		// people getting on only if the bus has still more than one stop (since it makes no sense to get on at the last stop).
		// before !(empty(passengers_getting_on)) and (length(my_route_outward) > 1 or length(my_route_backward) > 1)
		// probably it makes more sense with >=
		if !(empty(passengers_getting_on)) {
			n_of_passengers_on_board <- n_of_passengers_on_board + length(passengers_getting_on);
			
			//////////////////////////////////
			/// it must be changed, it must get on only if the stop is on the route, hence if it is able to have a my_get_off_stop
			//////////////////////////////////
			loop i over: passengers_getting_on {
				if i.my_get_off_stop = nil {
					// if the bus is still driving though switching stations
						if my_route_outward contains_any rdt2tram_switching_stations {
						write "Agent: " + i.Personal_ID + " is using the rdt to reach the tram to leave the area";
						// it looks if the upcoming stops are in the list tram_switching_stations
						loop x over: my_route_outward {
							if rdt2tram_switching_stations contains x {
								// if yes, than this is my get off stop
								i.my_get_off_stop <- x;
								capture i as:rdt_bus_passengers;
								break;
							}
						}
				// for the case that the agent is using the rdt bus to leave the area and want to switch to the bus
					} else if my_route_outward contains_any rdt2bus_switching_stations {
						write "Agent: " + i.Personal_ID + " is using the rdt to reach the tram to leave the area";
						// it looks if the upcoming stops are in the list bus_switching_stations
						loop x over: my_route_outward {
							if rdt2bus_switching_stations contains x {
								// if yes, than this is my get off stop
								i.my_get_off_stop <- x;
								capture i as:rdt_bus_passengers;
								break;
							}
						}
					}
				} else if i.my_get_off_stop != nil {
					capture i as:rdt_bus_passengers;
				}
			}			
		}
		write "RDT Bus " + self + " at stop " + bus_target + " with " + length(rdt_bus_passengers) + " on board"; 
		add bus_target::length(rdt_bus_passengers) to: passengers_by_stop;
		// value are resetted
		bus_target <- nil;
		current_path <- nil;
		current_target <- nil;
		final_target <- nil;
		targets <- [];
		// new counter is defined			
		stop_counter <- gauss(25,5) / step; // right now set as a random start number around 10, what lead to circa 15 / 25 seconds stop
		
		transition to: wait_at_stop {}
	}
	
	state wait_at_stop initial:false {
		color <- #darkorange;
		stop_counter <- stop_counter - 1;
		
		transition to:calculate_route when: stop_counter < 0 {}
	}
	
	point calcul_loc {
			float val <- (road(current_road).lanes - current_lane) + 0.5;
			val <- on_linked_road ? val * - 1 : val;
			if (val = 0) {
				return location; 
			} else {
				return (location + {cos(heading + 90) * val, sin(heading + 90) * val});
			}
		}
    
    reflex time_in_vehicle_counter when: length(self.rdt_bus_passengers) > 0 {
    	ask self.rdt_bus_passengers {
    		if n_of_vehicle_switch = 0 {
    			time_in_vehicle <- time_in_vehicle + 1;
    		} else {
    			time_in_vehicle2 <- time_in_vehicle2 + 1;
    		}	
    	}
    }
    
	// define cars_passengers as subspecies of people
	species rdt_bus_passengers  parent: people schedules: [] {	
	}
	

	aspect base {
			draw rectangle(vehicle_length+100, vehicle_width+50) rotate: heading color: color;
		}			
}


// define trams variables and behavior
species tram skills: [moving] frequency: 1 control: fsm {
	
	string line_id;
	rgb color <- #lightblue ;
    float tram_speed <- 35.0 °km / °h;
    bool route_planned;
    list<tram_stops> my_route;
    list<intersections> my_route_for_pedestrian;
    graph my_graph; 
    int vehicle_length <- 16;
    int vehicle_width <- 2;
    int n_of_passengers_on_board; // it must be adjusted as soon as data are available
	int stop_counter <-  gauss(25,5) / step;
	tram_stops tram_target;
	intersections pedestrian_related_target;
	bool arrived <- false;
	path tram_path;
	list<people> passengers_getting_on update:
		(people) where ((each.at_bus_stop = true) and // 1st condition > people are at the tram stop
		((each.my_get_on_stop = self.pedestrian_related_target)) and // 2nd condition > people's get on tram stop if it is the tram pedestrian related target (it means, the next bus stop)
		(self.my_route_for_pedestrian contains (each.my_get_off_stop)));  // 3rd condition > the bus drive through the desired get off tram stop
	list<tram_passengers> passengers_getting_off update: (tram_passengers) where (each.my_get_off_stop = self.pedestrian_related_target);
    
    state calculate_route initial:true {
		color <- #yellow;
		// if there are still some stops to go on the outward journey
		if !(empty(my_route)) {
			tram_target <- first(self.my_route);
			pedestrian_related_target <- first(self.my_route_for_pedestrian);
			remove first(self.my_route) from: self.my_route;
			remove first(self.my_route_for_pedestrian) from: self.my_route_for_pedestrian;
		// if there are no more stops to go on the outward journey, the stop of the backward journey are progressively selected
		} else if empty(my_route) {
			color <- #transparent;
			arrived <- true;
			// if someone is still on the bus throw him/her out
			if !(empty(passengers_getting_off)) {
				n_of_passengers_on_board <- n_of_passengers_on_board - length(passengers_getting_off);
				release passengers_getting_off as: people {			
				self.at_bus_stop <- false;
				self.location <- myself.location;
				self.n_of_vehicle_switch <- n_of_vehicle_switch + 1;
				 if (self.will_drive_out = true) {
						the_target <- nil;
						is_outside <- true;
						state <- "stand_by";
					} else if will_drive_out = false {
						if switch_to_rdt = true {
							// in case my tram line has not a switching station with the rdt bus
							if my_get_off_stop = nil {
								ask building_target {
									myself.my_get_off_stop <- intersections_closest_to_tram_stops where (each.lines_passing_through contains_any myself.my_pt_line) closest_to self ;
								}
							}
							my_get_on_stop <- rdt2tram_switching_stations at_distance (1000) closest_to self;
							my_get_off_stop <- my_living_place.closest_bus_stop;
							// in case the agent need to change tram line to reach the rdt2tram switching station
							if my_get_on_stop = nil {
								my_get_on_stop <- intersections_closest_to_tram_stops at_distance (1000) closest_to self;
								my_get_off_stop <- first(tram2rdt_switching_stations);
							} else {
								switch_to_rdt <- false;
							}
							state <- "get_on";
						} else {
							ask building_target {
								myself.the_target <- self.closest_intersection_2_building;
							}
							//the_target <- building_target;
							state <- "get_off_and_walk";
						}
					}
				}
			}
			do die;
		}
		transition to: driving {
		}
	}

	state driving initial:false {
		do goto (target: tram_target, on: my_graph, speed: tram_speed);
		
		transition to: passengers_get_on_off when: self.location overlaps self.tram_target {
			
		}
	}
	
	state passengers_get_on_off initial:false {
		// value are resetted
			tram_target <- nil;
			// new counter is defined			
			stop_counter <- gauss(25,5) / step; // right now set as a random start number around 10, what lead to circa 15 / 25 seconds stop
			// people getting off
			if !(empty(passengers_getting_off)) {
				n_of_passengers_on_board <- n_of_passengers_on_board - length(passengers_getting_off);
				release passengers_getting_off as: people {			
				self.at_bus_stop <- false;
				self.location <- myself.location;
				self.n_of_vehicle_switch <- n_of_vehicle_switch + 1;
				 if (self.will_drive_out = true) {
						the_target <- nil;
						is_outside <- true;
						state <- "stand_by";
					} else if will_drive_out = false {
						if rdt_passenger = true and switch_to_rdt = true {
								// first it try to reach the rdt2tram switching station						
								my_get_on_stop <- rdt2tram_switching_stations at_distance (1000) closest_to self;
								my_get_off_stop <- my_living_place.closest_bus_stop;
								// in case the agent need to change tram line to reach the rdt2tram switching station
								if my_get_on_stop = nil {
									my_get_on_stop <- intersections_closest_to_tram_stops at_distance (1000) closest_to self;
									my_get_off_stop <- first(tram2rdt_switching_stations);
							} else {
								switch_to_rdt <- false;
							}
							state <- "get_on";
						} else {
							ask building_target {
								myself.the_target <- self.closest_intersection_2_building;
							}
							//the_target <- building_target;
							state <- "get_off_and_walk";
						}
					}
				}
			}
			
			// people getting on only if the tram has still more than one stop (since it makes no sense to get on at the last stop).		
			if !(empty(passengers_getting_on)) {
				n_of_passengers_on_board <- n_of_passengers_on_board + length(passengers_getting_on);
				capture passengers_getting_on as:tram_passengers  {					
					
				}
			}
		
		transition to: wait_at_stop {}
	}
	
	state wait_at_stop initial:false {
		color <- #darkblue;
		stop_counter <- stop_counter - 1;
		
		transition to:calculate_route when: stop_counter < 0 {}
	}
	   
	reflex time_in_vehicle_counter when: length(self.tram_passengers) > 0 {
    	ask self.tram_passengers {
    		if n_of_vehicle_switch = 0 {
    			time_in_vehicle <- time_in_vehicle + 1;
    		} else {
    			time_in_vehicle2 <- time_in_vehicle2 + 1;
    		}	
    	}
    } 
	  
	// define cars_passengers as subspecies of people
	species tram_passengers  parent: people schedules: [] {}

	aspect base {
				draw rectangle(vehicle_length+80, vehicle_width + 50) rotate: heading color: color;
			}	
}

// define busses variables and behavior
species bus skills: [advanced_driving] frequency: 1 control: fsm {
	
	// vehicle related
	int counter_stucked <- 0;
	int threshold_stucked;
	int vehicle_width;
	string line_id;
	rgb color <- #yellow ;
	bool is_outside <- false;
	list<intersections> my_route_outward;
	list<intersections> my_route_backward;
	graph my_graph;
	intersections bus_target;
	int stop_counter <-  gauss(25,5) / step;
	float counter <- 0.0;
	float waiting_time_stop <- 3 #seconds;
	bool route_planned;
	list<people> passengers_getting_on update:
		(people) where ((each.at_bus_stop = true) and // 1st condition > people are at the bus stop
		(each.my_get_on_stop = self.bus_target) and // 2nd condition > people's get on bus stop is the buus_target (it means, the next bus stop)
		((self.my_route_outward contains (each.my_get_off_stop)) or (self.my_route_backward contains (each.my_get_off_stop))));  // 3rd condition > the bus drive through the desired get off bus stop
	list<bus_passengers> passengers_getting_off update: (bus_passengers) where (each.my_get_off_stop = self.bus_target);
	list<path> path_list;
	bool driving;
	bool arrived <- false;
	// stats
    int n_of_passengers_on_board;


	state calculate_route initial:true {
		// if there are still some stops to go on the outward journey
		if !(empty(my_route_outward)) {
			bus_target <- first(self.my_route_outward);
			remove first(self.my_route_outward) from: self.my_route_outward;		
		// if there are no more stops to go on the outward journey, the stop of the backward journey are progressively selected
		} else if empty(my_route_outward) and !(empty(my_route_backward)) {
			bus_target <- first(self.my_route_backward);
			remove first(self.my_route_backward) from: self.my_route_backward;
		// if both route are done
		} else if empty(my_route_outward) and empty(my_route_backward) {
			// if someone is still on the bus, throw him/her out
			if !(empty(passengers_getting_off)) {
				n_of_passengers_on_board <- n_of_passengers_on_board - length(passengers_getting_off);
				release passengers_getting_off as: people {
					if bus_exits contains my_get_off_stop {
						is_outside <- true;
					}
					self.at_bus_stop <- false;
					self.location <- myself.location;
					self.n_of_vehicle_switch <- n_of_vehicle_switch + 1;
					// permit multimodal switch to bus
					if (self.will_drive_out = true) and (self.my_exit != self.my_get_off_stop) {
						do switch_to_tram;
					} else if (self.will_drive_out = true) and (self.my_exit =  self.my_get_off_stop) {
						the_target <- nil;
						state <- "stand_by";
					} else if will_drive_out = false {
						ask building_target {
							myself.the_target <- self.closest_intersection_2_building;
						}
						//the_target <- building_target;
						state <- "get_off_and_walk";
					}
				}
			}
			if (current_road != nil) {
				ask road(current_road) {
					do unregister(myself);
				}
			}
			do die;
		}
		current_path <- compute_path(graph: self.my_graph, target: self.bus_target, source: bus_stops closest_to self);
		transition to: driving {
		}
	}

	state driving initial:false {
		do drive;
		//function who determines what agents do when they arrive at an intersection (Source: Taillandier)
		float external_factor_impact(float remaining_time) {
			proba_respect_stops[1] <- 1.0;
			//define the current intersection as the target node of the current_road
			intersections current_intersection <- intersections(road(current_road).target_node);
			
			//if the current intersection is a stop, than it will wait until waiting_time_stop is over
			if (current_intersection.is_stop_sign) {
				//if the counter is equal or bigger than the waiting time
				if (counter >= waiting_time_stop) {
					counter <- 0.0;
					proba_respect_stops[1] <- 0.0;
				// if not, just wait and increase the counter
				} else {
					counter <- counter + step;
					
				}
			}
			return remaining_time; // the time that the car has to wait before advancing
		}
		
		point calcul_loc {
			float val <- (road(current_road).lanes - current_lane) + 0.5;
			val <- on_linked_road ? val * - 1 : val;
			if (val = 0) {
				return location; 
			} else {
				return (location + {cos(heading + 90) * val, sin(heading + 90) * val});
			}
		}
		
		transition to: passengers_get_on_off when: final_target = nil {
			
		}
	}
	
	state passengers_get_on_off initial:false {
		color <- #darkorange;
		// in order to avoid to get stucked by the roads
		if (current_road != nil) {
			ask road(current_road) {
				do unregister(myself);
			}	
		}
		// people getting off
		if !(empty(passengers_getting_off)) {
			n_of_passengers_on_board <- n_of_passengers_on_board - length(passengers_getting_off);
			release passengers_getting_off as: people {
				if bus_exits contains my_get_off_stop {
					is_outside <- true;
				}
				self.at_bus_stop <- false;
				self.location <- myself.location;
				self.n_of_vehicle_switch <- n_of_vehicle_switch + 1;
				// permit multimodal switch to bus
				if (self.will_drive_out = true) and (self.my_exit != self.my_get_off_stop) {
					do switch_to_tram;
				} else if (self.will_drive_out = true) and (self.my_exit =  self.my_get_off_stop) {
					the_target <- nil;
					state <- "stand_by";
				} else if will_drive_out = false {
					ask building_target{
						myself.the_target <- self.closest_intersection_2_building;
					}
					//the_target <- building_target;
					state <- "get_off_and_walk";
				}
			}
		}
		// people getting on only if the bus has still more than one stop (since it makes no sense to get on at the last stop).
		// before !(empty(passengers_getting_on)) and (length(my_route_outward) > 1 or length(my_route_backward) > 1)
		// probably it makes more sense with >=
		if !(empty(passengers_getting_on)) {
			n_of_passengers_on_board <- n_of_passengers_on_board + length(passengers_getting_on);
			capture passengers_getting_on as:bus_passengers {
			}
		}
		// value are resetted
		bus_target <- nil;
		current_path <- nil;
		current_target <- nil;
		final_target <- nil;
		targets <- [];
		// new counter is defined			
		stop_counter <- gauss(25,5) / step; // right now set as a random start number around 10, what lead to circa 15 / 25 seconds stop
		
		transition to: wait_at_stop {}
	}
	
	state wait_at_stop initial:false {
		color <- #darkorange;
		stop_counter <- stop_counter - 1;
		
		transition to:calculate_route when: stop_counter < 0 {}
	}
	
	point calcul_loc {
			float val <- (road(current_road).lanes - current_lane) + 0.5;
			val <- on_linked_road ? val * - 1 : val;
			if (val = 0) {
				return location; 
			} else {
				return (location + {cos(heading + 90) * val, sin(heading + 90) * val});
			}
		}
    
   reflex time_in_vehicle_counter when: length(self.bus_passengers) > 0 {
    	ask self.bus_passengers {
    		if n_of_vehicle_switch = 0 {
    			time_in_vehicle <- time_in_vehicle + 1;
    		} else {
    			time_in_vehicle2 <- time_in_vehicle2 + 1;
    		}	
    	}
    } 
    
    
	// define cars_passengers as subspecies of people
	species bus_passengers  parent: people schedules: [] {}
	

	aspect base {
			draw rectangle(vehicle_length + 100, vehicle_width + 100) rotate: heading color: color;
		}			
}

	//-----------------//
	// INFRASTRUCTURES //
	//-----------------//

// define the blocks shape and behavior
species blocks {
	string block;
	string stadtteil;
	bool bewohnt;
	int n_of_buildings_in_block;
	list<living_building>living_places_in_block;
	list<functional_buildings> functional_buildings_in_block;
	list<educational_buildings> kitas_in_block;
	list<educational_buildings> schools_in_block;
	int n_of_living_places_in_block;
	int n_of_functional_buildings_in_block;
	int n_of_schools_in_block;
	int n_of_kitas_in_block;
	list<people> people_in_block;
	list<string> house_types_in_block;
	list<string> household_categories_in_block;
	float avg_walk_dist_to_bus_stop;
	float avg_walk_dist_to_tram_stop;
	float avg_walk_dist_to_pt_stop;
	float avg_walk_dist_to_kita;
	float avg_walk_dist_to_school;
	
	rgb color_inside <- #transparent;
	rgb color_border <- #transparent;
	
	aspect base {
		draw shape color: color_inside border: color_border ;
	}
}

// define the blocks shape and behavior
species block_to_eval {
	string block;
	
	int n_of_buildings;
	int n_of_living_places;
	int	n_of_people;
	string	age_classes_in_block;
	string	household_sizes_in_block;
	string	household_categories_in_block;
	string	house_types_in_block;
	string walk_dist_to_bus_stop;
	string walk_dist_to_tram_stop;
	string walk_dist_to_pt_stop;
	string walk_dist_to_kita;
	string walk_dist_to_school;
	
	
	aspect base {
		draw shape color: #transparent border: #black ;
	}
}

// define tram lines variables and behavior
species tram_lines {
	bool tram96;
	bool tram92;
	aspect base {
		draw shape color: #white border: #black;
	}
}

// define tram lines variables and behavior
species tram_stops {
	int tram96;
	int tram92;
	aspect base {
		draw shape color: #white border: #black;
	}
}

// define intersections variables and behavior
species intersections skills: [skill_road_node] {
	string type;
	string id;
	// Street lights and stop signs
	bool is_traffic_light;
	bool is_stop_sign;
	bool is_pt_stop;
	rgb color;
	int counter <- rnd (time_to_change);
	list<road> ways1;
	list<road> ways2;
	bool is_green;
	bool initialized <- false;
	
	// Motor vehicles' categories
	bool has_motor_vehicles_allowed_roads_in;
	bool has_motor_vehicles_allowed_roads_out;
	bool has_motor_vehicles_allowed_one_of;
	bool has_bike_allowed;

	// Gates to the area
	bool is_entry;
	bool is_exit;
	int entries;
	int exits;
	
	// Busses
    //		a = von außerhalb Zielgebiet nach innerhalb Zielgebiet
    //		a = wenn Strecke komplett im Zielgebiet liegt, dann Nord nach Süd
    //		b = entgegengesetzt
	int bus609a;
	int bus609b;
	int bus612a;
	int bus612b;
	int bus614a;
	int bus614b;
	int bus638a;
	int bus638b;
	int bus650a;
	int bus650b;
	int bus692a;
	int bus692b;
	int bus697a;
	int bus697b;
	int bus698a;
	int bus698b;
	int tram92a;
	int tram92b;
	int tram96a;
	int tram96b;
	int new_bus_line;
	list lines_passing_through;


	
	/////// ACTIONS ///////	
	
	/////// SIGNS AND STREET LIGHT ///////
	
	reflex clean_roads_in_out when: cycle = 1 {
		self.roads_in <- remove_duplicates(self.roads_in);
		self.roads_out <- remove_duplicates(self.roads_out);
	}
	
	// derived from Taillaindier Traffic_rule model
	reflex inizialize_traffic_infrastructure when: initialized = false and (self.is_traffic_light = true or self.is_stop_sign) {
		do initialize;
		initialized <- true;
	}
	
	reflex inizialize_custom_infrastructure when: cycle = 1 and (self.is_traffic_light = true or self.is_stop_sign) {
		do initialize;
		initialized <- true;
	}
	
	// each traffic light is initialized either to perform to_green or to_red action
	action initialize {
		if (is_traffic_light) {
			do compute_crossing;
			stop<- [[],[]];
			if (flip(0.5)) {
				do to_green;
			} else {
				do to_red;
			}	
		} else if is_stop_sign {
			do compute_crossing;
			stop<- [[],ways2];
		}
	}
	
	// crossing is computed so that the road coming from the right is gived ways	
	action compute_crossing{
		if  (length(roads_in) >= 2) {
			road rd0 <- road(roads_in[0]);
			list<point> pts <- rd0.shape.points;						
			float ref_angle <-  float(last(pts) direction_to rd0.location);
			loop rd over: roads_in {
				list<point> pts2 <- road(rd).shape.points;						
				float angle_dest <-  float(last(pts2) direction_to rd.location);
				float ang <- abs(angle_dest - ref_angle);
				if (ang > 45 and ang < 135) or  (ang > 225 and ang < 315) {
					ways2<< road(rd);
				}
			}
		}
		loop rd over: roads_in {
			if not(rd in ways2) {
				ways1 << road(rd);
			}
		}
	}
	
	// For green ways2 are blocked by adding them to the stop list	
	action to_green {
		stop[0] <- ways2 ;
		is_green <- true;
	}

	// For red ways1 are blocked by adding them to the stop list	
	action to_red {
		stop[0] <- ways1;
		is_green <- false;
	}

	// Traffic light change color and action following the counter and its time of change
	reflex traffic_light_switch_normal when: is_traffic_light  {
		counter <- counter + 1;
		if (counter >= time_to_change) { 
			counter <- 0;
			if is_green {do to_red;}
			else {do to_green;}
		} 
	}
	
	//reflex traffic_light_switch_all_vehicles_stopped when: is_traffic_signal = true {
		//self.counter <- self.counter + 1;
		//if (self.counter >= time_to_change) { 
			//self.counter <- 0;
			//self.stop[0] <- empty (self.stop[0]) ? self.roads_in : [] ;
		//} 
	//}

	// aspect depend on the function > street lights 
	// aspect depend on the function > street lights 
	aspect base {
		if (display_switcher_buildings = "Typology") {
			if (is_traffic_light) {
				draw box(1,1,10) color:#black;
				draw sphere(5) at: {self.location.x,self.location.y,12} color: is_green ? #green: #red border: #black;
			} else if (is_stop_sign) {
				draw triangle(3.0) color: #orange border: #black;	
			} else if self.new_bus_line >= 1 { // must be changed when all bus stops are included
				draw triangle(40) at: {self.location.x,self.location.y,12} color: #red border: #black;	
			} else if (is_pt_stop) { // must be changed when all bus stops are included
				draw triangle(40) at: {self.location.x,self.location.y,12} color: #yellow border: #green;
			} 
		} else if (display_switcher_buildings != "Distance to bus stop") {
			if (is_traffic_light) {
				draw box(1,1,10) color:#black;
				draw sphere(5) at: {self.location.x,self.location.y,12} color: is_green ? #green: #red border: #black;
			} else if (is_stop_sign) {
				draw triangle(3.0) color: #orange border: #black;	
			} else if (is_pt_stop) { // must be changed when all bus stops are included
				draw triangle(5) at: {self.location.x,self.location.y,12} color: #yellow border: #green;
			} 
		} else if (display_switcher_buildings = "Distance to pt stop") {
			if (is_traffic_light) {
				draw box(1,1,10) color:#black;
				draw sphere(5) at: {self.location.x,self.location.y,12} color: is_green ? #green: #red border: #black;
			} else if (is_stop_sign) {
				draw triangle(3.0) color: #orange border: #black;	
			} else if (is_pt_stop) { // must be changed when all bus stops are included
				draw triangle(40) at: {self.location.x,self.location.y,12} color: #yellow border: #green;
			} 
		} else if (display_switcher_buildings = "Distance to tram stop") {
			if (is_traffic_light) {
				draw box(1,1,10) color:#black;
				draw sphere(5) at: {self.location.x,self.location.y,12} color: is_green ? #green: #red border: #black;
			} else if (is_stop_sign) {
				draw triangle(3.0) color: #orange border: #black;	
			} else if (self in intersections_closest_to_tram_stops) { // must be changed when all bus stops are included
				draw triangle(40) at: {self.location.x,self.location.y,12} color: #yellow border: #green;
			} 
		} else if (display_switcher_buildings = "Distance to bus stop") {
			if (is_traffic_light) {
				draw box(1,1,10) color:#black;
				draw sphere(5) at: {self.location.x,self.location.y,12} color: is_green ? #green: #red border: #black;
			} else if (is_stop_sign) {
				draw triangle(3.0) color: #orange border: #black;	
			} else if (self in bus_stops) { // must be changed when all bus stops are included
				draw triangle(40) at: {self.location.x,self.location.y,12} color: #yellow border: #green;
			} 
		}
	}
}

// define building variables and behavior
species buildings  {
	
	// id
	string id;
    
    // placement
	string block;
	intersections closest_intersection_2_building;

aspect base {
		color <- #yellow ;
		
		}
}
// educational_buildings as subspecies of building: variables and behavior
species educational_buildings parent: buildings {
	// for educational buildings
	bool is_kita;
	bool is_school;
	string kita_id;
	string school_id;	
	
    // placement
	string block;
	
	aspect base {
		color <- #grey ;
		}
}

// functional_buildings as subspecies of building: variables and behavior
species functional_buildings parent: buildings {
	// for functional buildings
	bool is_education;
	bool is_shopping;
	bool is_leisure;
	bool is_living_place;
	bool is_working_place;
	
    // placement
	string block;

aspect base {
		if is_working_place = true {
			color <- #black ;
		}  else if is_shopping = true {
			color <- #green ;
		} else if is_education = true {
			color <- #cyan ;
		} else if is_leisure = true {
			color <- #purple ;
		}
		draw shape color: color;	
		}
}

// living_building as subspecies of building: variables and behavior
species living_building parent: buildings {
	// building typology
	string house_type;
	string block;
	// distances
    float walk_dist_to_bus_stop;
    float walk_dist_to_tram_stop;
    float walk_dist_to_pt_stop;
    float walk_dist_to_kita;
    float walk_dist_to_school;
    float walk_dist_to_shopping_place;
    string dist_to_pt_category;
    
    // quick access places
    intersections closest_bus_stop; 
    string closest_school;     
    string closest_kita;
    string closest_shop;
    
    //float walk_dist_to_shopping_place;
    int red_bus;
    int red_shop;
    int red_pt;
    int red_tram;
    
    // capacity
    int n_households;
  
    
    // perform calculation of distances - if new customized bus stops have been added
	action calc_dist_building {
			// pick up the closest bus stop
			closest_bus_stop <- bus_stops at_distance 2000 closest_to self;
			if closest_bus_stop = nil {
				closest_bus_stop <- bus_stops closest_to self;
			}
			// if the closest bus stop is one of the bus stop of the new line, it updates the distance
			if closest_bus_stop.lines_passing_through contains "new_bus_line" {
				path shortest_path_to_bus <- path_between(pedestrian_network, self, closest_bus_stop);
				walk_dist_to_bus_stop <- shortest_path_to_bus.shape.perimeter;
			}
	}
	
	action update_color_pt {
		self.red_pt <- self.walk_dist_to_pt_stop * (255/max_dist_to_pt_stop);
	}
	
	action update_color_bus{
		self.red_bus <- self.walk_dist_to_bus_stop * (255/max_dist_to_bus_stop);
	}
	
	action update_color_tram{
		self.red_tram<- self.walk_dist_to_tram_stop * (255/max_dist_to_tram_stop);
	}
	
	action update_color_shopping {
		self.red_shop <- self.walk_dist_to_shopping_place * (255/max_dist_to_shopping);
	}
    
    	aspect base {
		 if display_switcher_buildings = "Typology" {
					if house_type = "einzel" {
						color <- #darkred ; 
					} else if house_type = "mehr" {
						color <- #red ; 
					} else if house_type = "doppel" {
						color <- #salmon ; 
					} else if house_type = "reihenend" {
						color <- #orange ; 
					} else if house_type = "reihen" {
						color <- #orange ; 
					}
				draw shape color: color;
			} else if display_switcher_buildings = "Distance to bus stop" {
				do update_color_bus;
				color <- rgb(255, red_bus, red_bus);
				draw shape color: color;
			} else if display_switcher_buildings = "Distance to pt stop" {
				do update_color_pt;
				color <- rgb(255, red_pt, red_pt);
				draw shape color: color;
			} else if display_switcher_buildings = "Distance to tram stop" {
				do update_color_tram;
				color <- rgb(255, red_tram, red_tram);
				draw shape color: color;
			} else if display_switcher_buildings = "Distance to shopping place" {
				do update_color_shopping;
				color <- rgb(255, red_shop, red_shop);
				draw shape color: color;						
			}
		} 
	}



// define parking_areas variables and behavior
species parking_areas {
	rgb color <- rgb(red, 180, 100);
	int available_parking_places <- 0;
	int parking_areas_capacity <- available_parking_places;
	list<car> currently_parked_cars_before <- [];
	list<car> currently_parked_cars_after <- [];
	int n_currently_parked_cars <- 0;
	int counter <- 0;
	float covered_percentage <- 0.0;
	int red <- 0;
	
	// update the availability of parking places
	reflex update_available_parking_places when: length(car overlapping self) > 0 { // triggered only if there are some cars overlaping the parking place
		// a counter is used to verify if the number of car parked has changed
		if self.counter = 0 { // at time point 0
			self.currently_parked_cars_before <- car overlapping self; // a list of the car overlapping the parking area is produced
			self.n_currently_parked_cars <- length(self.currently_parked_cars_before); // the n of car parked is updated
			self.available_parking_places <- self.parking_areas_capacity - self.n_currently_parked_cars; // the current availability is updated
			self.counter <- 1; // the counter is set to one
		} else if counter = 1 { // at time point 1
			self.currently_parked_cars_after <- car overlapping self; // a list of the car overlapping the parking area is produced
			if (length(self.currently_parked_cars_after) != length(self.currently_parked_cars_before)) { // the list generated at time point 0 and 1 are compared, if they are not equal
				self.n_currently_parked_cars <- length(self.currently_parked_cars_after);  // the n of car parked is updated
				self.available_parking_places <- self.parking_areas_capacity - self.n_currently_parked_cars; // the current availability is updated
				self.currently_parked_cars_before <- self.currently_parked_cars_after; // the list of time point 1 became the list of time point 0
				self.currently_parked_cars_after <- []; // the list of time point 1 is empty
				self.counter <- 0; // the counter is set to 0
			}
		}
	}
	
	// to update color of parking area for visualization purpose
	// the percentage covered is related to the red, the higher the percentage the darker the color (salmon), otherwise it's green/yellow
	reflex update_color when: covered_percentage > 0.0 {
		self.covered_percentage <- (1 - ((self.parking_areas_capacity - self.n_currently_parked_cars) / self.parking_areas_capacity)) *100;
		self.red <- 255 - ((255 * self.covered_percentage)/100);
		if self.red > 255 {
			self.red <- 255;
		}
	}
	
	aspect base {
		draw shape color: #grey ;	
	}	

	
	aspect percentage_covered {
		color <- (red, 180, 100);
		// draw shape color: (red, 180, 100); // the more the parking areas is covered, the closer to read is the color
		draw shape color: color ; // the more the parking areas is covered, the closer to read is the color
	}
}

// define roads variables and behavior
species road skills: [skill_road]   {
	
	// infrastructure
	string oneway;
	string road_type;
	int speed_limit;
	rgb color;
	
	int vehicles_on_the_road <- 0;
	int cars_on_the_road <- 0;

	// motor vehicles categories
    bool motor_vehicles_allowed;
    bool bikes_allowed;
    bool pedestrians_allowed;
    
    // Busses
	bool bus609;
	bool bus612;
	bool bus614;
	bool bus638;
	bool bus650;
	bool bus692;
	bool bus697;
	bool bus698;


    reflex collect_traffic_data when: length(self.all_agents) > 0 {
		ask self {
			//------ Current n of vehicles ------ //
			// collect data about vehicles currently on the road
			self.vehicles_on_the_road <- length(self.all_agents);
			// collect data about cars (car + external_agents) currently on the road
			self.cars_on_the_road <- self.all_agents count (each.name contains_any ["car", "external_agents"]);
		}
	}
    
    
    //// fix that if a street scope is changed, the whole network must be recomputed
    /// ["Open street map", "Public transport","Road vehicle categories"];
	aspect base {
		if display_switcher_roads = "Open street map" {
				if color = rgb(255,255,255) {
					draw shape color: color border: #black; // add shape if color is white
				} else {
					draw shape color: color;
				}			
		} else if display_switcher_roads = "Public transport" {
				if color != #gray {
					draw shape width: 4 color: color;
				} else {
					draw shape color: color;	
				}
		} else if display_switcher_roads = "Road vehicle categories" {
				draw shape color: color;	
		}	
	}
}

	//--------------//
	// HUMAN AGENTS //
	//--------------//

// define people variables and behavior
species people skills: [moving] control:fsm {
	// IDS and personal characteristica
	string block;
	string Personal_ID;
	string stadtteil;
	rgb color;
	int age;
	string age_class;
	string household_size;
	string household_category;
	bool has_modi_decision;
	
	// activity plan
	list<string> today_activity_plan;
	
	// family related variables
	string household;
	bool has_children;
	list<people> family_members_id;
	
	// Work related variables
	string employed_status;
	list working_frequency;
	bool working_age;
    int start_work ;
    int minute_start_work ;
    int end_work  ;
    int minute_end_work ;
    bool is_commuter <- false;

	// Leisure related variables
	bool is_leisure_outside;
	list leisure_frequency;
    int start_leisure ;
    int minute_start_leisure ;
    int end_leisure  ;
    int minute_end_leisure ;
    int leisure_duration;
    
	// Shopping related variables
	bool is_shopping_outside;
	list shopping_frequency;
    int start_shopping ;
    int minute_start_shopping ;
    int end_shopping ;
    int minute_end_shopping ;
    int shopping_duration;
    
	// Places
    living_building my_living_place <- nil ;
    string my_living_place_id;
    buildings my_working_place <- nil ;
    string my_working_place_id;
    buildings my_shopping_place <- nil ;
    string my_shopping_place_id;
    buildings my_leisure_place <- nil ;
    string my_leisure_place_id;
    string my_exit_id;
    intersections my_exit <- nil;
    intersections my_entry <- nil; 
    intersections my_get_on_stop;
    intersections my_get_off_stop;
    
    // Transport modi
    string modi <- nil;
    car my_car <- nil;
    bool has_car;
    bool has_bike;
	path path_to_the_target;
	list my_pt_line;
	float bike_speed;
	float walking_speed;
	
    // Operational and driving skill related
    agent the_target;
    buildings building_target;
    bool is_outside <- false;
	string currently_doing <- "at_home";
	bool will_drive_out <- false;
	bool consecutive_activity <- false; // if true the agent will not drive to the living place between the first and second activity
	bool consecutive_activity_2 <- false; // if true the agent will not drive to the living place between the second and third activity	
	bool driving_back;
	bool staying_outside <- false;
	
	// rdt and bus
	bool at_bus_stop <- false; // used to activate the reflex for repeatedly waiting for the bus
	bool switching_bus;
	int stand_by_counter <- 0;
	bool rdt_passenger <- false;
	bool switch_to_rdt;
	bool rdt_pick_up_candidate;
	
	// times
	// overall trip
	date start_trip_time;
	date end_trip_time;
	// waiting at stop or to be pick-up
	int waiting_time_in_sec;
	int n_of_vehicle_switch;
	int waiting_time_in_sec2;
	// time in vehicle
	int time_in_vehicle;
	int time_in_vehicle2;
	// reaching the transport vehicle (car, public transport)
	date start_reach_vehicle;
	date end_reach_vehicle;
	// reaching the building after leaving the transport vehicle (car, public transport)
	date start_reach_destination;
	date end_reach_destination;
	
	
	state finish initial: false {
		if my_car != nil {
			ask my_car {
				do die;
			}
		}
		do die;
	}
	state initiate initial: true {
		color <- #black;
		currently_doing <- first(self.today_activity_plan);
		remove first(self.today_activity_plan) from: self.today_activity_plan;

		transition to: finish when: empty(today_activity_plan) {}
		transition to: stand_by when: !empty(today_activity_plan) {}
	}
		
	state stand_by initial:false {
		// calculate and save the times
		if start_trip_time != nil {
			end_trip_time <- current_date;
			int trip_duration <- milliseconds_between(start_trip_time, end_trip_time) / 1000;

			int reach_vehicle_duration;
			if start_reach_vehicle != nil and end_reach_vehicle != nil {
				reach_vehicle_duration <- milliseconds_between(start_reach_vehicle, end_reach_vehicle) / 1000;
			} else {
				reach_vehicle_duration <- 0;
			}
			
			int reach_destination_duration;
			if start_reach_destination != nil and end_reach_destination != nil {
				reach_destination_duration <- milliseconds_between(start_reach_destination, end_reach_destination) / 1000;
			} else {
				reach_destination_duration <- 0;
			}
			
			point destination;
			if will_drive_out = true {
				destination <- my_exit.location;
			} else if will_drive_out = false {
				destination <- building_target.location;
			}
			
			ask DB_accessor {
				do insert (params: PARAMS, into: "results_" + scenario_name + "_people_data" , 
	               columns: ["Personal_ID", "modi", "rdt_passenger", "currently_doing", "origin_x", "origin_y", "destination_x", "destination_y","rdt_pick_up_candidate", "n_of_vehicle_switch", "start_trip_time",  "trip_duration", "waiting_time_in_sec", "waiting_time_in_sec2",  "reach_the_vehicle_duration", "reach_the_destination_duration", "time_in_vehicle", "time_in_vehicle2"], 
	               values: [myself.Personal_ID, myself.modi, myself.rdt_passenger, myself.currently_doing, myself.location.x, myself.location.y, destination.x, destination.y, myself.rdt_pick_up_candidate, myself.n_of_vehicle_switch, myself.start_trip_time,  
	               	trip_duration, 
	               	myself.waiting_time_in_sec,
	               	myself.waiting_time_in_sec2, 
	               	reach_vehicle_duration, 
	               	reach_destination_duration,
	               	myself.time_in_vehicle,
	               	myself.time_in_vehicle2]);
			}
			start_trip_time <- nil;
			end_trip_time <- nil;
			start_reach_vehicle <- nil;
			end_reach_vehicle <- nil;
			start_reach_destination <- nil;
			end_reach_destination <- nil;
			waiting_time_in_sec <- nil;
			waiting_time_in_sec2 <- nil;
			time_in_vehicle <- nil;
			time_in_vehicle2 <- nil;
			n_of_vehicle_switch <- 0;
		}	
		
		if currently_doing = 'Home' {
			has_modi_decision <- false;
			driving_back <- false;
			my_get_on_stop <- nil;
			my_get_off_stop <- nil;
		}
		
		
		
		transition to: initiate when: empty(today_activity_plan) {}
		/////////////
		// WORKING //
		/////////////
		// start trip to go to work
		transition to:evaluate_modi when: current_date.hour = start_work and
		    current_date.minute = minute_start_work and
		    current_date.second = 0 and
		    currently_doing = "Home" {
		    	//////////// GENERAL ////////////
				// the agent is currently performing an activity so that it cannot be call for another activity (used to prevent crash because of unreachable agents)
				currently_doing <- first(self.today_activity_plan);	
				remove first(self.today_activity_plan) from: self.today_activity_plan;
				write "Working 1 - Agent: " + self.Personal_ID + currently_doing + " as part of " + today_activity_plan;
				start_trip_time <- current_date; // save trip departure time
			   	
				//////////// DESTINATION ////////////
			    // will_drive_out is used to unify is_commuter, is_shopping_outside and is_leisure_outside
			    if is_commuter = true {
			   		will_drive_out <- true; // the agent is going to drive out
			   	} else if is_commuter = false {
				   	will_drive_out <- false; // the agent is not going to drive out
			   		building_target <- my_working_place; // set target as my_working_place
			   	}
			   	stand_by_counter <- stand_by_counter + 1;
			   	write "Agent " + Personal_ID + " start trip to go to work";
		    }
		 
		// start trip to drive back home after work
	    transition to:evaluate_modi when: current_date.hour = end_work and
		    current_date.minute = minute_end_work and
		    current_date.second = 0 and
		    consecutive_activity = false and
		    (currently_doing = "Working" or
		    currently_doing = "School") {
			   	//////////// GENERAL ////////////
				start_trip_time <- current_date; // save trip departure time
				will_drive_out <- false;
				currently_doing <- first(self.today_activity_plan);	
				remove first(self.today_activity_plan) from: self.today_activity_plan;
				write "Working 2 - Agent: " + self.Personal_ID + currently_doing + " as part of " + today_activity_plan;
				//////////// DESTINATION ////////////
			    building_target <- my_living_place; // set target as my_living_place
				stand_by_counter <- stand_by_counter + 1;
				driving_back <- true;
			write "Agent " + Personal_ID + " start trip to drive back home after work";
		    }
		 
		// start trip to reach a second destination after working
	    transition to:evaluate_modi when: current_date.hour = end_work and
		    current_date.minute = minute_end_work and
		    current_date.second = 0 and
		    consecutive_activity = true and
		    (currently_doing = "Working" or
		    currently_doing = "School") {
		    	//////////// GENERAL ////////////
			    consecutive_activity <- false; // since the activity that is going to start is the second activity (or the consecutive activity 1) this is set to false
				currently_doing <- first(self.today_activity_plan);	
				remove first(self.today_activity_plan) from: self.today_activity_plan;
				write "Working 3 - Agent: " + self.Personal_ID + currently_doing + " as part of " + today_activity_plan;
			    //////////// DESTINATION ////////////
			    
			    // In case the agent was working outside and shop outside > hence: staying_outside = true
			    if is_commuter = true and is_shopping_outside = true and end_work = start_shopping and minute_end_work = minute_start_shopping { // if is working and doing shopping outside the end_work time is set to end shopping time and nothing more happen
			  		end_work <- end_shopping;
			  		minute_end_work <- minute_end_shopping;
			  		staying_outside <- true;
			    // In case the agent was working outside and leisure outside > hence: staying_outside = true
			    } else if is_commuter = true and is_leisure_outside = true and end_work = start_leisure and minute_end_work = minute_start_leisure  { // if is working and doing leisure activities outside the end_work time is set to end shopping time and nothing more happen
			  		end_work <- end_leisure;
			  		minute_end_work <- minute_end_leisure;
			  		staying_outside <- true;
				// in case the agent is not working outside or he was working outside but performs the second activity inside
			    } else if (is_commuter = true and is_shopping_outside = false and end_work = start_shopping and minute_end_work = minute_start_shopping) or 
			    (is_commuter = true and is_leisure_outside = false and end_work = start_leisure and minute_end_work = minute_start_leisure) or 
			    is_commuter = false
			    {
			    	if end_work = start_shopping and minute_end_work = minute_start_shopping {
			    		building_target <- my_shopping_place; // set target as my_shopping_place
			    	} else if end_work = start_leisure and minute_end_work = minute_start_leisure {
			    		building_target <- my_leisure_place; // set target as my_leisure_place
			    	}
			    
			    	start_trip_time <- current_date; // save trip departure time
			    	
			    	// if the following activity is shopping
					  if currently_doing = "Shopping" {
				        	if is_shopping_outside = true {
					        	the_target <- my_exit; // set targe	      
					        	will_drive_out <- true;  		
				        	} else if is_shopping_outside = false {
					        	building_target <- my_shopping_place; // set target as my_shopping_place
					        	will_drive_out <- false;
				        	}
				       // if the following activity is leisure
				       } else if currently_doing = "Leisure" {
				        	if is_leisure_outside = true {
				        	the_target <- my_exit; // set target
				        	will_drive_out <- true;     		
				        	} else if is_leisure_outside = false {
				        	building_target <- my_leisure_place; // set target as my_shopping_place
				        	will_drive_out <- false;      		
				        	}	       
				       }
			    	}
			    	stand_by_counter <- stand_by_counter + 1;
			    	write "Agent " + Personal_ID + " start trip to reach a second destination after working";
		    }
		
		//////////////
		// SHOPPING //
		//////////////
		// start trip to go shopping 
		transition to:evaluate_modi when: current_date.hour = start_shopping and
		    current_date.minute = minute_start_shopping and
		    current_date.second = 0 and
		    currently_doing = "Home" {
		    	//////////// GENERAL ////////////
				// the agent is currently performing an activity so that it cannot be call for another activity (used to prevent crash because of unreachable agents)
				currently_doing <- first(self.today_activity_plan);	
				remove first(self.today_activity_plan) from: self.today_activity_plan;
				write "Shopping 1 - Agent: " + self.Personal_ID + currently_doing + " as part of " + today_activity_plan;
				start_trip_time <- current_date;
				
				//////////// DESTINATION ////////////
			    // If the activity will take place outside of the area, will_drive_out is set to true
			    if is_shopping_outside = true {
			   		will_drive_out <- true; // set target as my_working_place
			   	} else if is_shopping_outside = false {
			   		will_drive_out <- false; // the agent is not going to drive out
			   		building_target <- my_shopping_place; // set target as my_leisure_place
			   	}
			   	stand_by_counter <- stand_by_counter + 1;
			   	write "Agent " + Personal_ID + " start trip to go shopping";	    
		    }
		
		// start trip to drive back home after shopping
	  	transition to:evaluate_modi when: current_date.hour = end_shopping and
			current_date.minute = minute_end_shopping and
			current_date.second = 0 and
			consecutive_activity = false and
			consecutive_activity_2 = false and 
		   	currently_doing = "Shopping" {
		   		 //////////// GENERAL ////////////
			    start_trip_time <- current_date;
			    will_drive_out <- false;
				currently_doing <- first(self.today_activity_plan);	
				remove first(self.today_activity_plan) from: self.today_activity_plan;
				write "Shopping 2 - Agent: " + self.Personal_ID + currently_doing + " as part of " + today_activity_plan;
			    //////////// DESTINATION ////////////
			   	building_target <- my_living_place; // set target as my_living_place
			    stand_by_counter <- stand_by_counter + 1;
			    driving_back <- true;
			    write "Agent " + Personal_ID + " start trip to drive back home after shopping";	    
		   	}
		
		// start trip to reach a second destination after shopping
		transition to:evaluate_modi when: current_date.hour = end_shopping and
		    current_date.minute = minute_end_shopping and
		    current_date.second = 0 and
		    currently_doing = "Shopping" and
		    ((consecutive_activity = true) or (consecutive_activity_2 = true)) {
		    	//////////// GENERAL ////////////
			  	// if the second consecutive activity has been called, it will be set to false
			   	if consecutive_activity_2 = true and consecutive_activity = false {
			   		consecutive_activity_2 <- false;
			   	}
			    // if the first consecutive activity was called, it will be set to false, or it remains falls if it was already false
			    consecutive_activity <- false;
				currently_doing <- first(self.today_activity_plan);	
				remove first(self.today_activity_plan) from: self.today_activity_plan;
				write "Shopping 3 - Agent: " + self.Personal_ID + currently_doing + " as part of " + today_activity_plan;
			    //////////// DESTINATION ////////////
			    if is_shopping_outside = true and is_leisure_outside = true and end_shopping = start_leisure and minute_end_shopping = minute_start_leisure
			    { // if is doing shopping outside and leisure also takes place outside the end_shopping time is set to end leisure time and nothing more happen
			  		end_shopping <- end_leisure;
			  		minute_end_shopping <- minute_end_leisure;
			  		staying_outside <- true;
			    } else if is_shopping_outside = false and end_shopping = start_leisure and minute_end_shopping = minute_start_leisure { // in all other cases he will drive to the second activity inside the area
			    	start_trip_time <- current_date; // save trip departure time
			    	if is_leisure_outside = true {
			    	the_target <- my_exit; // set target as my_shopping_place
			    	will_drive_out <- true;	        		
			    	} else if is_leisure_outside = false {
			    	building_target <- my_leisure_place; // set target as my_shopping_place
			    	will_drive_out <- false;       		
			    	}
			    }
			    stand_by_counter <- stand_by_counter + 1;
			    write "Agent " + Personal_ID + " start trip to reach a second destination after shopping";	
		    }
		
		/////////////
		// LEISURE //
		/////////////
		
		// start trip to reach leisure activity place
		transition to:evaluate_modi when: current_date.hour = start_leisure and
		    current_date.minute = minute_start_leisure and
		    current_date.second = 0 and
		    currently_doing = "Home" {
		    	//////////// GENERAL ////////////
				currently_doing <- first(self.today_activity_plan);	
				remove first(self.today_activity_plan) from: self.today_activity_plan;
				write "Leisure 1 - Agent: " + self.Personal_ID + currently_doing + " as part of " + today_activity_plan;
				start_trip_time <- current_date;
				
				//////////// DESTINATION ////////////
			    // If the activity will take place outside of the area, will_drive_out is set to true
			    if is_leisure_outside = true {
			   		will_drive_out <- true;
			   	} else if is_leisure_outside = false {
			   		will_drive_out <- false;
			   		building_target <- my_leisure_place;
			   	}
			   	stand_by_counter <- stand_by_counter + 1;
			   	write "Agent " + Personal_ID + " start trip to reach leisure activity place";	
		    }
		
		// start trip to drive back home after leisure
		transition to:evaluate_modi when: current_date.hour = end_leisure and
		   current_date.minute = minute_end_leisure and
		   current_date.second = 0 and
		   consecutive_activity = false and
		   consecutive_activity_2 = false and
		   currently_doing = "Leisure" {
		   	//////////// GENERAL ////////////
		    start_trip_time <- current_date;
			will_drive_out <- false;
			currently_doing <- first(self.today_activity_plan);	
			remove first(self.today_activity_plan) from: self.today_activity_plan;
			write "Leisure 2 - Agent: " + self.Personal_ID + currently_doing + " as part of " + today_activity_plan;
		    //////////// DESTINATION ////////////    
		   	building_target <- my_living_place; // set target as my_living_place
		    // if has car is going to travel by car	
		    stand_by_counter <- stand_by_counter + 1;
		    driving_back <- true;
		    write "Agent " + Personal_ID + " start trip to drive back home after leisure";	
		   }
		
		// start trip to reach a second destination after leisure
		transition to:evaluate_modi when: current_date.hour = end_leisure and
		    current_date.minute = minute_end_leisure and
		    current_date.second = 0 and
		    currently_doing = "Leisure" and
		    ((consecutive_activity = true) or (consecutive_activity_2 = true)) {
		    	//////////// GENERAL ////////////
			    // if the second consecutive activity has been called, it will be set to false
			    if consecutive_activity_2 = true and consecutive_activity = false {
			   		consecutive_activity_2 <- false;
			   	}
			   	
			    // if the first consecutive activity was called, it will be set to false, or it remains falls if it was already false
			    consecutive_activity <- false;
				currently_doing <- first(self.today_activity_plan);	
				remove first(self.today_activity_plan) from: self.today_activity_plan;
				write "Leisure 3 - Agent: " + self.Personal_ID + currently_doing + " as part of " + today_activity_plan;	
			    //////////// DESTINATION ////////////
			    if is_leisure_outside = true and is_shopping_outside = true and end_leisure = start_shopping and minute_end_leisure = minute_start_shopping
			    { // if is doing shopping outside and leisure also takes place outside the en_shopping time is set to end leisure time and nothing more happen
			  		end_leisure <- end_shopping;
			  		minute_end_leisure <- minute_end_shopping;
			  		staying_outside <- true;
			    } else if is_leisure_outside = false and end_leisure = start_shopping and minute_end_leisure = minute_start_shopping { // in all other cases he will drive to the second activity inside the area
			    	start_trip_time <- current_date; // save trip departure time
			    	if is_shopping_outside = true {
			    	the_target <- my_exit; // set target as my_shopping_place
			    	will_drive_out <- true;	        		
			    	} else if is_shopping_outside = false {
			    	building_target <- my_shopping_place; // set target as my_shopping_place
			    	will_drive_out <- false;       		
			    	}        
			    }
			stand_by_counter <- stand_by_counter + 1;
			write "Agent " + Personal_ID + " start trip to reach a second destination after leisure";	
		    }
	}
	
	state evaluate_modi initial: false {
		
		transition to: stand_by when: staying_outside = true {
			staying_outside <- false;
		}
		
		if has_modi_decision = false {
			if currently_doing != "School" and modi = nil {
				/// update it with SrV data
				//self.modi <- "car";
				self.modi <- rnd_choice(["bike"::0.23,"public_transport"::0.21,"car"::0.34, "pedestrian"::0.24]);
				// modal split data drawn from https://www.potsdam.de/sites/default/files/documents/verkehrsbefragung_potsdam_2018_steckbrief.pdf
			} else if currently_doing = "School" and modi = nil {
				// provisorisch a definitive strategy must be defined // right now independtly of age > random modi between
				self.modi <- rnd_choice(["bike"::0.55,"public_transport"::0.0,"pedestrian"::0.45]);
			}
		}
		
		transition to: start_trip when: modi != nil {
		}
		transition to: start_trip when: has_modi_decision = true ;
		transition to: start_trip when: currently_doing = "School"{
			has_modi_decision <- true;
		}
		
	}
	
	state wait_evaluation initial: false {
			
		transition to: start_trip when: currently_doing = "School"{
			has_modi_decision <- true;
		}
	}
	
	state start_trip initial: false {
		write "Agent: " + self + "currently_doing: " + currently_doing + " by: " + modi;
		if currently_doing = "Working" {
			 	if modi = "car" {
			 		working_car <- working_car + 1;
			 		write "At: " + cycle + " count of working_car: " + working_car;
			 	} else if modi = "bike" {
			 		working_bike <- working_bike + 1;
			 		write "At: " + cycle + " count of working_bike: " + working_bike;
			 	} else if modi = "public_transport" {
			 		working_pt <- working_pt + 1;
			 		write "At: " + cycle + " count of working_pt: " + working_pt;
			 	} else if modi = "pedestrian" {
			 		working_pedestrian <- working_pedestrian + 1;
			 		write "At: " + cycle + " count of working_pedestrian: " + working_pedestrian;
			 	}	
		} else if currently_doing = "Leisure" {
				if modi = "car" {
			 		leisure_car <- leisure_car + 1;
			 		write "At: " + cycle + " count of leisure_car: " + leisure_car;
			 	} else if modi = "bike" {
			 		leisure_bike <- leisure_bike + 1;
			 		write "At: " + cycle + " count of leisure_bike: " + leisure_bike;
			 	} else if modi = "public_transport" {
			 		leisure_pt <- leisure_pt + 1;
			 		write "At: " + cycle + " count of leisure_pt: " + leisure_pt;
			 	} else if modi = "pedestrian" {
			 		leisure_pedestrian <- leisure_pedestrian + 1;
			 		write "At: " + cycle + " count of leisure_pedestrian: " + leisure_pedestrian;
			 	}
		} else if currently_doing = "Shopping" {
				if modi = "car" {
			 		shopping_car <- shopping_car + 1;
			 		write "At: " + cycle + " count of shopping_car: " + shopping_car;
			 	} else if modi = "bike" {
			 		shopping_bike <- shopping_bike + 1;
			 		write "At: " + cycle + " count of shopping_bike: " + shopping_bike;
			 	} else if modi = "public_transport" {
			 		shopping_pt <- shopping_pt + 1;
			 		write "At: " + cycle + " count of shopping_pt: " + shopping_pt;
			 	} else if modi = "pedestrian" {
			 		shopping_pedestrian <- shopping_pedestrian + 1;
			 		write "At: " + cycle + " count of shopping_pedestrian: " + shopping_pedestrian;
			 	}
		} else if currently_doing = "School" {
				if modi = "car" {
			 		school_car <- school_car + 1;
			 		write "At: " + cycle + " count of school_car: " + school_car;
			 	} else if modi = "bike" {
			 		school_bike <- school_bike + 1;
			 		write "At: " + cycle + " count of school_bike: " + school_bike;
			 	} else if modi = "public_transport" {
			 		school_pt <- school_pt + 1;
			 		write "At: " + cycle + " count of school_pt: " + school_pt;
			 	} else if modi = "pedestrian" {
			 		school_pedestrian <- school_pedestrian + 1;
			 		write "At: " + cycle + " count of school_pedestrian: " + school_pedestrian;
			 	}
		}
		has_modi_decision <- true;

		
		//////////// TRANSPORT MODI ////////////
        if modi = "car" {
        	my_car <- nil;
        	if my_car = nil {
        		///// CREATE ONE CAR /////
				create car number: 1 {
					vehicle_length <- gauss(4.4#m,0.5#m);
					vehicle_width <- gauss(1.8#m,0.1#m);
					right_side_driving <- true;
					proba_lane_change_up <-  rnd(0.1, 1.0); // probability to change lane to a upper lane (left lane if right side driving) if necessary
					proba_lane_change_down <- rnd(0.5, 1.0); // probability to change lane to a lower lane (right lane if right side driving) if necessary
					security_distance_coeff <- 5 / 9 * 3.6 * rnd(1.5); // the coefficient for the computation of the the min distance between two drivers
					// (according to the vehicle speed - safety_distance =max(min_safety_distance, safety_distance_coeff * min(self.real_speed, other.real_speed) )
					proba_respect_priorities <- rnd(1.0, 1.0); // probability to respect priority (right or left) laws
					proba_respect_stops <- [1.0,1.0]; // probability to respect stop laws - first value for red stop, second for stop sign
					proba_block_node <- 0.0; // probability to block a node (do not let other driver cross the crossroad)
					proba_use_linked_road <- 0.1; // probability to change lane to a linked road lane if necessary
					max_acceleration <- 4 / 3.6 ; // maximum acceleration of the car for a cycle
					max_speed <- (rnd(35,50) °km / °h); // max speed of the car for a cycle
					min_security_distance <- 1.5 #m; // the minimal distance to another driver
					speed_coeff <- rnd(0.8, 1.2); // speed coefficient for the speed that the driver want to reach (according to the max speed of the road)
					self.my_parking_place <- (parking_areas where (each.available_parking_places >= 1) at_distance 200 closest_to(myself));
	    			if self.my_parking_place = nil {
		    				self.my_parking_place <- (parking_areas where (each.available_parking_places >= 1) closest_to(myself));
		    		}
		    		owner <- myself;
				}
				my_car <- shuffle(car) first_with (each.owner = self); 
        	}
        	the_target <-  my_car ;
        	if will_drive_out = false {
	        	ask my_car {
	        		is_leaving_the_area <- false;
	        		self.car_target <- driving_intersections closest_to (myself.building_target); // set the target of the car as my target
				}
			} else if will_drive_out = true {
				ask my_car {
					is_leaving_the_area <- true;
					self.car_target <- myself.my_exit; // set the target of the car as my target
				}	
			}
		// if has not car and has a bike is going to travel by bike	
		} else if modi = "bike" {
			if will_drive_out = false {
				// problem here
				if building_target = nil {
					building_target <- my_living_place;
				} 
	        	ask building_target{
						myself.the_target <- self.closest_intersection_2_building;
				}
				//the_target <- building_target;
        	} else if will_drive_out = true {
        		the_target <- self.my_exit;
        	}
		} else if modi = "public_transport" and driving_back = false and currently_doing != "Home"{
			// if the agent is doing some activities, stops should be defined
			do normal_stop_decision;
		} else if modi = "public_transport" and driving_back = true and currently_doing = "Home" {
			// if the agent is heading home
			if rdt_passenger = false  {
				// if the agent is not a rdt passenger simply switch
				intersections temp <- my_get_on_stop;
				my_get_on_stop <- my_get_off_stop;
				my_get_off_stop <- temp;
				the_target <- my_get_on_stop;
			} else if rdt_passenger = true {
			// if the agent is a rdt passenger it must be checked if he need to switch or not
			if switching_bus = false {
				// if he travel straight with the rdt bus, than simply switch
				intersections temp <- my_get_on_stop;
				my_get_on_stop <- my_get_off_stop;
				my_get_off_stop <- temp;
				the_target <- my_get_on_stop;				
			} else {
				// if he need to switch than he will drive to a rdt switching station and it is saved that he is switching
				switch_to_rdt <- true;
				do drive_to_rdt_switching_station;
				}
			} 	
		} else if modi = "pedestrian" {
			if will_drive_out = false {
	        	ask building_target {
					myself.the_target <- self.closest_intersection_2_building;
				}
				write the_target;
				//the_target <- building_target;
        	} else if will_drive_out = true {
        		the_target <- self.my_exit;
        	}
		}
		
		if will_drive_out = true {
			color <- #red;
		} else if will_drive_out = false {
			color <- #blue;
			is_outside <- false;
		}
		
		
		// first check for public transport > both stops are equal
		if self.my_get_on_stop = self.my_get_off_stop and modi = "public_transport" {
				my_get_on_stop <- nil;
				my_get_off_stop <- nil;
				my_pt_line <- nil;
				modi <- "pedestrian";
				if will_drive_out = false {
		        	ask building_target {
						myself.the_target <- self.closest_intersection_2_building;
					}
					//the_target <- building_target;
	        	} else if will_drive_out = true {
	        		the_target <- my_exit;
	        	}
			}
		
		// second check for public transport > stops are not in the same line
		// bus609a_stops bus609b_stops bus612a_stops bus612b_stops bus614a_stops bus614b_stops bus638a_stops bus638b_stops bus650a_stops bus650b_stops
				// bus692a_stops bus692b_stops bus697a_stops bus697b_stops bus698a_stops bus698b_stops
				// intersections_closest_to_tram_stops_92a intersections_closest_to_tram_stops_92b intersections_closest_to_tram_stops_96a intersections_closest_to_tram_stops_96b
		
		// the problem is that sometimes agents have a my_get_on_stop and my_get_off_stop that are not on the same line...
		// fox it by checking wheter it is the case (see below)
		// another options would be to clearly define the lines_passing_through by the interactions
		
		
		
		
		transition to:move when: !(empty(the_target)) {
		}
		
	}
	
	state move initial: false {
		if start_reach_vehicle = nil and (modi = 'public_transport' or modi = 'car'){
			start_reach_vehicle <- current_date;
		}
		if modi = "bike" {
			// substitute follow path: path_to_the_target
			speed <- bike_speed;
			do goto target:self.the_target on:bike_network;
		} else if modi = "pedestrian" or modi = "public_transport" or modi = "car" {
			if my_pt_line contains "new_bus_line" and rdt_pick_up_candidate = true {
				do call_rdt;
			} else if my_pt_line contains "new_bus_line" and perc_pick_up_service > rnd(1,101) {
				do call_rdt;
			} else {
				speed <- walking_speed;
				do goto target:self.the_target on:pedestrian_network;
			}
		}	

		// for agents that were outside
		transition to:get_on when: modi = "public_transport" and self.the_target = tram_exit {
			end_reach_vehicle <- current_date;
			path_to_the_target <- nil;
			the_target <- nil;
		}
		
		// modified von self.location overlaps self.the_target
		transition to:get_on when: (modi = "car" or modi = "public_transport") and self.location overlaps self.the_target {
			end_reach_vehicle <- current_date;
			path_to_the_target <- nil;
			the_target <- nil;
		}
		
		transition to:stand_by when: (modi = "bike" or modi = "pedestrian") and self.location overlaps self.the_target {
			if the_target = my_exit {
				is_outside <- true;
			}
			end_trip_time <- current_date; // save trip arrive time
			path_to_the_target <- nil;
			the_target <- nil;
			location <- any_location_in(self.building_target);
		}
		
	}
	
	state get_on initial: false {
		if modi = "car" {
			ask my_car  {
					self.passengers_on_board <- self.passengers_on_board + 1; // decrease car_passengers_on_board
					//do compute_path(graph: road_network, target: car_target); // calculate the path to the target
					
					// it looks like it improved it a lot > the problem seems to be that agent try to go to intersections that are not in the driving graph
					// clean network operator removed > do not seem to affect
					// check the intersections where they jump by writing it
					current_path <- compute_path(graph: road_network, target: self.car_target);
					if current_path = nil {
						do compute_path(graph: road_network, target: car_target); // calculate the path to the target
						if current_path = nil {
							location <- (driving_intersections closest_to self).location;
							current_path <- compute_path(graph: road_network, target: self.car_target);
						} 
						if current_path = nil {
							list<intersections> test <- (driving_intersections at_distance 500);
							loop i over: test {
								location <- i.location;
								current_path <- compute_path(graph: road_network, target: self.car_target);
								if current_path != nil { break; }	
							}
						}
					}
					
					capture myself as:car_passengers ; // agent is captured as car_passenger
					is_outside <- false;
					state <- "driving";
				}
		} else if modi = "public_transport" {
			at_bus_stop <- true;
			color <- #darkred;
		}
	}
	
	//// this one must be improved > not working for commuters 
	state get_off_and_walk initial: false {
		if start_reach_destination = nil and (modi = 'public_transport' or modi = 'car'){
			start_reach_destination <- current_date;
		}
			speed <- walking_speed;
			do goto target:self.the_target on:pedestrian_network;			
		
		
		// modified von self.location overlaps self.the_target
		transition to:stand_by when: self.location overlaps self.the_target {
			end_reach_destination <- current_date;
			if (the_target = my_exit) {
				is_outside <- true;
			}
			end_trip_time <- current_date; // save trip arrive time
			path_to_the_target <- nil;
			the_target <- nil;
			location <- any_location_in(self.building_target);
		}
	}
					/////////////////////////////////////
					////// SWITCH PUBLIC TRANSPORT //////
					/////////////////////////////////////

	// this action will be performed by agents who arrive at their get_off_stop, want to leave the area but the get_off_stop is not equal to thei exit
	// in that case they will switch the closest tram stop and take the corrisponding tram
	// that is particularly the case for the bus lines stopping at the last stop of the tram lines
	action switch_to_outgoing_pt {
		// first it looks if he can reach the exit from the closest stop
		self.switching_bus <- true;
		intersections closest_intersec <- intersections_closest_to_tram_stops at_distance walking_to_tram_tollerance closest_to(self);
		if (closest_intersec = nil) {closest_intersec <- intersections_closest_to_tram_stops closest_to(self);}
		my_get_on_stop <- closest_intersec;
		my_pt_line <- my_get_on_stop.lines_passing_through;
		if my_pt_line contains "tram_92a" or "tram_92b" {
				my_get_off_stop <- tram_exit;
		} else if my_pt_line contains "tram_96a" or "tram_96b" {
				my_get_off_stop <- tram_exit;
		}
		// in the other case it looks which is the stop closest to the exit and try to reach it
		if !(my_get_on_stop.lines_passing_through contains_any my_get_off_stop.lines_passing_through) {
			ask my_exit {
				intersections closest_intersec <- pt_stops at_distance walking_to_tram_tollerance closest_to self;
				if (closest_intersec = nil) {closest_intersec <- pt_stops closest_to self;}
				myself.my_get_off_stop <- closest_intersec;
			}
			intersections closest_intersec <- pt_stops where (each.lines_passing_through contains_any self.my_get_off_stop.lines_passing_through) at_distance walking_to_tram_tollerance closest_to(self);
			if (closest_intersec = nil) {closest_intersec <- pt_stops where (each.lines_passing_through contains_any self.my_get_off_stop.lines_passing_through) closest_to(self);}
			my_get_on_stop <- closest_intersec;	
		}
		
		// must be adapted to phase move and get_on
		modi <- "public_transport";
		path_to_the_target <- nil;
		the_target <-  self.my_get_on_stop ;
		state <- "move";
	}
	
	action switch_to_tram {
		self.switching_bus <- true;
		// case 1 > Agent is arrived at a stop served by tram
		if my_get_off_stop.lines_passing_through contains "tram_92b" or "tram_96b" {
			my_pt_line <- my_get_off_stop.lines_passing_through;
			my_get_on_stop <- my_get_off_stop;
			my_get_off_stop <- tram_exit; // it could also be intersections_closest_to_tram_stops_96b but they are the same
			state <- "get_on";
		} else {
			// case 2 > Agent need to walk in order to arrive to a stop served by the tram
			my_get_on_stop <- nil;
			my_get_on_stop <- intersections_closest_to_tram_stops at_distance walking_to_tram_tollerance closest_to(self);
			if (my_get_on_stop = nil) {my_get_on_stop <- intersections_closest_to_tram_stops closest_to(self);}
			my_get_off_stop <- tram_exit; // it could also be intersections_closest_to_tram_stops_96b but they are the same
			the_target <- my_get_on_stop;
			state <- "move";
		}
	}
	
	action normal_stop_decision {
		intersections closest_intersec;
			// first it evaluates if it is outside
			if is_outside = true {
				closest_intersec <- tram_exit;	// in that case it takes the tram_exit
			} else if is_outside = false { // if it is inside
				closest_intersec <- (intersections_closest_to_tram_stops at_distance walking_to_tram_tollerance) closest_to (self); // if it is close take the tram
				if (closest_intersec = nil) { // otherwise the closest bus stop
					closest_intersec <- (bus_stops at_distance walking_to_bus_tollerance) closest_to (self);
					if (closest_intersec = nil) {closest_intersec <- pt_stops closest_to (self);}					
				}
			}
			my_get_on_stop <- closest_intersec;
			// it considers the lines passing through
			ask my_get_on_stop {
				myself.my_pt_line <- self.lines_passing_through;
			}
			// in that case it must be differentiated between new line stops and normal stops
			if my_pt_line contains "new_bus_line" // if the choosen intersection contain the custom rdt bus line
				and not(my_pt_line contains "6") // and it doesn't contain a bus
				and not(my_pt_line contains "tram") { // or tram
				/// case rdt
					if will_drive_out = true { // if it will drive out, it should have exit = tram_exit and...
						my_get_off_stop <- nil; // the get off stop cannot be defined right now, it should be defined when he get on the bus, since probably multiple switch stations are possible
						my_exit <- tram_exit;
					} else if will_drive_out = false { // if the destination is inside the area it will look for the stop closest to the building target
					intersections closest_intersec;
					ask building_target {
						closest_intersec <- ((new_busa_stops) at_distance walking_to_bus_tollerance) closest_to (self);
						if closest_intersec = nil {closest_intersec <- new_busa_stops closest_to (self);}
						myself.my_get_off_stop <- closest_intersec;
					}
					switching_bus <- false;
					}
				} else if my_pt_line contains_any ['tram_92a','tram_92b','tram_96a','tram_96b']  {
					/// case not rdt but tram
					if will_drive_out = true {
						my_exit <- tram_exit;
						//	my_get_on_stop <- intersections_closest_to_tram_stops at_distance walking_to_tram_tollerance closest_to(self);
							//if my_get_on_stop = nil {
								//my_get_on_stop <-intersections_closest_to_tram_stops closest_to(self);
							//}
						my_get_off_stop <- my_exit;
					} else if will_drive_out = false {
						// in that case it looks for the get_off_stop closer to the building target and pick a get on stop correspondly
						my_get_on_stop <- nil;
						ask building_target {
							intersections closest_intersec <- ((intersections_closest_to_tram_stops) at_distance walking_to_tram_tollerance) closest_to (self);
							if (closest_intersec = nil) {closest_intersec <- (intersections_closest_to_tram_stops) closest_to (self);}
							myself.my_get_off_stop <- closest_intersec;
						}			
						// it considers the lines passing through
						ask my_get_off_stop {
							myself.my_pt_line <- lines_passing_through;
						}
						// if the choosen intersection contain the tram 92b than it looks for the closer tram 92b stop
						if my_pt_line contains "tram_92b" {
							my_get_on_stop <- intersections_closest_to_tram_stops_92 closest_to(self);
						}
						
						if my_get_on_stop = nil and my_pt_line contains "tram_96b" { // if the choosen intersection contain the tram 96b than it looks for the closer tram 92b stop
							my_get_on_stop <- intersections_closest_to_tram_stops_96 closest_to(self);
						}
						
						if my_get_on_stop = nil and my_pt_line contains "tram_92a" { // if the choosen intersection contain the tram 92a than it looks for the closer tram 92a stop
							my_get_on_stop <- intersections_closest_to_tram_stops_92 closest_to(self);
						}
						
						if my_get_on_stop = nil and my_pt_line contains "tram_96a" { // if the choosen intersection contain the tram 96a than it looks for the closer tram 96a stop
							my_get_on_stop <- intersections_closest_to_tram_stops_96 closest_to(self);
						}		
					}
				} else {
					// in that case it looks for the get_off_stop closer to the building target and pick a get on stop correspondly
					my_get_on_stop <- nil;
					if will_drive_out = true {
						my_exit <- bus_south_exit;
						my_get_off_stop <- my_exit;
					} else if will_drive_out = false {
					ask building_target {
							intersections closest_intersec <- ((bus_stops) at_distance walking_to_bus_tollerance) closest_to (self);
							if (closest_intersec = nil) {closest_intersec <- (intersections_closest_to_tram_stops) closest_to (self);}
							myself.my_get_off_stop <- closest_intersec;
						}	
					}		
						// it considers the lines passing through
						ask my_get_off_stop {
							myself.my_pt_line <- lines_passing_through;
						}
						
						if my_get_on_stop = nil and my_pt_line contains "bus_609a"{ // if the choosen intersection does not contain tram stops than it looks for the closer bus stop of the corresponding bus line
								my_get_on_stop <- bus609a_stops closest_to(self);
						}
						if my_pt_line contains "bus_609b" and my_get_on_stop = nil {
							my_get_on_stop <- bus609b_stops closest_to(self);
						}
						if my_pt_line contains "bus_612a" and my_get_on_stop = nil {
							my_get_on_stop <- bus612a_stops closest_to(self);
						}
						if my_pt_line contains "bus_612b" and my_get_on_stop = nil {
							my_get_on_stop <- bus612b_stops closest_to(self);
						}
						if my_pt_line contains "bus_614a" and my_get_on_stop = nil {
							my_get_on_stop <- bus614a_stops closest_to(self);
						}
						if my_pt_line contains "bus_614b" and my_get_on_stop = nil {
							my_get_on_stop <- bus614b_stops closest_to(self);
						}
						if my_pt_line contains "bus_638a" and my_get_on_stop = nil {
							my_get_on_stop <- bus638a_stops closest_to(self);
						}
						if my_pt_line contains "bus_638b" and my_get_on_stop = nil {
							my_get_on_stop <- bus638b_stops closest_to(self);
						}
						if my_pt_line contains "bus_650a" and my_get_on_stop = nil {
							my_get_on_stop <- bus650a_stops closest_to(self);
						}
						if my_pt_line contains "bus_650b" and my_get_on_stop = nil {
							my_get_on_stop <- bus650b_stops closest_to(self);
						}
						if my_pt_line contains "bus_692a" and my_get_on_stop = nil {
							my_get_on_stop <- bus692a_stops closest_to(self);
						}
						if my_pt_line contains "bus_692b" and my_get_on_stop = nil {
							my_get_on_stop <- bus692b_stops closest_to(self);
						}
						if my_pt_line contains "bus_697a" and my_get_on_stop = nil {
							my_get_on_stop <- bus697a_stops closest_to(self);
						}
						if my_pt_line contains "bus_697b" and my_get_on_stop = nil {
							my_get_on_stop <- bus697b_stops closest_to(self);
						}
						if my_pt_line contains "bus_698a" and my_get_on_stop = nil {
							my_get_on_stop <- bus698a_stops closest_to(self);
						}
						if my_pt_line contains "bus_698b" and my_get_on_stop = nil {
							my_get_on_stop <- bus698b_stops closest_to(self);
						}
				}
			// since it could be the case that my_get_on_stop equal my_get_off_stop (cause of proximity) in that case the agent will walk (same code as below for pedestrians)
			self.the_target <-  my_get_on_stop;
	}
	
	action drive_to_rdt_switching_station {
		write self.Personal_ID + " - " + drive_to_rdt_switching_station;
		will_drive_out <- false;
		intersections closest_intersec;
			// first it evaluates if it is outside
			if is_outside = true {
				closest_intersec <- tram_exit;	// in that case it takes the tram_exit
			} else if is_outside = false { // if it is inside
				closest_intersec <- (intersections_closest_to_tram_stops at_distance walking_to_tram_tollerance) closest_to (self); // if it is close take the tram
				if (closest_intersec = nil) { // otherwise the closest bus stop
					closest_intersec <- (bus_stops at_distance walking_to_bus_tollerance) closest_to (self);
					if (closest_intersec = nil) {closest_intersec <- pt_stops closest_to (self);}					
				}
			}
			my_get_on_stop <- closest_intersec;
			// it considers the lines passing through
			ask my_get_on_stop {
				myself.my_pt_line <- self.lines_passing_through;
			}
			// in that case it must be differentiated between new line stops and normal stops
			if my_pt_line contains "new_bus_line" // if the choosen intersection contain the custom rdt bus line
				and not(my_pt_line contains "6") // and it doesn't contain a bus
				and not(my_pt_line contains "tram") { // or tram
					ask my_living_place {
						myself.my_get_off_stop <- new_busa_stops closest_to self;
					}
				} else if my_pt_line contains_any ['tram_92a','tram_92b','tram_96a','tram_96b']  {
					my_get_off_stop <- tram2rdt_switching_stations where (each.lines_passing_through contains_any my_pt_line) closest_to self ;
					// for the case that my tram line is not tram2rdt_switching station
					if my_get_off_stop = nil {
						self.my_get_off_stop <- intersection_tram_lines_crossing_station;
					}	
					if my_get_off_stop = nil {
						ask building_target {
							myself.my_get_off_stop <- intersections_closest_to_tram_stops where (each.lines_passing_through contains_any myself.my_pt_line) closest_to self ;
						}
					}					
				} else {
					// in that case it looks for the get_off_stop closer to the building target and pick a get on stop correspondly
					my_get_off_stop <- one_of(bus2rdt_switching_stations);
				}
			// since it could be the case that my_get_on_stop equal my_get_off_stop (cause of proximity) in that case the agent will walk (same code as below for pedestrians)
			self.the_target <-  my_get_on_stop;
	}
	
	action call_rdt {
		self.color <- #white;
		self.at_bus_stop <- true;
		self.rdt_pick_up_candidate <- true;
		if length(rdt_bus) > 0 {
			if will_drive_out = true {
				ask rdt_bus where ((each.bus_target != nil) and
					(each.bus_target = my_get_on_stop) and
					(each.state = "driving") and
					(each.calling_agent = nil) and
					(length(each.members) < rdt_capacity) and
					(each.my_route_outward contains_any rdt2tram_switching_stations or
						each.my_route_outward contains_any rdt2bus_switching_stations)) {
					write "Rdt bus " + self + " has been called by agent " + myself.Personal_ID;
					state <- "on_call";
					on_hold_stop <- bus_target;
					add myself::myself.location to: to_be_picked_up;
				}
			} else if will_drive_out = false {
				ask rdt_bus where ((each.bus_target != nil) and
					(each.bus_target = my_get_on_stop) and
					(each.state = "driving") and
					(length(each.members) < rdt_capacity) and
					(each.my_route_outward contains my_get_off_stop) and
					(each.calling_agent = nil)) {
					write "Rdt bus " + self + " has been called by agent " + myself.Personal_ID;
					state <- "on_call";
					on_hold_stop <- bus_target;
					add myself::myself.location to: to_be_picked_up;
				}
			}
		}
	}

					///////////////////////////////////////////////
					// WALK OR CYCLE TO REACH THE WALKING TARGET //
					///////////////////////////////////////////////


	
	
	
	reflex waiting_at_stop_counter_1 when: at_bus_stop = true and n_of_vehicle_switch = 0 {
		waiting_time_in_sec <- waiting_time_in_sec + 1;
	}
	
	reflex waiting_at_stop_counter_2 when: at_bus_stop = true and n_of_vehicle_switch > 0 {
		waiting_time_in_sec2 <- waiting_time_in_sec2 + 1;
	}
	
	aspect base {
			draw square(50) color: color border: #white;
	}
}



	//////////////////////////////////
	// Definition of the experiment //
	//////////////////////////////////

experiment road_traffic type: gui {


    parameter "Load new bus line" category: "Infrastructures" var: include_new_bus_line init: true;
    parameter "scenario_name" category: "Output-Displays" var: scenario_name <- "short_route";
    // parameter "Percentage home service" category: "Demand" var: perc_pick_up_service init: 50 min: 0 max: 100 step: 1;
    parameter "people_df" category: "Output-Displays" var: people_df <- "people_2306" among: ["test_people3", "people_2306", "people_400_random"];
    parameter "Road visualization" category: "Output-Displays" var: display_switcher_roads <- "Open street map" among: ["Open street map", "Public transport","Road vehicle categories"];
    parameter "Building visualization" category: "Output-Displays" var: display_switcher_buildings <- "Typology" among: ["Typology", "Distance to bus stop", "Distance to pt stop", "Distance to tram stop", "Distance to shopping place"];

output {
		display city_display type: opengl draw_env: false background: rgb(61,72,73) {
			species block_to_eval aspect:base refresh: false;
			species living_building aspect: base refresh: true ;
			species educational_buildings aspect: base refresh: true ;
			species functional_buildings aspect: base refresh: true ;
			species blocks aspect:base refresh: true;
			species parking_areas aspect:base refresh: false;
			species road aspect: base refresh: true;
			//species parking_areas aspect: percentage_covered refresh: true; // on hold to spare computation
			//species road aspect: traffic_intensity refresh: true; // on hold to spare computation
			species intersections aspect: base refresh: true;
			species tram_lines aspect: base refresh: true;
			species tram_stops aspect: base refresh: true;
			species people aspect: base refresh: true;
			species car aspect: base refresh: true;
			species bus aspect: base refresh: true;
			species rdt_bus aspect: base refresh: true;
			species tram aspect: base refresh: true;
			species pt_manager aspect: base;
			species rdt_manager aspect: base;

		}	
	}
}
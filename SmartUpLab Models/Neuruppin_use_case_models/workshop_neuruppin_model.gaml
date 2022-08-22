/**
 * * Name: Workshop Neuruppin Use Case
 * * Annotation: The current model will not work since no data are public available. It is for documentation purpose only
*  
* Author: Diego Dametto

model neuruppin_parking_model


global  {

// input strings for settings and saving data
	string scenario_name <- '';
	string setting_name <- "";
    list<string> available_scenarios <- ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"];
	bool save_data;
// sql related variables
	string save_string;
	map<string,string> SELECTED_PARAMS <- LOCAL_PARAMS;
	map<string,string> LOCAL_PARAMS <- ['host'::'xxx', 'dbtype'::'xxx', 'database'::'xxx', 'port'::'xxx', 'user'::'xxx', 'passwd'::'xxx'];
	map<string,string> ONLINE_PARAMS <- ['host'::'xxx', 'dbtype'::'xxx', 'database'::'xxx', 'port'::'xxx', 'user'::'xxx', 'passwd'::'xxx'];
	
// it works but it is amazingly slow
	map<string,string> BOUNDS <- [	//'srid'::'32648', // optinal
	 								'host'::'xxx',
									'dbtype'::'xxx',
									'database'::'xxx',
									'port'::'xxx',
									'user'::'xxx',
									'passwd'::'xxx',
								  	'select'::'SELECT ST_AsEWKB(geom) as geom FROM arbeitsgebiet_epsb28533;' ];
//  environment related variables
	geometry shape <- envelope(BOUNDS);
		
// time related variables
	float step <- 600 #sec;
	date starting_date;
	string today;
	map<string,float> time_of_the_day;
	
//int neuruppin_altstadt_residents <- 5236;
	list<int> visitors_activity_times;
	list<int> resident_activity_times;
	map<string, list> visitors_activity_times_distrib;
	map<string, list> resident_activity_times_distrib;
	int n_outgoing_residents_per_day;
	int n_residents;
	float work_prob;
	float freet_prob;
	float work_prob_res;
// visitors related variables
	int n_incoming_agents_per_day;
	int reference_value_n_incoming_agents_per_day;
	int hvz_workers;
	map<string,float> worker_freetime_prob;

// attraction buildings	
	list<float> coef;
	map<string, float> attraction_weights_list;
	float max_attraction_coefficient;
	float min_attraction_coefficient;
// destination lists
	list<buildings> freetime_buildings;
	list<buildings> work_buildings;

// hotspots for special events
	list<buildings> hotspots;
	list<string> hotspots_choices <- ["Seepromenade", "Klosterkiche Sankt Trinitatis", "Kulturhaus", "Kulturkirche"];
	string hotspots_choice;
	int n_of_visitors_to_hotspot;
	int time_event;
	int event_duration;
    bool hotspot_event;

// distances parking to building
	int less_than_25 <- 0;
	int less_than_50 <- 0;
	int less_than_100 <- 0;
	int less_than_150 <- 0;
	int more_than_150 <- 0;
	
// interface interactions: moving parking places
	list<parking_places> moved_agents ;
	bool modify_parking_places;
	point target;
	geometry pointing_zone <- circle(6);
	bool can_drop;
	bool parking_places_modified;
	
// interface interactions: erase parking zones
	bool erase_parking_zones;
// interface interactions: opening the river
	bool river_visible;
	list<parking_places> to_be_erased;
// interface carfree areas
	bool modify_roads;
	point target_roads;
	list<roads> selected_roads;
	bool roads_modified;
// park and ride
	int n_park_and_ride;
	int allowed_stay_park_and_ride;
	string park_and_ride_location;
	bool park_and_ride_station;
	point target_park_and_ride;
	float prob_using_park_and_ride;
	bool park_and_ride_created;
// extension parking place Töllerstrasse
	int n_extension_tollerstrasse;
	bool extension_tollerstrasse;
// demolition parking place Bahnhof Rheinsberger Tor
	bool demolition_train_station;
// querparkn Schinkelstrasse
	bool parking_places_rotation;
// colors for the background
	map<string,rgb> background_colors <- ["Medium grey"::rgb(177,177,177), "Dark grey"::rgb(61,72,73), "Light grey":: rgb(181, 189, 183), "White":: rgb(255,255,255), "Black":: rgb(0,0,0), "Light green":: rgb(127, 176, 139)];
	rgb background_color;
// colors for the legend
	map<string,rgb> legend_color <- ["Gebäude"::rgb(60, 174, 163), "Wohngebäude"::rgb(23, 63, 95), "Anziehungspunkt"::#red, "Veranstaltungsort"::#pink,
																'Mischnutzung'::rgb(32, 99, 155), "Bewohnerparkplatz":: #fuchsia,
																"1 Std. parken"::rgb(229,215,231), "2 Std. parken"::rgb(187,149,193), 
																"3 Std. parken"::rgb(150,112,156), "4 Std. parken"::#darkorange, 
																"Parkenfrei"::#lightgreen, "Parkhaus & Garage"::#darkgreen,
																"Belegter Parkplatz"::#black];
	string QUERY_parking_places_2 <- "SELECT gid, zonen, layer, switch, ST_AsEWKB(geom) as geom FROM parkplaetze_poly_epsg25833
																	WHERE switch = 1;";
	// Define the queries
	string QUERY_living_buildings <- "SELECT gid, funktion, idstatbz, ST_AsEWKB(geom) as geom FROM buildings_poly_epsg25833 WHERE funktion = 'Wohnhaus' OR
															funktion = 'Wohngebäude mit Gewerbe und Industrie' OR
															funktion = 'Wohngebäude mit Handel und Dienstleistungen' OR
															funktion = 'Wohngebäude' OR
															funktion = 'Wohn- und Geschäftsgebäude' OR
															funktion = 'Gebäude für Gewerbe und Industrie mit Wohnen';";
	// mixed buildings as Wohngebäude mit Gewerbe und Industrie are loaded twice in both species
	string QUERY_buildings <- "SELECT gid, funktion, ___id, area, ST_AsEWKB(geom) as geom FROM buildings_poly_epsg25833 WHERE funktion != 'Wohnhaus' AND
															funktion != 'Wohnheim' AND
															funktion != 'Wohngebäude';";
	

	string QUERY_parking_places <- "SELECT gid, zonen, layer, switch, ST_AsEWKB(geom) as geom FROM parkplaetze_poly_epsg25833 WHERE (switch != 1 OR switch IS NULL)";
	
	string QUERY_roads <- "SELECT gid, fclass, name, ST_AsEWKB(geom) as geom FROM roads_epsg25833;";
	string QUERY_water_line <- "SELECT ST_AsEWKB(geom) as geom FROM water_line_epsg25833;";
	string QUERY_water_areas <- "SELECT ST_AsEWKB(geom) as geom FROM water_poly_epsg25833;";
	string QUERY_park_and_ride <- "SELECT gid, ST_AsEWKB(geom) as geom FROM park_and_ride_epsg28533;";

													
	matrix<string> save_data_matrix <- {1,8} matrix_with "0";
	list<int> cycles;
	list<string> osm_ids;
	list<int> hours_of_parking;
	list<int> mins_of_parking;
	list<int> distance_to_goals;
	list<bool> occupied_list;
	list<string> occupied_by_list;
	list<string> building_target;
	
	////////////////////
	// Initialisation //
	////////////////////
	
	init {
		
		///// CREATE DB ACCESSOR
		create (agentDB) {
					do setParameter(params: SELECTED_PARAMS);
					do connect (params: SELECTED_PARAMS);
		}

		///// CREATE AGENTS /////
		

		// run queries	
		create DB_accessor {
			
			// BUILDINGS
			create buildings from: select(SELECTED_PARAMS, QUERY_buildings)
							 with:[id::"gid",
							 		type::"funktion",
				 					poi_id::"___id",
				 					area::"area",
									shape::"geom"];
			
			// hotspots
			// Kirche gid = 158 and 157; Seepromenade gid = 2570; Kulturhaus gid = 2331, Kirche Seepromenade gid = 41
			hotspots <- buildings where (each.id = "158" or each.id = "157" or each.id = "2570" or each.id = "2331" or each.id = "41");
			
			// freetime -> following list
			freetime_buildings <- buildings where (each.type = "Promenade" or
																				each.type = "Kapelle" or
																				each.type = "Gebäude für Bildung und Forschung" or
																				each.type = "Gericht" or
																				each.type = "Freizeit- und Vergnügungsstätte" or
																				each.type = "Veranstaltungsgebäude" or
																				each.type = "Gebäude für kulturelle Zwecke" or
																				each.type = "Sport-, Turnhalle" or
																				each.type = "Gebäude für religiöse Zwecke" or
																				each.type = "Kreditinstitut" or
																				each.type = "Hallenbad" or
																				each.type = "Museum" or
																				each.type = "Gebäude für soziale Zwecke" or
																				each.type = "Post" or
																				each.type = "Geschäftsgebäude" or
																				each.type = "Kaufhaus" or
																				each.type = "Kirche" or
																				each.type = "Gebäude für Bewirtung" or
																				each.type = "Hotel, Motel, Pension" or
																				each.type = "Betriebsgebäude für Schiffsverkehr" or
																				each.type = "Verwaltungsgebäude" or
																				each.type = "Gaststätte, Restaurant" or
																				each.type = "Gebäude zur Freizeitgestaltung" or
																				each.type = "Gebäude für Gesundheitswesen" or
																				each.type = "Wohngebäude mit Handel und Dienstleistungen" or
																				each.type = "Gebäude für Handel und Dienstleistungen" or
																				each.type = "Gebäude für Wirtschaft oder Gewerbe");

			// work -> following list
			work_buildings <- buildings where (each.type = "Gericht" or
																				each.type = "Produktionsgebäude" or
																				each.type = "Gebäude für soziale Zwecke" or
																				each.type = "Feuerwehr" or
																				each.type = "Gebäude für Gewerbe und Industrie mit Wohnen" or
																				each.type = "Geschäftsgebäude" or
																				each.type = "Kaufhaus" or
																				each.type = "Fabrik" or
																				each.type = "Gebäude für Gewerbe und Industrie mit Wohnen" or
																				each.type = "Allgemein bildende Schule" or
																				each.type = "Hotel, Motel, Pension" or
																				each.type = "Verwaltungsgebäude" or
																				each.type = "Bürogebäude" or
																				each.type = "Gaststätte, Restaurant" or
																				each.type = "Gebäude für Gesundheitswesen" or
																				each.type = "Gebäude zur Freizeitgestaltung" or
																				each.type = "Wohngebäude mit Handel und Dienstleistungen" or
																				each.type = "Lagerhalle, Lagerschuppen, Lagerhaus" or
																				each.type = "Gebäude für Handel und Dienstleistungen" or
																				each.type = "Wohngebäude mit Gewerbe und Industrie" or
																				each.type = "Gebäude für Wirtschaft oder Gewerbe" or
																				each.type = "Wohn- und Geschäftsgebäude" or
																				each.type = "Werkstatt");
			
			create living_buildings from: select(SELECTED_PARAMS, QUERY_living_buildings)
				 with:[id::"gid",
				 		type::"funktion",
				 		block::"idstatbz",
						shape::"geom"];
									
			// PARKING PLACES
			create parking_places from: select(SELECTED_PARAMS, QUERY_parking_places)
							 with:[id::"gid",
									shape::"geom",
									parking_typology::"zonen",
									switch::"switch",
									zone::'layer'] {
									if parking_typology = "reines Bewohnerparken" or parking_typology = 'Garage'  {
										resident_only <- true;
										if parking_typology = "reines Bewohnerparken" {
											predefined_color <-  #fuchsia;
										} else if parking_typology = 'Garage' {
											predefined_color <-  #darkgreen;
										}
									} else {
										resident_only <- false;
									}
									if resident_only = true {
										allowed_stay_duration <- 999;
									} else {
										if parking_typology = '1 Stunde' {
											allowed_stay_duration <- 1;
											predefined_color <-  rgb(229,215,231);
										} else if parking_typology = '2 Stunden' {
											allowed_stay_duration <- 2;
											predefined_color <-  rgb(187,149,193);
										}  else if parking_typology = '3 Stunden' {
											allowed_stay_duration <- 3;
											predefined_color <-  rgb(150,112,156);
										} else if parking_typology = '4 Stunden' {
											allowed_stay_duration <- 4;
											predefined_color <-  #darkorange;
										} else if parking_typology = 'Tiefgarage' or parking_typology = 'Parkhaus' or parking_typology = 'Parken frei' {
											allowed_stay_duration <- 999;
											if parking_typology = 'Parken frei' {
												predefined_color <-  #lightgreen;
											} else {
												predefined_color <-  #darkgreen;
											}	
										} 
									}
									color_parking_places <- predefined_color;
								}
			// WATER STREAM
			create water_line from: select(SELECTED_PARAMS, QUERY_water_line)
							 with:[shape::"geom"];
							 
			// WATER AREAS
			create water_area from: select(SELECTED_PARAMS, QUERY_water_areas)
							 with:[shape::"geom"];
							 
			// PARK AND RIDE AREAS
			create park_and_ride_areas from: select(SELECTED_PARAMS, QUERY_park_and_ride)
							 with:[id::"gid",
									shape::"geom"];
			
			// ROADS
			create roads from: select(SELECTED_PARAMS, QUERY_roads)
							 with:[id::"gid",
									type ::"fclass",
									street_name::"name",
									shape::"geom"];
									

			
			
			// define the parking zone for each building
			ask living_buildings {
				parking_places temp	<- parking_places at_distance 500 closest_to self;
				if temp = nil {
					temp	<- parking_places closest_to self;
				}
				ask temp {
					myself.parking_zone <- zone;
				}
			}
			ask buildings {
				parking_places temp	<- parking_places at_distance 500 closest_to self;
				if temp = nil {
					temp	<- parking_places closest_to self;
				}
				ask temp {
					myself.parking_zone <- zone;
				}
			}
		
		
		// create a distribution for inspecting traffic flow for visitors
		list<int> start_parking_times <- visitors collect (each.start_parking_time);
		list<int> end_parking_times <- visitors collect (each.end_parking_time);
		visitors_activity_times <- 	start_parking_times +end_parking_times ;
		//add return_times to: resident_activity_times;
		visitors_activity_times_distrib <- distribution_of(visitors_activity_times, 18, 6, 24);			
			
		
		// create a distribution for inspecting traffic flow for resident
		list<int> leaving_times <- residents collect (each.leaving_time);
		list<int> return_times <- residents collect (each.return_time);
		resident_activity_times <- 	leaving_times +return_times ;
		//add return_times to: resident_activity_times;
		resident_activity_times_distrib <- distribution_of(resident_activity_times, 18, 6, 24);						
		}
	}
	
	// reflex to stop the simulation
	reflex end_simulation when: current_date.hour = 0 {
		ask agentDB {
			loop index from: 0 to: length(cycles) -1 {
				do insert into: "results_" + save_string + "_parking_places_by_hour" 
				columns: ["cycle", "osm_id", "hour", "minute", "distance_to_goal", "occupied", "occupied_by", "building_target"]
				 values: [cycles[index], osm_ids[index], hours_of_parking[index], mins_of_parking[index], distance_to_goals[index], occupied_list[index], occupied_by_list[index], building_target[index]];
			}
		}
		if parking_places_modified = true {
			ask agentDB {
					do executeUpdate (updateComm: "CREATE TABLE parking_places_" + save_string + "_modified"
						    + "(id INTEGER,"
							+ "parking_typology VARCHAR,"
							+ "geom GEOMETRY);");
			}
			ask parking_places {
				ask agentDB {
					do insert into: "parking_places_" + save_string + "_modified"
							  columns: ["id", "parking_typology", "geom"]
							  values: [myself.id, myself.parking_typology,myself.shape];
				}
			}
			save ("results_" + save_string + "_parking_places_by_hour") to: "save_string.txt" type: "text" rewrite: true;
			save ("parking_places_" + save_string + "_modified" ) to: "save_parking_string.txt" type: "text" rewrite: true;	
		} else {
			save ("results_" + save_string + "_parking_places_by_hour" ) to: "save_string.txt" type: "text" rewrite: true;	
		}
		write command("Python save_data.py &");
		write "Die Daten wurden erfolgreich gespeichert";
        do pause;
    }
    
    // interface interaction: moving parking places
	action kill {
		if modify_parking_places = true {
			ask moved_agents {
				do die;
			}
			moved_agents <- list<parking_places>([]);
		}
	}
	
	action duplicate {
		if modify_parking_places = true {
			geometry available_space <- (pointing_zone at_location target) - (union(moved_agents) + 10);
			ask first(moved_agents) {
					create parking_places number: 1 {
						color_parking_places <- myself.predefined_color;
						zone  <- myself.zone;
						occupied <- false;
						resident_only <- myself.resident_only;
						allowed_stay_duration <- myself.allowed_stay_duration;
						parking_typology <- parking_typology;
						difference <- { 0, 0 };
						color <- # burlywood;
						location <- myself.location + {12,12};
						shape <- myself.shape;
					}
			} 
		}
	}
	
	// this action is used for modiying roads and parking places
	action click {
		if modify_parking_places = true {
			if (empty(moved_agents)) {
				list<parking_places> selected_agents <- parking_places inside (pointing_zone at_location #user_location);
				moved_agents <- selected_agents;
				ask selected_agents {
					difference <- #user_location - location;
					color <- # olive;
				}
			} else if (can_drop) {
				ask moved_agents {
					color <- # burlywood;
				}
				moved_agents <- list<parking_places>([]);
			}
		} else if modify_roads = true { // interface interaction: carfree street
			if (!empty(selected_roads)) {
				ask selected_roads {
					color_roads <- #darkgreen;
					list<parking_places> parking_places_in_autofree_area <- parking_places at_distance 25;
					ask parking_places_in_autofree_area {
						do die;
					}
				}	
			}
		} else if park_and_ride_station = true { // interface interaction: create park and ride
			if (!empty(selected_roads)) {
				ask first(selected_roads) {
					create park_and_ride_stop number: 1{
						id <- length(park_and_ride_stop);
						location <- #user_location;
					}
					string display_name;
					if self.street_name != nil {
						display_name <- self.street_name;	
					} else {
						display_name <- (roads where (each.street_name != nil) at_distance 200 closest_to self).street_name;
						// in case distance operator failed
						if display_name = nil {
							display_name <- (roads where (each.street_name != nil) closest_to self).street_name;
						}
					}
					write "#############################################################";
					write "Eine Park & Ride Haltestelle wurde in der bzw. in der Nähe von der " + display_name + " gesetzt";
					write "#############################################################";
				}	
			}
		}
	}

	// this action is used for modiying roads and parking places
	action move	 {
		if modify_parking_places = true {
			can_drop <- true;
			target <- #user_location;
			list<parking_places> other_agents <- (parking_places inside (pointing_zone at_location #user_location)) - moved_agents;
			geometry pos_occupied <-  geometry(other_agents);
			ask moved_agents	{
				location <- #user_location - difference;
				if (pos_occupied intersects self) {
					color <- # red;
					can_drop <- false;
				} else {
					color <- # olive;
				}	
			}
		} else if modify_roads = true { // interface interaction: carfree street
			target_roads <- #user_location;
			selected_roads <- (roads overlapping (pointing_zone at_location #user_location));
		} else if park_and_ride_station = true { // interface interaction: create park and ride
			target_park_and_ride <- #user_location;
			selected_roads <- (roads overlapping (pointing_zone at_location #user_location));
		}
	}
	// interface > create park and ride
	action park_and_ride {
		write "#############################################################";
		write "Ein Park & Ride Parkplatz mit " + n_park_and_ride + " Stellplätze wurde in " + park_and_ride_location + " generiert";
		write "Die erlaubte Aufenthaltsdauer beträgt " + allowed_stay_park_and_ride + " Stunden";
		write "#############################################################";
		park_and_ride_areas my_spot;
		int incremental <- 0;
		list<geometry> available_spots;
     	 create parking_places number: n_park_and_ride {
			shape<- rectangle(5#m,3#m);
			allowed_stay_duration<- allowed_stay_park_and_ride;
			zone <- "park & ride";
			// define parking typology and color from duration
			if allowed_stay_duration = 1 {
				parking_typology <- "1 Stunde";
				predefined_color <-  rgb(229,215,231);
			} else if allowed_stay_duration = 2 {
				parking_typology <- "2 Stunden";
				predefined_color <-  rgb(187,149,193);
			} else if allowed_stay_duration = 3 {
				parking_typology <- "3 Stunden";
				predefined_color <-  rgb(150,112,156);
			} else if allowed_stay_duration =4 {
				parking_typology <- "4 Stunden";
				predefined_color <-  #darkorange;
			} else if allowed_stay_duration > 4 {
				parking_typology <- "Parken frei";
				predefined_color <-  #lightgreen;
			}
			color_parking_places <- predefined_color;
			// define location
	     	 if park_and_ride_location = "Nord-West" {
	     	 		my_spot <- first(park_and_ride_areas where (each.id = 1));
	     	 		available_spots <- to_rectangles(my_spot, 20,20);
	     	 		location <- (available_spots[incremental]).location;
	     	 		remove available_spots[incremental] from: available_spots;
	     	 		ask my_spot {
	     	 			color_park_and_ride <- #darkred;
	     	 		}
	     	 		incremental <- incremental + 1;
			} else if park_and_ride_location = "Nord-Ost" {
	     	 		my_spot <- first(park_and_ride_areas where (each.id = 2));
	     	 		available_spots <- to_rectangles(my_spot, 20,20);
	     	 		location <- (available_spots[incremental]).location;
	     	 		remove available_spots[incremental] from: available_spots;
	     	 		ask my_spot {
	     	 			color_park_and_ride <- #darkred;
	     	 		}
	     	 		incremental <- incremental + 1;
			} if park_and_ride_location = "Sud-West" {
     	 		my_spot <- first(park_and_ride_areas where (each.id = 3));
     	 		available_spots <- to_rectangles(my_spot, 20,20);
     	 		location <- (available_spots[incremental]).location;
     	 		remove available_spots[incremental] from: available_spots;
     	 		ask my_spot {
     	 			color_park_and_ride <- #darkred;
     	 		}
     	 		incremental <- incremental + 1;
			}
		}
	}
	// interface > create park places in der Töllerstrasse
	action extension_parking_place {
		write "#############################################################";
		write "Der Parkplatz in der Töllerstrasse wird um " + n_extension_tollerstrasse + " Stellplätze erweitert";
		write "#############################################################";
		park_and_ride_areas my_spot;
		int incremental <- 0;
		list<geometry> available_spots;
     	 create parking_places number: n_extension_tollerstrasse {
			shape<- rectangle(5#m,3#m);
			parking_typology <- "Parken frei";
			allowed_stay_duration<- 4;
			predefined_color <-  #lightgreen;
			color_parking_places <- predefined_color;
			my_spot <- first(park_and_ride_areas where (each.id = 4));
 	 		available_spots <- to_rectangles(my_spot, 10,10);
 	 		location <- (available_spots[incremental]).location;
 	 		remove available_spots[incremental] from: available_spots;
 	 		incremental <- incremental + 1;
 	 		ask parking_places at_distance 200 closest_to self {
 	 			myself.zone <- self.zone;
 	 		}
		}
	}
	// interface > demolition parking places at the train statation Rheinsberger Tor
	action demolition_parking_place {
		write "############################################";
		write "Der Parkplätze am Rheinsberger Tor werden zurückgebaut";
		write "############################################";
		ask park_and_ride_areas where (each.id = 5) {
			ask parking_places overlapping self {
				do die;
			} 
		}
	}
	// interface > rotate parking places in the Schinkelstrasse
	action rotate_parking_place {
		write "##################################################################";
		write "Querparken in der Schinkelstrasse ermöglichen und 30 zusätzliche Parkplätze gewinnen";
		write "##################################################################";
		ask park_and_ride_areas where (each.id = 6) {
			ask parking_places overlapping self {
				do die;
			} 
		}
		int incremental <- 1;
		ask DB_accessor {
			
			
			create parking_places from: select(SELECTED_PARAMS, QUERY_parking_places_2)
							 with:[id::'gid',
							 		shape::"geom",
									parking_typology::"zonen",
									switch::"switch",
									zone::'layer'] {
									incremental <- incremental + 1;
									if parking_typology = "reines Bewohnerparken" or parking_typology = 'Garage'  {
										resident_only <- true;
										if parking_typology = "reines Bewohnerparken" {
											predefined_color <-  #fuchsia;
										} else if parking_typology = 'Garage' {
											predefined_color <-  #darkgreen;
										}
									} else {
										resident_only <- false;
									}
									if resident_only = true {
										allowed_stay_duration <- 999;
									} else {
										if parking_typology = '1 Stunde' {
											allowed_stay_duration <- 1;
											predefined_color <-  rgb(229,215,231);
										} else if parking_typology = '2 Stunden' {
											allowed_stay_duration <- 2;
											predefined_color <-  rgb(187,149,193);
										}  else if parking_typology = '3 Stunden' {
											allowed_stay_duration <- 3;
											predefined_color <-  rgb(150,112,156);
										} else if parking_typology = '4 Stunden' {
											allowed_stay_duration <- 4;
											predefined_color <-  #darkorange;
										} else if parking_typology = 'Tiefgarage' or parking_typology = 'Parkhaus' or parking_typology = 'Parken frei' {
											allowed_stay_duration <- 999;
											if parking_typology = 'Parken frei' {
												predefined_color <-  #lightgreen;
											} else {
												predefined_color <-  #darkgreen;
											}	
										} 
									}
									color_parking_places <- predefined_color;
								}
		}
	}
}

	///////////////////////////
	// Definition of species //
	///////////////////////////



// DB_accessor handle the database
species agentDB parent: AgentDB {  
	// individuals should be created only after parameters are defined
	action create_humans {
		ask DB_accessor {
			do define_settings;
		}
			///// CREATE A RESULT DF IN POSTGRES
			// save parking data
			if save_data = true {
				save_string <- lower_case(setting_name + "_" + scenario_name);
					do executeUpdate (updateComm: "DROP TABLE IF EXISTS results_" + save_string + "_parking_places_by_hour");
					do executeUpdate (updateComm: "CREATE TABLE results_" + save_string + "_parking_places_by_hour"
						    + "(cycle INTEGER,"
							+ "osm_id VARCHAR,"
							+ "hour INTEGER,"
							+ "minute INTEGER,"
							+ "occupied BOOL,"
							+ "occupied_by VARCHAR,"
							+ "distance_to_goal INTEGER,"
							+ "building_target VARCHAR);");
 				  do executeUpdate (updateComm: "CREATE TABLE IF NOT EXISTS overview_simulations"
 				  			+ "(setting_name VARCHAR,"
							+ "scenario_name VARCHAR,"  
							+ "hotspot_event BOOL,"
							+ "hotspots_choice VARCHAR,"
							+ "event_duration INTEGER,"
							+ "event_time INTEGER," 
							+ "n_incoming_agents_per_day INTEGER," 
							+ "n_residents INTEGER,"
							+ "river_visible BOOL,"
							+ "extension_tollerstrasse BOOL,"
							+ "demolition_parking_train_station BOOL,"
							+ "parking_places_rotation BOOL,"
							+ "erase_parking_zones BOOL,"
							+ "roads_modified BOOL,"
							+ "parking_places_modified BOOL,"
							+ "park_and_ride_created BOOL,"
							+ "n_park_and_ride INTEGER,"
							+ "park_and_ride_location VARCHAR);");
				} 
		ask DB_accessor {
			// VISITORS
			// the n of visitors to be created must be adjusted > currently is based on the verkehrszählungen
			create visitors number: n_incoming_agents_per_day {
				
				state <- "standby";
				// each visitors correspond to one specific target_group_category which defines its length_of_stay and times
				target_group_category <- rnd_choice(worker_freetime_prob); 
				// the following categories should be defined more specifically
				if target_group_category = "worker" {
					start_parking_time <- int(gauss(hvz_workers,1));
					length_of_stay <- int(gauss(7,1.5));
					end_parking_time <- start_parking_time + length_of_stay;	
				} else if target_group_category = "freetime" {
					string my_activity_time <- rnd_choice(time_of_the_day);
					if my_activity_time = "morning" {	
						start_parking_time <- int(gauss(11,2));	
					} else if my_activity_time = "afternoon" {
						start_parking_time <- int(gauss(15,3));	
					} else if my_activity_time = "evening" {
						start_parking_time <- int(gauss(20,1));
					}
					//adjust for irrealistic times
					if start_parking_time < 9 {
						start_parking_time <- one_of(9,10,11);
					}
					if start_parking_time > 22 {
						start_parking_time <- one_of(19,20,21);
					}			
					// define a random length of absence
					length_of_stay <- rnd(1,2);
					// calculate the return time
					end_parking_time <- start_parking_time + length_of_stay;
					//adjust for irrealistic times
					if end_parking_time > 23 {
						end_parking_time <- 23;
					}	
				}
				if end_parking_time != nil {
					end_parking_minute <- one_of(0,10,20,30,40,50);
				}
				if start_parking_time != nil {
					start_parking_minute <- one_of(0,10,20,30,40,50);
				}
			}
			
			if hotspot_event = true {
				do hotspot_event_creation;
			}
			// RESIDENTS
			string QUERY_people <- "SELECT block, age_class, hh_dim
													FROM neuruppin_altstadt_adult_population
													ORDER BY RANDOM()
													LIMIT " + string(n_residents) + ";";
			// the n of residents to be created must be adjusted > Option 1) Perc_residents with car must be related to only 18 to 70 yrs old; Option 2) Data about pkw in the altstadt are available
			create residents from: select(SELECTED_PARAMS, QUERY_people)
									 with:[ //location::'"{" + "location.x" +","+ "location.y" + "," + "location.z" + "}"', 
									 	block::"block",
									 	age_class::"age_class",
									 	hh_dim:: "hh_dim"]
				{
				// each individual will live in a building in its own block
				my_living_place <- one_of(living_buildings where (each.block = self.block)); //
				if my_living_place = nil {
					my_living_place <- one_of(living_buildings);
				}
				state <- "parking";
				float temp_not_work_prob_res <- 1 - work_prob_res;
				// definition of leaving time, return time and length of absence following the target groups
				// reference for traffic flows: https://publications.rwth-aachen.de/record/805453/files/805453.pdf
				if current_date.day >= 6 {
					target_group_category <- rnd_choice(['working_inhabitant'::work_prob_res, 'not_working_inhabitant'::temp_not_work_prob_res]);
				} else if current_date.day < 6 {
					if age_class = "75+" or age_class = "65-to-74" {
						target_group_category <- 'not_working_inhabitant';
					} else {
						target_group_category <- rnd_choice(['working_inhabitant'::work_prob_res, 'not_working_inhabitant'::temp_not_work_prob_res]);
					}
				}
				if target_group_category = "not_working_inhabitant" {
					// a random decision whether not_working_inhabitants have their activity in the morning or afternoon
					string my_activity_time <- rnd_choice(time_of_the_day);
					if my_activity_time = "morning" {	
						leaving_time <- int(gauss(11,2));					
					} else if my_activity_time = "afternoon" {
						leaving_time <- int(gauss(15,3));				
					}
					// define a random length of absence
					length_of_absence <- rnd(1,5);
					// calculate the return time
					return_time <- leaving_time + length_of_absence;	
				} else if target_group_category = "working_inhabitant" {
					leaving_time <- int(gauss(hvz_workers,1));
					length_of_absence <- int(gauss(9,1.5));
					return_time <- leaving_time + length_of_absence;				
				}
				if leaving_time != nil {
					leaving_minute <- one_of(0,10,20,30,40,50);
				}
				if return_time != nil {
					return_minute <- one_of(0,10,20,30,40,50);
				}
				// based on my_living_place the closest parking_place that is not occupied and has an allowed_stay_duration longer than 4 hrs or that it is reserved for residents is selected
				ask my_living_place {
					myself.my_parking_place <- parking_places where (each.occupied = false and  (each.zone = self.parking_zone or each.zone = 'ohne Anwohnerkarte ohne Parkscheibe')) at_distance 200 closest_to (self) ; // select the parking place
				}
				// in case with the at_distance operator nothing was found
				if my_parking_place = nil {
						ask my_living_place {
							myself.my_parking_place <- parking_places where (each.occupied = false and (each.zone = self.parking_zone or each.zone = 'ohne Anwohnerkarte ohne Parkscheibe')) closest_to (self) ; // select the parking place
						}
				}
				// if the visiting car as found a parking place, it locate itself there and change my_parking_place's attributes
				if my_parking_place != nil {
						location <- my_parking_place.location;
						int dist;
						dist <- self distance_to my_living_place;
						ask my_parking_place {
							self.occupied <- true;
							self.color_parking_places <- #black;
							self.occupied_by <- myself.target_group_category;
							self.distance_to_goal <- dist;
							self.target_of_parking <- myself.my_living_place.id;
							do save_parking_data;
						}
						//add dist to: dist2building;
						if dist < 25 {
							less_than_25 <- less_than_25 + 1;
						} else if dist < 50 {
							less_than_50 <- less_than_50 + 1;
						} else if dist < 100 {
							less_than_100 <- less_than_100 + 1;
						} else if dist < 150 {
							less_than_150 <- less_than_150 + 1;
						} else {
							more_than_150 <- more_than_150 + 1;
						}
				} else {
					// it must be defined a strategy
					write "Resident: " + self + " cannot find a parkplace";
					//do die;
				}
			}
			
			do declare_settings;
		}
		
		if save_data {
		    // adjust data for the case that park and ride was or was not created
		    int temp_n_park_and_ride;
		    string temp_park_and_ride_location;
		    if park_and_ride_created = true {
       			temp_n_park_and_ride <- n_park_and_ride;
       			temp_park_and_ride_location <- park_and_ride_location;
       		} else {
       			temp_n_park_and_ride <- 0;
       			temp_park_and_ride_location <- nil;
       		}
       		 // adjust data for the case that the hotspot was or was not created
       		string temp_hotspot_choice;
       		int temp_event_duration;
       		int temp_time_event;
       		if hotspot_event = true {
       			temp_hotspot_choice <- hotspots_choice;
       			temp_event_duration <- event_duration;
       			temp_time_event <- time_event;
       		} else {
       			temp_hotspot_choice <- nil;
       			temp_event_duration <- 0;
       			temp_time_event <- 0;
       		}
			do insert into: "overview_simulations"
							columns: ["setting_name", "scenario_name", "hotspot_event", "hotspots_choice", "event_duration", "event_time", "n_incoming_agents_per_day", "n_residents",
       						"river_visible", "extension_tollerstrasse", "demolition_parking_train_station", "parking_places_rotation",
       						"erase_parking_zones",  "roads_modified", "parking_places_modified", "park_and_ride_created", "n_park_and_ride", "park_and_ride_location"]
       						 values: [setting_name, scenario_name, hotspot_event, temp_hotspot_choice, temp_event_duration, temp_time_event, n_incoming_agents_per_day, n_residents,
       						river_visible, extension_tollerstrasse, demolition_train_station, parking_places_rotation,
       						erase_parking_zones, roads_modified, parking_places_modified, park_and_ride_created, temp_n_park_and_ride, temp_park_and_ride_location];
		} 
	}
} 

species DB_accessor skills: [SQLSKILL] {
	reflex create_poi_list_this_hous when: current_date.minute = 0 {
		// first the hour must be translated in the corresponding column
		string test <- current_date.hour;
		string col_for_query <- "hour_" + string(test);
		// the string for the query must be dynamically adjusted and transformed in a map
		string QUERY_poi_times <- "SELECT id, " + col_for_query + " FROM poi_times WHERE day = '" + today + "';";
		list<list> t <- list<list> (select(SELECTED_PARAMS, QUERY_poi_times));
		matrix<string> t_matrix <- transpose(matrix (t[2])); // {67,26};
		attraction_weights_list <- map(t_matrix);
	
		// Define max of attraction_coefficient for calculating color
		max_attraction_coefficient <-  max(attraction_weights_list);
		min_attraction_coefficient <-  min(attraction_weights_list);
		float sorted <- min(attraction_weights_list where (each > 0));
		if max_attraction_coefficient = 0 {
			max_attraction_coefficient <- 1;
		}
		// update the attraction coeffient of the buildings that have a poi_id and calculate a weighted attraction coefficient based on the area
		ask buildings where (each.poi_id != nil) {
			loop i over: attraction_weights_list.keys {
				if self.poi_id = i {
					self.attraction_coefficient <- attraction_weights_list[i];
					self.attraction_coefficient <- attraction_coefficient * area;
				}
			}
			ask freetime_buildings {
				
			}
			// update their color
			do update_color_building;
		}
	}
	
	action open_the_river {
		ask water_line {
			color_water <- #blue ;
			add parking_places where (each intersects self) to: to_be_erased;
			ask  parking_places where (each intersects self) {
				do die;
			}
		}		
		write "################################################";
   		write "In der Altstadt sind zirka " + length(parking_places) + " Parkplätze vorhanden.";
		write "Durch die Aufdeckung des Flusses werden zirka " + length(to_be_erased) + " Parkplätze entfallen";
		write "Dementsprechend bleiben zirka " + length(parking_places) + " Parkplätze in der Altstadt vorhanden.";
		write "################################################";
	}
	
	action declare_settings {
		write "#######################################################################";
		write "Datum & Uhrzeit der Simulation: " +  starting_date;
		write "Es wird folgenden Wochentag: " +  scenario_name + " simuliert";
		if hotspot_event = true {
			write "Es wird eine Veranstaltung um " + time_event + " Uhr für die Dauer von " + event_duration + "Stunde geben";
			write "Die Veranstaltung findet am folgenden Standort '" + hotspots_choice + "' mit " + n_of_visitors_to_hotspot + " Besucher*innen";
		}
		write "Eingehender Verkehr (Anzahl Autos): " +  n_incoming_agents_per_day;
		write "		> davon Arbeitende: " +  length(visitors where (each.target_group_category = "worker"));
		write "		> davon aus anderen Grunden (Freizeit, Tourismus, Shopping Artzbesuch usw.: " +  length(visitors where (each.target_group_category = "freetime"));
		write "Ausgehender Verkehr (Anzahl Autos): " +  length(residents);
		write "		> davon Arbeitende: " +  length(residents where (each.target_group_category = "working_inhabitant"));
		write "		> davon nicht Arbeitende (Rentner*innen usw.: " +  length(residents where (each.target_group_category = "not_working_inhabitant"));
		write "HVZ: " +  hvz_workers + " Uhr";
		write "% der Wegeketten nach Tageszeit: " + time_of_the_day;
		write "% der Wegeketten nach Zielgruppe: " + worker_freetime_prob;
		write "#######################################################################";
	}
	action define_settings {
				freet_prob <- 1 - work_prob;
				if scenario_name = 'Montag' {
					 starting_date <- date([2022,3,1,4,0,0]);
					 //n_incoming_agents_per_day <- 2000;
					 time_of_the_day <- ["morning"::0.4, "afternoon"::0.5, "evening"::0.1];
					 worker_freetime_prob <- ["worker"::work_prob, "freetime"::freet_prob];
				} else if scenario_name = 'Dienstag' {
					 starting_date <- date([2022,3,2,4,0,0]);
					 //n_incoming_agents_per_day <- 2000;
					 time_of_the_day <- ["morning"::0.4, "afternoon"::0.5, "evening"::0.1];
					 worker_freetime_prob <- ["worker"::work_prob, "freetime"::freet_prob];
				} else if scenario_name = 'Mittwoch' {
					 starting_date <- date([2022,3,3,4,0,0]);
					 //n_incoming_agents_per_day <- 2000;
					 time_of_the_day <- ["morning"::0.4, "afternoon"::0.5, "evening"::0.1];
					 worker_freetime_prob <- ["worker"::work_prob, "freetime"::freet_prob];
				} else if scenario_name = 'Donnerstag' {
					 starting_date <- date([2022,3,4,4,0,0]);
					 //n_incoming_agents_per_day <- 2000;
					 time_of_the_day <- ["morning"::0.4, "afternoon"::0.5, "evening"::0.1];
					 worker_freetime_prob <- ["worker"::work_prob, "freetime"::freet_prob];
				} else if scenario_name = 'Freitag' {
					 starting_date <- date([2022,3,5,4,0,0]);
					 //n_incoming_agents_per_day <- 2000;
					 time_of_the_day <- ["morning"::0.4, "afternoon"::0.5, "evening"::0.1];
					 worker_freetime_prob <- ["worker"::work_prob, "freetime"::freet_prob];
				} else if scenario_name = 'Samstag' {
					 starting_date <- date([2022,3,6,4,0,0]);
					 time_of_the_day <- ["morning"::0.1, "afternoon"::0.7, "evening"::0.2];
					  //n_incoming_agents_per_day <- 3000;
					  worker_freetime_prob <- ["worker"::work_prob, "freetime"::freet_prob];
				} else if scenario_name = 'Sonntag' {
					 starting_date <- date([2022,3,7,4,0,0]);
					 time_of_the_day <- ["morning"::0.3, "afternoon"::0.6, "evening"::0.1];
					  //n_incoming_agents_per_day <- 3000 + n_of_visitors_to_hotspot;
					  worker_freetime_prob <- ["worker"::work_prob, "freetime"::freet_prob];
				}
			
			// save the day as name
			if current_date.day = 1 {
				today <- "Monday";
			} else if current_date.day = 2 {
				today <- "Tuesday";
			} else if current_date.day = 3 {
				today <- "Wednesday";
			} else if current_date.day = 4 {
				today <- "Thursday";
			} else if current_date.day = 5 {
				today <- "Friday";
			} else if current_date.day = 6 {
				today <- "Saturday";
			} else if current_date.day = 7 {
				today <- "Sunday";
			}
		}
		
		// if it is a scenario with a veranstaltung, than people should receive specific characteristics
		/// people coming to an event are not driving alone, hence they are divided by two
		action hotspot_event_creation {
			
				list<visitors> visitors_hotspot <- (n_of_visitors_to_hotspot / 2) first (visitors where (each.target_group_category = "freetime"));
					ask visitors_hotspot {
						event_visitor <- true;
						start_parking_time <- time_event;
						end_parking_time <- start_parking_time + event_duration;
						if hotspots_choice = "Kulturkirche" {
							ask buildings where (each.id = "158") {
								myself.my_target <- self;
							}
							//my_target <- first(buildings where (each.id = "158"));
						} else if hotspots_choice = "Seepromenade" {
							ask buildings where (each.id = "2570") {
								myself.my_target <- self;
							}
							//my_target <- first(buildings where (each.id = "2570"));
						} else if hotspots_choice = "Kulturhaus" {
							ask buildings where (each.id = "2331") {
								myself.my_target <- self;
							}
							//my_target <- first(buildings where (each.id = "2331"));
						} else if hotspots_choice = "Klosterkiche Sankt Trinitatis" {
							ask buildings where (each.id = "41") {
								myself.my_target <- self;
							}
							//my_target <- first(buildings where (each.id = "41"));
						}
			}	
		}
	}

// define cars variables and behavior
species residents control: fsm {
	string id;
	string block;
	string age_class;
	string hh_dim;
	living_buildings my_living_place;
	parking_places my_parking_place;
	string target_group_category;
	int leaving_time;
	int leaving_minute;
	int return_time;
	int return_minute;
	int length_of_absence;
	
	
	state parking initial: true{
  	// transition to leave and adjustment of my_parking_place
  	transition to:leave when: current_date.hour = leaving_time and current_date.minute = leaving_minute {
	  		ask my_parking_place {
				self.occupied <- false;
				self.color_parking_places <- predefined_color;
				self.occupied_by <- myself.target_group_category;
				self.target_of_parking <- myself.my_living_place.id;
				do save_parking_data;
			}
	  	}
	}
	// by leaving they just die evtl. for residents they can have another state to be reactivated later
	state leave initial: false{
		transition to: parking when: current_date.hour = return_time and current_date.minute = return_minute {
			// based on my_living_place the closest parking_place that is not occupied and has an allowed_stay_duration longer than my length_of_stay or that it is reserved for residents is selected
			ask my_living_place {
				myself.my_parking_place <- parking_places where (each.occupied = false and (each.zone = self.parking_zone or each.zone = 'ohne Anwohnerkarte ohne Parkscheibe')) at_distance 200 closest_to (self) ; // select the parking place
			}
			// in case with the at_distance operator nothing was found
			if my_parking_place = nil {
					ask my_living_place {
						myself.my_parking_place <- parking_places where (each.occupied = false and (each.zone = self.parking_zone or each.zone = 'ohne Anwohnerkarte ohne Parkscheibe')) closest_to (self) ; // select the parking place
					}
			}
			// if the visiting car as found a parking place, it locate itself there and change my_parking_place's attributes
			if my_parking_place != nil {
					location <- my_parking_place.location;
					int dist;
					dist <- self distance_to my_living_place;
					ask my_parking_place {
						self.occupied <- true;
						self.color_parking_places <- #black;
						self.occupied_by <- myself.target_group_category;
						self.distance_to_goal <- dist;
						self.target_of_parking <- myself.my_living_place.id;
						do save_parking_data;
					}
					//add dist to: dist2building;
					if dist < 25 {
						less_than_25 <- less_than_25 + 1;
					} else if dist < 50 {
						less_than_50 <- less_than_50 + 1;
					} else if dist < 100 {
						less_than_100 <- less_than_100 + 1;
					} else if dist < 150 {
						less_than_150 <- less_than_150 + 1;
					} else {
						more_than_150 <- more_than_150 + 1;
					}
			} else {
				// it must be defined a strategy
				write "Resident: " + self + " cannot find a parkplace";
				//do die;
			}
		}
	}
	aspect base {
		draw  circle(1) color: #transparent ;
	}
}

// define cars variables and behavior
species visitors control: fsm {
	string id;
	buildings my_target;
	parking_places my_parking_place;
	string target_group_category;
	int end_parking_time;
	int end_parking_minute;
	int start_parking_time;
	int start_parking_minute;
	int length_of_stay;
	bool using_park_and_ride;
	bool event_visitor;
	
	state standby initial:true {
		transition to: parking when: current_date.hour = start_parking_time and current_date.minute =  start_parking_minute {
			if target_group_category = "worker" {
				my_target <- one_of(work_buildings);
			} else {
				if event_visitor = false {
					string my_target_id <- rnd_choice(attraction_weights_list); // it must be checked analytically
					// in cases where something get wrong, take one random destination
					if my_target_id = nil {
						my_target_id <- one_of(attraction_weights_list.keys); // it must be checked analytically
					}
					my_target <- first(buildings where (each.poi_id = my_target_id));
					// in case something goes wrong
					if my_target = nil {
						my_target <- one_of(buildings);
					}
					// some visitors could park at the park and ride station if any available
					if length(park_and_ride_stop) > 0 {
						float prob_not_using <- 1 - prob_using_park_and_ride;
						using_park_and_ride <- [false::prob_not_using, true::prob_using_park_and_ride];
					}
				}
			}
			ask my_target {
				if myself.using_park_and_ride = false {
					myself.my_parking_place <- parking_places where (each.occupied = false and each.resident_only = false and each.allowed_stay_duration >= myself.length_of_stay)  closest_to (self) ; // select the parking place					
				} else if myself.using_park_and_ride = true {
					myself.my_parking_place <- one_of(parking_places where (each.zone = "park & ride")); // select the parking place in a park and ride zone
				}
			}
			// in case with the at_distance operator nothing was found
			if my_parking_place = nil {
					ask my_target {
						myself.my_parking_place <- parking_places where (each.occupied = false and each.resident_only = false and  each.allowed_stay_duration >= myself.length_of_stay) closest_to (self) ; // select the parking place
					}
					if my_parking_place = nil and using_park_and_ride = false {
						self.my_parking_place <- one_of(parking_places where (each.zone = "park & ride")); // select the parking place in a park and ride zone
						using_park_and_ride <- true;
					}
			}
			// if the visiting car as found a parking place, it locate itself there and change my_parking_place's attributes
			if my_parking_place != nil {
					location <- my_parking_place.location;
					int dist;
					if self.using_park_and_ride = false {
						dist <- self distance_to my_target;
					} else if self.using_park_and_ride = true {
						park_and_ride_stop my_park_and_ride_stop;
						ask my_target {
							my_park_and_ride_stop <- park_and_ride_stop closest_to self;	
						}
						dist <- my_park_and_ride_stop distance_to my_target;
					}
					ask my_parking_place {
						self.occupied <- true;
						self.color_parking_places <- #black;
						self.occupied_by <- myself.target_group_category;
						self.distance_to_goal <- dist;
						self.target_of_parking <- myself.my_target.id;
						do save_parking_data;
					}
					//add dist to: dist2building;
					if dist < 25 {
						less_than_25 <- less_than_25 + 1;
					} else if dist < 50 {
						less_than_50 <- less_than_50 + 1;
					} else if dist < 100 {
						less_than_100 <- less_than_100 + 1;
					} else if dist < 150 {
						less_than_150 <- less_than_150 + 1;
					} else {
						more_than_150 <- more_than_150 + 1;
					}
			} else {
				// it must be defined a strategy
				do die;
			}
		}
	}
	
	state parking initial: false{
  	// transition to leave and adjustment of my_parking_place
  	transition to:leave when: current_date.hour = end_parking_time and current_date.minute =  end_parking_minute {
	  		ask my_parking_place {
				self.occupied <- false;
				self.color_parking_places <- predefined_color;
				self.occupied_by <- myself.target_group_category;
				self.target_of_parking <- myself.my_target.id;
				do save_parking_data;
			}
	  	}
	}
	// by leaving they just die evtl. for residents they can have another state to be reactivated later
	state leave initial: false{
		do die;
	}
	aspect base {
		draw  circle(1) color: #transparent ;
	}
}


// define buildings  variables and behavior
species buildings {
	rgb color_building ;
	string id;
	string type;
	string poi_id;
	float attraction_coefficient;
	float weigthed_attraction_coefficient;
	int area;
	int red_attraction;
	string parking_zone;
	// define a red tone for indicating buildings with high attraction following: color <- rgb(255, red_attraction, red_attraction);
	action update_color_building {
			self.red_attraction <- 255 - int(self.attraction_coefficient * (255/max_attraction_coefficient));
	}
	
	aspect base {
		if hotspots contains self {
				color_building <- #pink;
		} else {
			if poi_id != nil {
				color_building <- rgb(255, red_attraction, red_attraction);
			} else {
				color_building <- rgb(60, 174, 163);
			}	
		}	
		draw shape color: color_building; //border: #white  width: 2 ;
	}
}

// define buildings  variables and behavior
species living_buildings {
	rgb color_building;
	string id;
	string type;
	string block;
	string parking_zone;
	aspect base {
		if type contains "mit" {
			color_building <- rgb(32, 99, 155);
		} else {
			color_building <- rgb(23, 63, 95);
		}
		draw shape color: color_building; //border: #white  width: 2 ;
	}
}

// define parking_places variables and behavior
species parking_places control: fsm {
	rgb color_parking_places;
	rgb predefined_color;
	string id;
	string zone;
	bool occupied <- false;
	bool resident_only;
	bool switch;
	int allowed_stay_duration;
	string parking_typology;
	string occupied_by;
	int distance_to_goal;
	string target_of_parking;
	point difference <- { 0, 0 };
	
	action save_parking_data {  // save data into Postgres
		if save_data = true {
			add cycle to: cycles;
			add id to: osm_ids;
			add current_date.hour to: hours_of_parking;
			add current_date.minute to: mins_of_parking;
			add distance_to_goal to: distance_to_goals;
			add occupied to: occupied_list;
			add occupied_by to: occupied_by_list;
			add target_of_parking to: building_target;
		}
	}

	aspect base {
		draw shape color: color_parking_places border: #white  ;
	}
}

// define roads variables and behavior
species roads {
	rgb color_roads <- #white ;
	string id;
	string street_name;
	string type;
	
	aspect base {
		draw shape color: color_roads ;
	}
}

// define park_and_ride areas variables and behavior
species park_and_ride_areas {
	int id;
	rgb color_park_and_ride;

	aspect base {
		draw shape color: color_park_and_ride ;
	}
}

// define park_and_ride stops variables and behavior
species park_and_ride_stop {
	int id;

	aspect base {
		draw circle(5#m) color: #white border: #black ;
	}
}


// define water_line variables and behavior
species water_line {
	rgb color_water <- #transparent ;

	aspect base {
		draw shape color: color_water ;
	}
}

// define water_area variables and behavior
species water_area{
	rgb color_water <- #blue ;

	aspect base {
		draw shape color: color_water ;
	}
}


	//////////////////////////////////////
	// Definition of the experiment //
	/////////////////////////////////////

experiment neuruppin type: gui {
	
   parameter "Setting Name" category:"Allgemeine Einstellungen" var: setting_name;  
   parameter "Szenario-Wahl" category: "Allgemeine Einstellungen" var: scenario_name <- 'Montag' among: available_scenarios;
   parameter "Background color" category: "Allgemeine Einstellungen" var: background_color <- 'Medium grey' among: background_colors;
   parameter "Daten speichern?" category: "Allgemeine Einstellungen" var: save_data init: true;
   user_command "Agenten kreieren" category: "Allgemeine Einstellungen" color:#darkblue {ask agentDB {do create_humans;}}
   parameter "Ist ein Veranstaltungstag?" category: "Veranstaltungen" var: hotspot_event init: false;
   parameter "Hotspot der Veranstaltung" category: "Veranstaltungen" var: hotspots_choice <- 'Seepromenade' among: hotspots_choices;
   parameter "Uhrzeit der Veranstaltung" category: "Veranstaltungen" var: time_event init: 18 min: 10 max: 20 step: 1;
   parameter "Dauer der Veranstaltung" category: "Veranstaltungen" var: event_duration init: 2 min: 1 max: 6 step: 1;    
   parameter "Besucher*innen des Hotspots" category: "Veranstaltungen" var: n_of_visitors_to_hotspot  init: 500 min: 100 max: 1500 step: 1;

   parameter "Anzahl eingehender Verkehr pro Tag - Besucher*innen" category: "Traffic flow" var: n_incoming_agents_per_day init: 2000 min: 1000 max: 3500 step: 1;
   parameter "% des eigehenden Verkehrs aus berüflichen Gründen" category: "Traffic flow" var: work_prob init: 0.4 min: 0.0 max: 1.0 step: 0.05;
   parameter "Anzahl Autos von Einwohner*innen mit Parkschein" category: "Traffic flow" var: n_residents init: 1304 min: 1000 max: 2000 step: 1;
   parameter "% des Einwohner*innen, die arbeiten gehen" category: "Traffic flow" var: work_prob_res init: 0.8 min: 0.0 max: 1.0 step: 0.05;
   parameter "HVZ - Arbeitende" category: "Traffic flow" var: hvz_workers init: 8 min: 0 max: 23 step: 1;
   

   parameter "Aufdeckung des Baches" category: "Baumaßnahmen" var: river_visible init: false on_change: {ask DB_accessor {do open_the_river;}parking_places_modified <- true;};
   parameter "Umbau der Parkplätze" category: "Baumaßnahmen" var: modify_parking_places init: false on_change: {parking_places_modified <- true;};
   parameter "Bestimmung autofreie Straße" category: "Baumaßnahmen" var: modify_roads init: false on_change: {roads_modified <- true;parking_places_modified <- true;};
   parameter "Parkingplatz in der Töllerstrasse erweitern" category: "Baumaßnahmen" var: extension_tollerstrasse init: false on_change: {ask world {do extension_parking_place;parking_places_modified <- true;}};
   parameter "Anzahl Stellpätze bei der Erweitung des Parkingplatzes in der Töllerstrasse" category: "Baumaßnahmen" var: n_extension_tollerstrasse init: 60 min: 10 max: 100 step: 1 on_change: {parking_places_modified <- true;};
   parameter "Parkplätze am Rheinsberger Tor zurückbauen" category: "Baumaßnahmen" var: demolition_train_station init: false on_change: {ask world {do demolition_parking_place;}parking_places_modified <- true;};
   parameter "Querparken in der Schinkelstrasse ermöglichen" category: "Baumaßnahmen" var: parking_places_rotation init: false on_change: {ask world {do rotate_parking_place;}parking_places_modified <- true;};
   parameter "Parkzonen aufheben" category: "Baumaßnahmen" var: erase_parking_zones init: false on_change: {ask parking_places {zone <- "neuruppin";}
   																																														ask living_buildings {parking_zone <- "neuruppin";}
 																																														ask buildings {parking_zone <- "neuruppin";}
 																																														write "###########################################";
 																																														write "Die Parkzonen wurden für die ganze Altstadt aufgehoben";
 																																														write "###########################################";};
   parameter "Anzahl Stellplätze" category:"Park & Ride" var: n_park_and_ride  init: 100 min: 1 max: 400 step: 1;
   parameter "Erlaubte Aufenthaltslänge" category:"Park & Ride" var: allowed_stay_park_and_ride init: 24;
   parameter "Location" category:"Park & Ride" var: park_and_ride_location <- "Nord-West" among: ["Nord-West","Nord-Ost","Sud-West"];
   parameter "Park and Ride Haltestelle setzen" category: "Park & Ride" var: park_and_ride_station init: false;
   parameter "Anteil Park and Ride Nutzende" category: "Park & Ride"var: prob_using_park_and_ride init: 0.2 min: 0.05 max: 1.0 step: 0.05;
   user_command "Park & ride realisieren" category: "Park & Ride" color:#darkblue {ask world {do park_and_ride;} park_and_ride_created <- true;}
   // 56 as initial value is derived from the Auswertung_Umfrage_Neuruppin > Seite 13
   // parameter "% of residents with car" category: "Residents" var: n_outgoing_residents_per_day init: 2970 min: 2000 max: 3500 step: 1;
   

   
output {
	layout #split;
		display city_display type: java2D  draw_env: false background: background_color {		

		
        	//define an overlay layer positioned at the coordinate 5,5 for the
            overlay position: { 5, 5 } size: { 250 #px, 350 #px } background: # black transparency: 0.5 border: #black rounded: true
            {
            	//for each possible type, we draw a square with the corresponding color and we write the name of the type
                float y <- 30#px;
                loop type over: legend_color.keys
                {
                    draw square(15#px) at: { 20#px, y } color: legend_color[type] border: #white;
                    draw type at: { 40#px, y + 4#px } color: # white font: font("SansSerif", 18, #bold);
                    y <- y + 25#px;
                }
            }
            
            // graphics for modifying parking places and roads
            graphics "Empty target" {
				if modify_parking_places = true {  // graphics for modifying parking places
					if (empty(moved_agents)) {
						draw pointing_zone at: target empty: false border: false color: #wheat;
					}
				} else if modify_roads = true {  // graphics for modifying roads
						draw pointing_zone at: target_roads empty: false border: false color: #green;
				} else if park_and_ride_station = true {  // graphics for modifying roads
						draw pointing_zone at: target_park_and_ride empty: false border: false color: #darkblue;
				} else if modify_roads = false and modify_parking_places = false and park_and_ride_station = false {
					// nothing to reset after action is completed
				}
			}
            
			graphics "Full target" {
				int size <- length(moved_agents);
				if (size > 0)
				{
					rgb c1 <- rgb(#darkseagreen, 120);
					rgb c2 <- rgb(#firebrick, 120);
					draw pointing_zone at: target empty: false border: false color: (can_drop ? c1 : c2);
					draw "'Parkplätzemanagement" at: target + { -15, -15 } font: font("SansSerif", 18, #bold) color: # white;
					draw "'r': Parkplatz entfernen" at: target + { -15, 0 } font: font("SansSerif", 18, #bold) color: # white;
					draw "'c': Parkplatz duplizieren" at: target + { -15, 15 } font: font("SansSerif", 18, #bold) color: # white;
				} else if modify_roads = false and modify_parking_places = false and park_and_ride_station = false {
					
				}

			}
			event mouse_move action: move;
			event mouse_up action: click;	
			event 'r' action: kill;
			event 'c' action: duplicate;
			species parking_places  aspect:base refresh: true;
            species roads  aspect:base refresh: true;
			species living_buildings  aspect:base refresh: true;
			species buildings  aspect:base refresh: true;
			species water_line  aspect:base refresh: true;
			species water_area  aspect:base refresh: false;
			species visitors  aspect:base refresh: true;
			species residents  aspect:base refresh: true;
			species park_and_ride_stop  aspect:base refresh: true;
			
        }
		
		display "Distances" type:java2D {
			chart "Distanz vom Parkplatz zum Gebäuden" type:histogram
			background: background_color
			 	color: #white 
			 	axes: #white
			 	title_font: font('Serif', 32, #italic)
			 	tick_font: font('Monospaced', 14, #bold) 
			 	label_font: font('Arial', 18, #bold) 
			 	legend_font: font('SanSerif', 18, #bold)
			 	//y_range:[0,40]
			 	x_tick_line_visible:false
			 	y_tick_line_visible:false
			 	y_tick_unit:5
			 	x_label:'Distanz'
			 	y_label:'Anzahl'
			series_label_position: xaxis
			{
				datalist legend:["< 25","< 50","< 100","< 150","> 150"] 
					style: bar
					value:[less_than_25,less_than_50,less_than_100,less_than_150,more_than_150] 
					color:[rgb(255,204,204),rgb(255,153,153),rgb(255,102,102),rgb(255,51,51),rgb(204,0,0)];
			}
		}
		display "Parking_places" synchronized: true {
			chart "Besetzte Vs freie Parkplätze" type:histogram 
			 	background: background_color
			 	color: #white  
			 	axes: #white 
			 	title_font: font('Serif', 32.0, #italic)
			 	tick_font: font('Monospaced', 14, #bold) 
			 	label_font: font('Arial', 18, #bold) 
			 	legend_font: font('SanSerif', 18, #bold) 
			 	//y_range:[-20,40]
			 	x_tick_line_visible:false
			 	y_tick_line_visible:false
			 	y_tick_unit:100
			 	x_label:'Zeit'
			 	y_label:'Anzahl'
			 {
				data "Besetze Parkplätze" value: length(parking_places where (each.occupied = true))
					accumulate_values: true						
					style:stack
					color:#yellow;
				data "Freie Parkplätze" value: length(parking_places where (each.occupied = false))
					accumulate_values: true						
					style: stack
					color:#black;
			}
		}
	}
}
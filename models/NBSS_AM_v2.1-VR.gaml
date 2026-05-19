model NBSSAM_model_VR

import "NBSS_AM_v2.1_forVR.gaml"

species unity_linker parent: abstract_unity_linker {
	string player_species <- string(unity_player);
	int max_num_players  <- 1;
	int min_num_players  <- 1;
	//unity_property up_sewer_system;
	unity_property up_filter_media;
		//unity_property up_rain;
	//unity_property up_programmed_maintenance;
		//unity_property up_unmanaged_flow;
		//unity_property up_managed_flow;
	unity_property up_vegetation_cover;
	//unity_property up_vegetal_component;
	unity_property up_trees;
	unity_property up_inlet;
	unity_property up_engineered_component;
	unity_property up_natural_environment;
	unity_property up_NBSS;
	unity_property up_default;
	//unity_property up_component;
	//unity_property up_ext_time_failure;
	//unity_property up_ext_metric_failure;
	//unity_property up_failure_event;
	//unity_property up_output_flow;
	//unity_property up_rtf_maintenance;
	unity_property up_outlet;
	unity_property up_urban_environment;
	unity_property up_ponding_area;
	
	//mes agents ajoutés
	unity_property up_shrubs_plants;
	unity_property up_grass;
	unity_property up_vegetal_waste;
	unity_property up_trash;
	unity_property up_weeds;
	unity_property up_gravel;
	unity_property up_microorganisms;
	unity_property up_swale;
	//list<point> init_locations <- define_init_locations();

//	list<point> define_init_locations {
//		return [{50.0,50.0,0.0}];
//	}

	bool do_send_world <- true;
	list<point> init_locations <- [any_location_in(init_free_space) + {0,0,1}];

	init {
		do define_properties;
		player_unity_properties <- [up_default];
//		do add_background_geometries(sewer_system,up_sewer_system);
		
//		do add_background_geometries(rain,up_rain);
//		do add_background_geometries(programmed_maintenance,up_programmed_maintenance);
//		do add_background_geometries(vegetal_component,up_vegetal_component);

		//do add_background_geometries(natural_environment,up_natural_environment);
		//do add_background_geometries(engineered_component,up_engineered_component);
//		do add_background_geometries(component,up_component);
//		do add_background_geometries(ext_time_failure,up_ext_time_failure);
//		do add_background_geometries(ext_metric_failure,up_ext_metric_failure);
//		do add_background_geometries(failure_event,up_failure_event);
//		do add_background_geometries(rtf_maintenance,up_rtf_maintenance);
		//do add_background_geometries(urban_environment,up_urban_environment);
		do add_background_geometries(ponding_area,up_ponding_area);
	//	do add_background_geometries(filter_media, up_filter_media);
//		do add_background_geometries(managed_flow,up_managed_flow);
//		do add_background_geometries(unmanaged_flow,up_unmanaged_flow);
//		do add_background_geometries(output_flow,up_output_flow);
		
		//
		//do add_background_geometries(microorganisms, up_microorganisms);
	//	do add_background_geometries(gravel, up_gravel);
		//do add_background_geometries(NBSS, up_NBSS);
	//	do add_background_geometries(swale, up_swale);
	}
	action define_properties {
//		unity_aspect sewer_system_aspect <- geometry_aspect(1.0,#gray,precision);
//		up_sewer_system <- geometry_properties("sewer_system","sewer_system",sewer_system_aspect,#no_interaction,false);
//		unity_properties << up_sewer_system;


		unity_aspect filter_media_aspect <- geometry_aspect(1.0,#saddlebrown,precision);
		up_filter_media <- geometry_properties("filter_media","filter_media",filter_media_aspect,#ray_interactable,false);
		unity_properties << up_filter_media;


//		unity_aspect rain_aspect <- geometry_aspect(1.0,#gray,precision);
//		up_rain <- geometry_properties("rain","rain",rain_aspect,#no_interaction,false);
//		unity_properties << up_rain;


//		unity_aspect programmed_maintenance_aspect <- geometry_aspect(1.0,#gray,precision);
//		up_programmed_maintenance <- geometry_properties("programmed_maintenance","programmed_maintenance",programmed_maintenance_aspect,#no_interaction,false);
//		unity_properties << up_programmed_maintenance;
//
//
//		unity_aspect unmanaged_flow_aspect <- geometry_aspect(1.0,#gray,precision);
//		up_unmanaged_flow <- geometry_properties("unmanaged_flow","unmanaged_flow",unmanaged_flow_aspect,#no_interaction,false);
//		unity_properties << up_unmanaged_flow;
//
//
//		unity_aspect managed_flow_aspect <- geometry_aspect(1.0,#gray,precision);
//		up_managed_flow <- geometry_properties("managed_flow","managed_flow",managed_flow_aspect,#no_interaction,false);
//		unity_properties << up_managed_flow;


		unity_aspect vegetation_cover_aspect <- prefab_aspect("Prefabs/Visual Prefabs/City/Vehicles/Car",1.0,0.0,1.0,0.0,precision);
		up_vegetation_cover <- geometry_properties("vegetation_cover","vegetation_cover",vegetation_cover_aspect,#ray_interactable,false);
		unity_properties << up_vegetation_cover;


//		unity_aspect vegetal_component_aspect <- prefab_aspect("Prefabs/Visual Prefabs/City/Vehicles/Car",1.0,0.0,1.0,0.0,precision);
//		up_vegetal_component <- geometry_properties("vegetal_component","vegetal_component",vegetal_component_aspect,#no_interaction,false);
//		unity_properties << up_vegetal_component;


		unity_aspect trees_aspect <- prefab_aspect("Prefabs/FreeVegetation-LowPolyNature/FreeVegetation/Prefabs/Tree_1_1",1.0,0.0,1.0,0.0,precision);
		up_trees <- geometry_properties("trees","trees",trees_aspect,#ray_interactable,false);
		unity_properties << up_trees;
		
		unity_aspect shrubs_aspect <- prefab_aspect("Prefabs/FreeVegetation-LowPolyNature/FreeVegetation/Prefabs/Bush_1_1",1.0,0.0,1.0,0.0,precision);
		up_shrubs_plants <- geometry_properties("shrubs_plants","shrubs_plants",shrubs_aspect,#ray_interactable,false);
		unity_properties << up_shrubs_plants;
		
		unity_aspect grass_aspect <- prefab_aspect("Prefabs/FreeVegetation-LowPolyNature/FreeVegetation/Prefabs/Grass_1_1",1.0,0.0,1.0,0.0,precision);
		up_grass <- geometry_properties("grass","grass",grass_aspect,#ray_interactable,false);
		unity_properties << up_grass;
		
		unity_aspect vegetal_waste_aspect <- prefab_aspect("Prefabs/FreeVegetation-LowPolyNature/FreeVegetation/Prefabs/Plant_1_1",1.0,0.0,1.0,0.0,precision);
		up_vegetal_waste <- geometry_properties("vegetal_waste","vegetal_waste",vegetal_waste_aspect,#ray_interactable,false);
		unity_properties << up_vegetal_waste;
		
		unity_aspect trash_aspect <- prefab_aspect("Prefabs/Mess Maker Free/Low Poly/Cans/Soda Can Green Crushed",1.0,0.0,1.0,0.0,precision);
		up_trash <- geometry_properties("trash","trash",trash_aspect,#ray_interactable,false);
		unity_properties << up_trash;
		
		unity_aspect weeds_aspect <- prefab_aspect("Prefabs/Parks And Nature Pack/Prefab/GrassE",1.0,0.0,1.0,0.0,precision);
		up_weeds <- geometry_properties("weeds","weeds",weeds_aspect,#ray_interactable,false);
		unity_properties << up_weeds;
		
		unity_aspect gravel_aspect <- geometry_aspect(1.0, #slategrey, precision); //à voir si je définis la sous-couche en prefab ou non
		up_gravel <- geometry_properties("gravel","gravel",gravel_aspect,#no_interaction,false);
		unity_properties << up_gravel;
		
//		unity_aspect microorganisms_aspect <- prefab_aspect("Prefabs/Visual Prefabs/City/Vehicles/Car",1.0,0.0,1.0,0.0,precision);
//		up_microorganisms <- geometry_properties("microorganisms","microorganisms",microorganisms_aspect,#no_interaction,false);
//		unity_properties << up_microorganisms;


		unity_aspect inlet_aspect <- geometry_aspect(0.75,#gray,precision);
		up_inlet <- geometry_properties("inlet","inlet",inlet_aspect,#ray_interactable,false);
		unity_properties << up_inlet;


		unity_aspect engineered_component_aspect <- geometry_aspect(1.0,#darkgray, precision);
		up_engineered_component <- geometry_properties("engineered_component","engineered_component",engineered_component_aspect,#no_interaction,false);
		unity_properties << up_engineered_component;


		unity_aspect natural_environment_aspect <- geometry_aspect(1.0,#green,precision);
		up_natural_environment <- geometry_properties("natural_environment","natural_environment",natural_environment_aspect,#no_interaction,false);
		unity_properties << up_natural_environment;


		unity_aspect NBSS_aspect <- geometry_aspect(2.0,#gray,precision);
		up_NBSS <- geometry_properties("NBSS","NBSS",NBSS_aspect,#ray_interactable,false);
		unity_properties << up_NBSS;
		
		unity_aspect swale_aspect <- geometry_aspect(1.0,#lawngreen,precision);
		up_swale <- geometry_properties("swale","swale",swale_aspect,#ray_interactable,false);
		unity_properties << up_swale;


		unity_aspect default_aspect <- geometry_aspect(1.0,#gray,precision);
		up_default <- geometry_properties("default","",default_aspect,#no_interaction,false);
		unity_properties << up_default;


//		unity_aspect component_aspect <- prefab_aspect("Prefabs/Visual Prefabs/City/Vehicles/Car",1.0,0.0,1.0,0.0,precision);
//		up_component <- geometry_properties("component","component",component_aspect,#no_interaction,false);
//		unity_properties << up_component;
//
//
//		unity_aspect ext_time_failure_aspect <- geometry_aspect(1.0,#gray,precision);
//		up_ext_time_failure <- geometry_properties("ext_time_failure","ext_time_failure",ext_time_failure_aspect,#no_interaction,false);
//		unity_properties << up_ext_time_failure;
//
//
//		unity_aspect ext_metric_failure_aspect <- geometry_aspect(1.0,#gray,precision);
//		up_ext_metric_failure <- geometry_properties("ext_metric_failure","ext_metric_failure",ext_metric_failure_aspect,#no_interaction,false);
//		unity_properties << up_ext_metric_failure;
//
//
//		unity_aspect failure_event_aspect <- geometry_aspect(1.0,#gray,precision);
//		up_failure_event <- geometry_properties("failure_event","failure_event",failure_event_aspect,#no_interaction,false);
//		unity_properties << up_failure_event;
//
//
//		unity_aspect output_flow_aspect <- geometry_aspect(1.0,#gray,precision);
//		up_output_flow <- geometry_properties("output_flow","output_flow",output_flow_aspect,#no_interaction,false);
//		unity_properties << up_output_flow;
//
//
//		unity_aspect rtf_maintenance_aspect <- geometry_aspect(1.0,#gray,precision);
//		up_rtf_maintenance <- geometry_properties("rtf_maintenance","rtf_maintenance",rtf_maintenance_aspect,#no_interaction,false);
//		unity_properties << up_rtf_maintenance;


		unity_aspect outlet_aspect <- geometry_aspect(0.75,#gray,precision);
		up_outlet <- geometry_properties("outlet","outlet",outlet_aspect,#ray_interactable,false);
		unity_properties << up_outlet;


		unity_aspect urban_environment_aspect <- geometry_aspect(1.0,#gray,precision);
		up_urban_environment <- geometry_properties("urban_environment","urban_environment",urban_environment_aspect,#no_interaction,false);
		unity_properties << up_urban_environment;


		unity_aspect ponding_area_aspect <- geometry_aspect(0.5, #blue, precision);
		up_ponding_area <- geometry_properties("ponding_area","ponding_area",ponding_area_aspect,#no_interaction,false);
		unity_properties << up_ponding_area;


	}
	reflex send_geometries {
		do add_geometries_to_send(trees,up_trees);
//		do add_geometries_to_send(vegetation_cover, up_vegetation_cover);
		do add_geometries_to_send(outlet,up_outlet);
//		do add_geometries_to_send(inlet, up_inlet);
		//do add_geometries_to_send(NBSS,up_NBSS);
		//do add_geometries_to_send(filter_media,up_filter_media);
		
		//
		do add_geometries_to_send(shrubs_plants, up_shrubs_plants);
		do add_geometries_to_send(grass, up_grass);
		do add_geometries_to_send(trash, up_trash);
		do add_geometries_to_send(weeds, up_weeds);
		do add_geometries_to_send(vegetal_waste,up_vegetal_waste);
		//do add_geometries_to_send(ponding_area,up_ponding_area);
	}
	
	// modify state of species according to health/biodiv
	reflex send_agents when: not empty(unity_player) {
		
		// add attributes to send to Unity. We send one attribute "type" for the dynamic_punctual_agent agents, 
		// that will have for name "type" in uniy and which is an integer  (between 0 and 2 for each dynamic_punctual_agent).
		// get the value of type for each agent.
		list<int> type_agents <- inlet collect (each.function_attributes["my_fqt"]);
		//write "types envoyés : " + type_agents; // debug
		//put this list value in a map (several attributes can be send at the same time).
		map<string,list<int>> atts <-  ["type":: type_agents];
		//at every step, we send the dynamic_punctual_agent agents with the up_car properties and the attributes "atts" 
		do add_geometries_to_send(inlet,up_inlet,atts);	
		
		//we want to keep the dynamic_geometry_agent in their current state in Unity, so we add them in the geometries_to_keep list
		//do add_geometries_to_keep(outlet);	
	}
	
	
//	reflex send_agents_every_100_steps when: every(100 #cycle) and not empty(unity_player){
//		//at every 100 step, we send the new geometries of the dynamic_geometry_agent agents with the up_geom properties
//		do add_geometries_to_send(dynamic_geometry_agent,up_geom);
//	}
	
	
	
	
	// Maintenance practices and their impact on biodiv/costs/vegetation health
	action maintenance_remove(string id) {
		agent ag <- (trash + weeds + vegetal_waste) first_with (each.name = id) ;
		if (ag != nil) {
			ask ag {
				remove key: self from: myself.geometries_to_send;
				do die;
			}
		}
	}
//	action maintenance_repair(string id) {
//		component ag <- (engineered_component + vegetal_component) first_with (each.name = id) ;
//		if (ag != nil) {
//			ask ag {
//				if function_attributes["my_health"] < 3 {
//					function_attributes["my_health"] <- function_attributes["my_health"] + 1;
//				}
//				else {
//					function_attributes["my_health"] <- function_attributes["my_health"] - 1;
//				}
//				price <- price + 1;
//			}
//		}
//	}
	action add_veg(string id) {
		agent ag <- (shrubs_plants + grass + trees) first_with (each.name = id) ;
		if (ag != nil) {
			ask ag {
				create ag;
				add ag to: myself.geometries_to_send; //pas sûre
			}
		}
	}
	action water_plants(string id) {
		//if (current_season = "summer" and time_since_last_water >= 2) {
			// si trop arrosée, perds de la santé, sinon en gagne (et affecte apparence plantes) aussi dépend des saisons
		//}
	}
	action mow_grass_trees(string id) {
		agent ag <- (trees + grass) first_with(each.name = id);
		if ag != nil {
			create vegetal_waste {
				location <- rnd({1.0, 0.0, 0.0}); //à déterminer mais dans ponding area
			}
			// supprimer une partie des feuilles/de l'herbe au niveau du sol/des arbres
		}
	}
	
//	action change_color
//	//impact décisions sur envir/pluie (si failure_event -> impact aussi)
//	reflex dying_component when: is_failure_event { //lien failure event
//		//selon état (3, 2, 1, 0), composant devient rouge, jaune, orange -> changer aspect des species
//		is_failure_event <- false;
//	}
	reflex dying_biodiv {
		//selon état, réduire le nombre d'espèce dans l'environnement (et réduire fonctionnalité soil par ex) -> enlever agents des listes (uorg par ex)
	}
	reflex budget {
		//coût de maintenance, je sais pas trop pour l'instant
	}
	reflex sediment_acc {
		//quand valeur dans tableau potpall_acc augmente, ajouter une couche de sédiments (et transformer vegetal waste en sediments)
	}
}



species unity_player parent: abstract_unity_player{
	float player_size <- 1.0;
	rgb color <- #red;
	float cone_distance <- 10.0 * player_size;
	float cone_amplitude <- 90.0;
	float player_rotation <- 90.0;
	bool to_display <- true;
	float z_offset <- 2.0;
	aspect default {
		if to_display {
			if selected {
				 draw circle(player_size) at: location + {0, 0, z_offset} color: rgb(#blue, 0.5);
			}
			draw circle(player_size/2.0) at: location + {0, 0, z_offset} color: color ;
			draw player_perception_cone() color: rgb(color, 0.5);
		}
	}
	
	reflex stay_in_bounds { // marche pas
        if !(init_free_space overlaps self) {
            write "out of bounds";
            location <- closest_points_with(init_free_space.location, self)[0]; // ou 1
        }
    }
}

experiment vr_xp parent:"Interface (EN)" autorun: false type: unity {
	float minimum_cycle_duration <- 0.1;
	string unity_linker_species <- string(unity_linker);
	list<string> displays_to_hide <- ["Rain", "Inlet", "Ponding area", "Vegetation cover", "Filter media", "Performance", map];
	float t_ref;

	action create_player(string id) {
		ask unity_linker {
			do create_player(id);
			
			do build_invisible_walls(player: last(unity_player), //player to send the information to
			id: "wall_for_free_area", //id of the walls
			height: 40.0, //height of the walls
			wall_width: 1.0, //width of the walls
			geoms: [init_free_space]);
		}
	}

	action remove_player(string id_input) {
		if (not empty(unity_player)) {
			ask first(unity_player where (each.name = id_input)) {
				do die;
			}
		}
	}

	output {
		 display map_VR parent: map {
			 species unity_player;
			 event #mouse_down{
				 float t <- gama.machine_time;
				 if (t - t_ref) > 500 {
					 ask unity_linker {
						 move_player_event <- true;
					 }
					 t_ref <- t;
				 }
			 }
		 }
	}
}

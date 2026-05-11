model NBSSAM_model_VR

import "NBSS_AM_v2.1_forVR.gaml"

species unity_linker parent: abstract_unity_linker {
	string player_species <- string(unity_player);
	int max_num_players  <- 1;
	int min_num_players  <- 1;
	unity_property up_sewer_system;
	unity_property up_filter_media;
	unity_property up_rain;
	unity_property up_programmed_maintenance;
	unity_property up_unmanaged_flow;
	unity_property up_managed_flow;
	unity_property up_vegetation_cover;
	unity_property up_vegetal_component;
	unity_property up_trees;
	unity_property up_inlet;
	unity_property up_engineered_component;
	unity_property up_natural_environment;
	unity_property up_NBSS;
	unity_property up_default;
	unity_property up_component;
	unity_property up_ext_time_failure;
	unity_property up_ext_metric_failure;
	unity_property up_failure_event;
	unity_property up_output_flow;
	unity_property up_rtf_maintenance;
	unity_property up_outlet;
	unity_property up_urban_environment;
	unity_property up_ponding_area;
	list<point> init_locations <- define_init_locations();

	list<point> define_init_locations {
		return [{50.0,50.0,0.0}];
	}


	init {
		do define_properties;
		player_unity_properties <- [nil];
		do add_background_geometries(sewer_system,up_sewer_system);
		do add_background_geometries(filter_media,up_filter_media);
		do add_background_geometries(rain,up_rain);
		do add_background_geometries(programmed_maintenance,up_programmed_maintenance);
		do add_background_geometries(vegetation_cover,up_vegetation_cover);
		do add_background_geometries(vegetal_component,up_vegetal_component);
		do add_background_geometries(trees,up_trees);
		do add_background_geometries(inlet,up_inlet);
		do add_background_geometries(engineered_component,up_engineered_component);
		do add_background_geometries(natural_environment,up_natural_environment);
		do add_background_geometries(NBSS,up_NBSS);
		do add_background_geometries(component,up_component);
		do add_background_geometries(ext_time_failure,up_ext_time_failure);
		do add_background_geometries(ext_metric_failure,up_ext_metric_failure);
		do add_background_geometries(failure_event,up_failure_event);
		do add_background_geometries(rtf_maintenance,up_rtf_maintenance);
		do add_background_geometries(urban_environment,up_urban_environment);
		do add_background_geometries(ponding_area,up_ponding_area);
	}
	action define_properties {
		unity_aspect sewer_system_aspect <- geometry_aspect(1.0,#gray,precision);
		up_sewer_system <- geometry_properties("sewer_system","sewer_system",sewer_system_aspect,#no_interaction,false);
		unity_properties << up_sewer_system;


		unity_aspect filter_media_aspect <- geometry_aspect(1.0,#gray,precision);
		up_filter_media <- geometry_properties("filter_media","filter_media",filter_media_aspect,#no_interaction,false);
		unity_properties << up_filter_media;


		unity_aspect rain_aspect <- geometry_aspect(1.0,#gray,precision);
		up_rain <- geometry_properties("rain","rain",rain_aspect,#no_interaction,false);
		unity_properties << up_rain;


		unity_aspect programmed_maintenance_aspect <- geometry_aspect(1.0,#gray,precision);
		up_programmed_maintenance <- geometry_properties("programmed_maintenance","programmed_maintenance",programmed_maintenance_aspect,#no_interaction,false);
		unity_properties << up_programmed_maintenance;


		unity_aspect unmanaged_flow_aspect <- geometry_aspect(1.0,#gray,precision);
		up_unmanaged_flow <- geometry_properties("unmanaged_flow","unmanaged_flow",unmanaged_flow_aspect,#no_interaction,false);
		unity_properties << up_unmanaged_flow;


		unity_aspect managed_flow_aspect <- geometry_aspect(1.0,#gray,precision);
		up_managed_flow <- geometry_properties("managed_flow","managed_flow",managed_flow_aspect,#no_interaction,false);
		unity_properties << up_managed_flow;


		unity_aspect vegetation_cover_aspect <- prefab_aspect("Prefabs/Visual Prefabs/City/Vehicles/Car",1.0,0.0,1.0,0.0,precision);
		up_vegetation_cover <- geometry_properties("vegetation_cover","vegetation_cover",vegetation_cover_aspect,#ray_interactable,false);
		unity_properties << up_vegetation_cover;


		unity_aspect vegetal_component_aspect <- prefab_aspect("Prefabs/Visual Prefabs/City/Vehicles/Car",1.0,0.0,1.0,0.0,precision);
		up_vegetal_component <- geometry_properties("vegetal_component","vegetal_component",vegetal_component_aspect,#no_interaction,false);
		unity_properties << up_vegetal_component;


		unity_aspect trees_aspect <- prefab_aspect("Prefabs/Visual Prefabs/City/Vehicles/Car",1.0,0.0,1.0,0.0,precision);
		up_trees <- geometry_properties("trees","trees",trees_aspect,#ray_interactable,false);
		unity_properties << up_trees;


		unity_aspect inlet_aspect <- geometry_aspect(1.0,#gray,precision);
		up_inlet <- geometry_properties("inlet","inlet",inlet_aspect,#no_interaction,false);
		unity_properties << up_inlet;


		unity_aspect engineered_component_aspect <- prefab_aspect("Prefabs/Visual Prefabs/City/Vehicles/Car",1.0,0.0,1.0,0.0,precision);
		up_engineered_component <- geometry_properties("engineered_component","engineered_component",engineered_component_aspect,#ray_interactable,false);
		unity_properties << up_engineered_component;


		unity_aspect natural_environment_aspect <- geometry_aspect(1.0,#gray,precision);
		up_natural_environment <- geometry_properties("natural_environment","natural_environment",natural_environment_aspect,#no_interaction,false);
		unity_properties << up_natural_environment;


		unity_aspect NBSS_aspect <- prefab_aspect("Prefabs/Visual Prefabs/City/Vehicles/Car",1.0,0.0,1.0,0.0,precision);
		up_NBSS <- geometry_properties("NBSS","NBSS",NBSS_aspect,#ray_interactable,false);
		unity_properties << up_NBSS;


		unity_aspect default_aspect <- geometry_aspect(1.0,#gray,precision);
		up_default <- geometry_properties("default","",default_aspect,#no_interaction,false);
		unity_properties << up_default;


		unity_aspect component_aspect <- prefab_aspect("Prefabs/Visual Prefabs/City/Vehicles/Car",1.0,0.0,1.0,0.0,precision);
		up_component <- geometry_properties("component","component",component_aspect,#ray_interactable,false);
		unity_properties << up_component;


		unity_aspect ext_time_failure_aspect <- geometry_aspect(1.0,#gray,precision);
		up_ext_time_failure <- geometry_properties("ext_time_failure","ext_time_failure",ext_time_failure_aspect,#no_interaction,false);
		unity_properties << up_ext_time_failure;


		unity_aspect ext_metric_failure_aspect <- geometry_aspect(1.0,#gray,precision);
		up_ext_metric_failure <- geometry_properties("ext_metric_failure","ext_metric_failure",ext_metric_failure_aspect,#no_interaction,false);
		unity_properties << up_ext_metric_failure;


		unity_aspect failure_event_aspect <- geometry_aspect(1.0,#gray,precision);
		up_failure_event <- geometry_properties("failure_event","failure_event",failure_event_aspect,#no_interaction,false);
		unity_properties << up_failure_event;


		unity_aspect output_flow_aspect <- geometry_aspect(1.0,#gray,precision);
		up_output_flow <- geometry_properties("output_flow","output_flow",output_flow_aspect,#no_interaction,false);
		unity_properties << up_output_flow;


		unity_aspect rtf_maintenance_aspect <- geometry_aspect(1.0,#gray,precision);
		up_rtf_maintenance <- geometry_properties("rtf_maintenance","rtf_maintenance",rtf_maintenance_aspect,#no_interaction,false);
		unity_properties << up_rtf_maintenance;


		unity_aspect outlet_aspect <- geometry_aspect(1.0,#gray,precision);
		up_outlet <- geometry_properties("outlet","outlet",outlet_aspect,#no_interaction,false);
		unity_properties << up_outlet;


		unity_aspect urban_environment_aspect <- geometry_aspect(1.0,#gray,precision);
		up_urban_environment <- geometry_properties("urban_environment","urban_environment",urban_environment_aspect,#no_interaction,false);
		unity_properties << up_urban_environment;


		unity_aspect ponding_area_aspect <- prefab_aspect("Prefabs/Visual Prefabs/City/Vehicles/Car",1.0,0.0,1.0,0.0,precision);
		up_ponding_area <- geometry_properties("ponding_area","ponding_area",ponding_area_aspect,#no_interaction,false);
		unity_properties << up_ponding_area;


	}
	reflex send_geometries {
		do add_geometries_to_send(unmanaged_flow,up_unmanaged_flow);
		do add_geometries_to_send(output_flow,up_output_flow);
		do add_geometries_to_send(managed_flow,up_managed_flow);
		do add_geometries_to_send(outlet,up_outlet);
	}
	
	action maintenance_remove(string id) {
		agent ag <- (trash + weeds + leaves + grass) first_with (each.name = id) ;
		if (ag != nil) {
			ask ag {
				remove key: self from: myself.geometries_to_send;
				do die;
			}
		}
	}
	action maintenance_repair(string id) {
		component ag <- (engineered_component + vegetal_component) first_with (each.name = id) ;
		if (ag != nil) {
			ask ag {
				if function_attributes["my_health"] < 3 {
					function_attributes["my_health"] <- function_attributes["my_health"] + 1;
				}
				else {
					function_attributes["my_health"] <- function_attributes["my_health"] - 1;
				}
				price <- price + 1;
			}
		}
	}
	action add_veg(string id) {
		agent ag <- (shrubs + grass + trees) first_with (each.name = id) ;
		if (ag != nil) {
			ask ag {
				create ag;
				add ag to: myself.geometries_to_send; //pas sûre
			}
		}
	}
	action water_plants(string id) {
		if (current_season = "summer" and time_since_last_water >= 2) {
			
		}
	}
}

species trash {}

species weeds {}

species soil parent: NBSS { // définir apparence/localisation/matière
}

species gravel parent: NBSS {}

species microorganisms parent: soil {}

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
}

experiment vr_xp parent:"Interface (EN)" autorun: false type: unity {
	float minimum_cycle_duration <- 0.1;
	string unity_linker_species <- string(unity_linker);
	list<string> displays_to_hide <- ["Flooding","Degraded vegetation days","Maintenance days","Accepted flood"];
	float t_ref;

	action create_player(string id) {
		ask unity_linker {
			do create_player(id);
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
		 display Rain_VR parent:"Rain" {
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

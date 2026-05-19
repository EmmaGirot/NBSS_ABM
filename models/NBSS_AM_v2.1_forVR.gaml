/**
* Name: NBSSAM
* Based on the internal empty template. 
* Author: egirot
* Tags: 
* 
*/

/* 
 * to run this version you'll need the following files from the includes folder :
 * output_flow_LT.csv
 * maintenance_programmed.csv
 * 	in the climate folder : 
 * climate_spei.csv
 * weather_input_gama.csv
 * 	in the failures folder : 
 * ext_metric_failures.csv
 * ext_time_failures.csv
*	in the maintenance_practices folder
 * MP_pos_impact.csv
 * MP_neg_impact_seasons.csv

 * 
 * Changes made are : 
 * - grass and shrubs_plants are no longer 2 different agents but one called vegetation_cover
 * - negative impact of maintenance practices if not carried out during targeted seasons as written in MP_Seasons.csv
 * - negative impact of maintenance practices if frequency is too high compared to failure frequency 
 * 
 * TODO :
 * - call R from GAMA for spei calculation  
 * - add randomness in the days of week in which ext_failures are triggered
 */

model NBSSAM

//******************** GLOBAL *****************************************
global {
	// gestion espace libre
	
	//geometry free_space <- copy(shape);
	geometry init_free_space <- rectangle(100,100);
	geometry free_space <- init_free_space;
	
	//geometry free_space;
	
	
	
	int price <- 0;
	int time_since_last_water <- 5; //à définir
	bool is_failure_event <- false;
	//geometry zone_NBSS <- rectangle(30, 20) at_location global_zone.location; // zone NBSS
	//geometry global_zone <- rectangle(50,40);
	float step <-1 #day;
	float step1 <- 1.0;
	
	// Setting simulation timeline
	date starting_date <- date(string(int(weather_data[0,0])));  // starting date of simulation;
	date end_date <- date(string(int(weather_data[0,length(rows_list(weather_data))-1])));
	float simulation_duration <- float((years_between(starting_date,end_date)));
	
		// Loading csv rainfall and spei file
	file weather_file <- csv_file("../includes/climate/weather_input_gama.csv",",");
	matrix weather_data <- matrix(weather_file);
	
	// TODO : create spei_file according to weather_file by calling R from GAMA
	file spei_file <- csv_file("../includes/climate/climate_spei.csv",",");
	matrix spei_data <- matrix(spei_file);
	
	// Defining seasons
	string current_season;
	int y <- year(current_date);
	date season_end;
	date season_start;
	reflex season_update {
		
		if (month(current_date)=12 or month(current_date)<=2){
			current_season <- "winter";
			season_start <- date(string(y)+ "-12-01");
			season_end <-date(string(y+1) + "-02-28");
		}
		if (month(current_date)>=3 and month(current_date)<=5){
			current_season<- "spring";
			season_start <- date(string(y)+ "-03-01");
			season_end <-date(string(y) + "-05-31");
		}
		if (month(current_date)>=6 and month(current_date)<=8){
			current_season <- "summer";
			season_start <- date(string(y)+ "-06-01");
			season_end <-date(string(y) + "-08-31");
		}
		if (month(current_date)>=9 and month(current_date)<=11){
			current_season <- "fall";
			season_start <- date(string(y)+ "-09-01");
			season_end <-date(string(y) + "-11-30");
		}
	}
	

	// Loading csv files that has the logic table which calculates the output flow depending on input and condition values
	file output_flow_LT_file <- csv_file( "../includes/output_flow_LT.csv",';',int);
	bool end_sim<-false;
		
	// maintenance parameters 
	string maintenance_type <- "programmed";// parameter: maintenance_type among:["no maintenance", "run-to-failure", "programmed"];
	int intervention_delay_days <- 5;// parameter:true  min:2 max: 30;
	
	//performance parameters
	int days_maintained <- 0;
	int days_accepted_flood <- 0;
	int days_flooding <- 0;
	int days_vegetation_degraded <- 0; 
	
	init {
		
//		point pt1 <- {25, 25};
//		point pt2 <- {100, 25};
//		point pt3 <- {100, 100};
//		point pt4 <- {25, 100};
//		
//		free_space <- union([
//		    pt1 buffer 15,
//		    pt2 buffer 15,
//		    pt3 buffer 15,
//		    pt4 buffer 15,
//		    line([pt1, pt2]) + 8,
//		    line([pt2, pt3]) + 8,
//		    line([pt3, pt4]) + 8,
//		    line([pt4, pt1]) + 8
//		]);
		
		// Initialization of Rain agent : 
		create rain {
			create managed_flow{
				my_component<- myself;
				myself.runoff <- self;
			}
		}
		// Initialization of NBSS and all its components :
		create NBSS {
			shape <- rectangle(30, 20);
			location <- any_location_in(free_space buffer -15.0);
			//location <- {location.x, location.y, location.z - 1.0};
			free_space <- free_space - (shape + 0.5);
			
			my_name <- "Swale1";
			//location <- {25.0, 25.0, 0.0};
			//write global_zone.location;
			create swale number: 2 { // faire apparaître la tranchée
				shape <- rectangle(30, 6);
				list<point> list_of_positions <- [{myself.location.x, myself.location.y + 7, myself.location.z}, {myself.location.x, myself.location.y - 7, myself.location.z}];
				location <- list_of_positions[index];
				free_space <- free_space - (shape + 0.5);
			}
			
			create inlet {
				shape <- circle(1);
				location <- {myself.location.x - 13.0, myself.location.y, 0};
				free_space <- free_space - (shape + 0.5);
				//location <- any_location_in(zone_NBSS.contour) + {0.0, 0.0, 1.0};
				//location <- any_location_in(line(zone_NBSS.points));
//				loop while: (self distance_to one_of(inlet)) < 0.5 {
//				    location <- any_location_in(line(zone_NBSS.points));
//				}
				
				//write zone_NBSS.contour;
				my_name<-"inlet";
				my_NBSS<- myself;
				my_color <- #antiquewhite;
				my_downstream_comp <- my_NBSS.my_ponding_area;
				myself.my_inlet <- self;
				add self to:myself.my_engineered_components;
				create managed_flow{
					my_component <- myself;
					myself.my_output_managed_flow <- self;
				}
				create unmanaged_flow {
					my_component <- myself;
					myself.my_output_unmanaged_flow <- self;
	
				}
			}
			create ponding_area  {
				shape <- rectangle(30, 8);
				location <- {myself.location.x, myself.location.y, 0}; //z+1.75
				free_space <- free_space - (shape + 0.5);
				
				my_name<-"ponding_area";
				my_NBSS<- myself;
				my_color <- #antiquewhite;
				my_upstream_comp <- my_NBSS.my_inlet ;
				my_downstream_comp <- my_NBSS.my_filter_media;
				myself.my_ponding_area <- self;
				add self to:myself.my_engineered_components;
				create managed_flow{
					my_component <- myself;
					myself.my_output_managed_flow <- self;
				}
				create unmanaged_flow {
					my_component <- myself;
					myself.my_output_unmanaged_flow <- self;
				}		
		
			}
			create vegetation_cover {
				my_name<-"vegetation_cover";
				my_NBSS<- myself;
				create grass number: rnd(0, 20) {
					//location <- any_location_in(zone_NBSS);
				}
				create shrubs_plants number: rnd(0,3) {
					//location <- any_location_in(zone_NBSS);
				}
			}
			create trees {
				
				
				my_name <- "trees";
				my_NBSS<- myself;
				//location <- any_location_in(zone_NBSS) + {0.0, 0.0, 1.0};
			}
			create filter_media {
				//location <- zone_NBSS.location + {0.0, 0.0, -1.0};
				shape <- rectangle(30,20);
				location <- {myself.location.x, myself.location.y, myself.location.z-1.0};
				free_space <- free_space - (shape + 0.5);
				
				my_name<-"filter_media";
				my_NBSS<- myself;
				my_color <- #antiquewhite;
				my_upstream_comp <- my_NBSS.my_ponding_area;
				my_downstream_comp <- my_NBSS.my_outlet;
				myself.my_filter_media <- self;
				add self to:myself.my_engineered_components;
				create managed_flow{
					my_component <- myself;
					myself.my_output_managed_flow <- self;
				}
				create unmanaged_flow {
					my_component <- myself;
					myself.my_output_unmanaged_flow <- self;
				}
			}
		
			
			create outlet{
				//location <- any_location_in(zone_NBSS.contour);
//				loop while: (self distance_to one_of(inlet)) < 0.5 {
//				    location <- any_location_in(zone_NBSS.contour);
//				}
				shape <- circle(1);
				location <- {myself.location.x + 13.0, myself.location.y, 0};
				free_space <- free_space - (shape + 0.5);
				
				my_name <- "outlet";
				my_NBSS<- myself;
				my_color <- #antiquewhite;
				my_upstream_comp <- my_NBSS.my_filter_media;
				my_impacted_agents <- ["Sewer system", "Receiving natural environment"];
				myself.my_outlet <- self;
				add self to:myself.my_engineered_components;
				create managed_flow{
					my_component <- myself;
					myself.my_output_managed_flow <- self;
				}
				create unmanaged_flow {
					my_component <- myself;
					myself.my_output_unmanaged_flow <- self;
				}
			}
			create gravel {
				shape <- rectangle(30,20);
				location <- {myself.location.x, myself.location.y, myself.location.z-2.0};
				free_space <- free_space - (shape + 0.5);
			}
			my_components <- my_engineered_components union my_vegetal_components;	
			
		}
		create urban_environment {
			my_name <- "Urban environment";
			create unmanaged_flow{
				my_component<- myself;
				myself.overflow <- self;
			}
			
		}
		
		create sewer_system{
			my_name <- "Sewer system";
		}
		
		create natural_environment{
			my_name <- "Receiving natural environment";
		}
	
		create failure_event {}
		// The following 2 csv files contain failure event parameters.
		// Here I am creating as many failure events agent as there are lines in the CSV file.
		create ext_time_failure from:csv_file( "../includes/failures/ext_time_failures.csv",';',true) with:
			[my_name::string(get("failure_name")), 
				season_dep::bool(get("season_dep")),
				my_frequency::float(get("frequency_weeks")),
				my_winter_factor::int(get("winter_factor")),
				my_spring_factor::int(get("spring_factor")),
				my_summer_factor::int(get("summer_factor")),
				my_fall_factor::int(get("fall_factor")),
				impacted_agent::string(get("impacted_agent")),
					impacted_attribute::string(get("impacted_attribute"))
			];
		create ext_metric_failure from:csv_file( "../includes/failures/ext_metric_failures.csv",';',true) with:
				[my_name::string(get("failure_name")), 
				impacted_agent::string(get("impacted_agent")),
				impacted_attribute::string(get("impacted_attribute")),
					my_threshold::int(get("threshold"))

			];
		create trash number: rnd(0,10) {
			//location <- any_location_in(global_zone);
		}
		create weeds number: rnd(0,10) {
			//location <- any_location_in(global_zone);
		}		

		// The maintenance_practices.csv file contains maintenance practices parameters
		// Here I am creating as many maintenance practice agent as there are lines in the CSV file. 
		if maintenance_type = "programmed" {
			create programmed_maintenance from:csv_file( "../includes/maintenance_programmed.csv",';',true) with:
				[practice_name::string(get("practice_name")), 
					maintenance_frequency::float(get("practice_frequency_weeks")), 
					prog_season_dep::bool(get("season_dep")),
					prog_target_season::list<string>(get("target_season")),
					department::string(get("department")),
					cost::float(get("cost_euros"))
				];	
		}
		if maintenance_type = "run-to-failure" {
			create rtf_maintenance;
		}
		
		
	}
		
	
	reflex NBSS_functioning{
			// first, compute inlet output flow and associated pollutant loads with runoff as input flow
			ask any(inlet){ 
				do update_output_flows(any(rain).runoff.my_flow);
			}
			ask any(ponding_area) {
				do flow_downstream;
			}
	
		}
			
	reflex stop_simulation when: current_date > end_date {
		end_sim<-true;
		do pause;
	}
}

//************************ SPECIES DECLARATION ***************************
/* Added species for VR sim */
species trash {
	aspect default {
		draw circle(1) border:#black color:#red;
	}
}

species weeds {
	aspect default {
		draw circle(1) border:#black color:#green;
	}
}

species gravel parent: NBSS {
	aspect default {
		draw rectangle(80,55) border:#black color:#black;
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -31, -2} anchor: #top_center;
	}
}

//species microorganisms parent: filter_media {} //also bees, pollen, different kinds of plants

species vegetal_waste {
	aspect default {
		draw square(3) border:#black color:#red;
	}
}

/* Declaration of the rain species */
species rain {
	float rainfall;
	managed_flow runoff;
	date last_rain;
	list<int> runoff_history <- [];

	reflex create_runoff {
		runoff.my_flow <- 0.0;
		loop i from:0 to:weather_data.rows-1 {
			if current_date = date(string(int(weather_data[0,i]))) {
				//Rainfall event <= 20mm in a day are considered as a runoff flow of 1
				if (float(weather_data[1,i]) <= 20.0 and float(weather_data[1,i]) > 5.0) {
					runoff.my_flow <- 1.0;
				}
				//Rainfall event between 20mm and 80mm in a day are considered as a runoff flow of 2
				if (float(weather_data[1,i]) > 20.0 and float(weather_data[1,i]) <= 80.0 ) {
					runoff.my_flow <- 2.0;
				}
				//Rainfall event > 80mm in a day are considered as a runoff flow of 3
				if (float(weather_data[1,i]) > 80.0 ) {
					runoff.my_flow <- 3.0;
				}
			rainfall <- - float(weather_data[1,i]);
			}
		
			
		}
		add(runoff.my_flow) to: runoff_history;
			if (runoff.my_flow != 0) {
				last_rain <- current_date;
			}	
	}
}

/* Declaration of the species NBSS */
species NBSS {
	string my_name;
	inlet my_inlet; 
	ponding_area my_ponding_area;
	filter_media my_filter_media; 
	outlet my_outlet;
	trees my_trees;
	list<engineered_component> my_engineered_components;
	list<vegetal_component> my_vegetal_components;
	list<component> my_components;
	


	
	aspect default {
		draw rectangle(30, 20) color: #white;
		//draw rectangle(80,55) border:#black color:#white;
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -31, 1} anchor: #top_center;
	}
	

}

species swale parent: NBSS {
	
}

/* Declaration of the parent species component */
species component {
	NBSS my_NBSS; //to which NBSS this component belongs	
	string my_name;
	output_flow my_output_managed_flow;
	output_flow my_output_unmanaged_flow;
	rgb my_color;
	list<failure_event> my_failures ;
	map <string,int> function_attributes;
	component my_upstream_comp;
	component my_downstream_comp;
	list<string> my_impacted_agents;
	bool rtf_state <- false; //run-to-failure state
	int PV_health <- 10;

	action flow_downstream {
		do update_output_flows(my_upstream_comp.my_output_managed_flow.my_flow);

		ask my_NBSS.my_engineered_components where(each.my_upstream_comp = self) {
			do flow_downstream;
		}
	}

	action update_output_flows (float current_inflow){
		matrix data <- matrix(output_flow_LT_file);
		//loop on the matrix rows (skip the first header line)
	 	loop i from: 0 to: data.rows -1 {
			if (data[0,i] = int(function_attributes["my_fqt"]) and data[1,i] = int(current_inflow)){
				my_output_managed_flow.my_flow <- float(data[2,i]);
				my_output_unmanaged_flow.my_flow <- float(data[3,i]);	
			}
		}
		
	}
	

}

/**************************** PARENT : ENGINEERED COMPONENTS*****************************************/

species engineered_component parent: component {
	map <string,int> function_attributes <- ["my_fqt"::3];
	
	// critical state that will lead to run-to-failure maintenance
	reflex eng_critic_state when: (function_attributes["my_fqt"]=0) and (rtf_state=false){
		rtf_state <- true;
		create rtf_maintenance {
			impacted_component <- myself;
			rtf_state_date <- current_date;
		}
		
	}
}
	

/********************************************** INLET ***************************************/
species inlet parent: engineered_component {
	int type <- function_attributes["my_fqt"];
	
	aspect default {
		draw circle(4) border:#black color:my_color;
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -7, 1} anchor: #top_center;
		//draw line([ponding_area(0).location -0.01,self.location + 3]) color: #dodgerblue begin_arrow: 2 end_arrow: -7 width: 2.0;
	}
	
	reflex accepted_flood when: (my_output_unmanaged_flow.my_flow =3){
		days_accepted_flood <- days_accepted_flood +1 ;
	}
	
	reflex flooding when: (my_output_unmanaged_flow.my_flow >= 1 and my_output_unmanaged_flow.my_flow <3){
		days_flooding <- days_flooding +1 ;
	}
}

/******************************************** PONDING AREA ********************************************/
species ponding_area parent: engineered_component {
	bool temporary<-true;
	bool ponding <- false;
	
	//unusual ponding occurs when filter media has an output_unmanaged_flow
	reflex unusual_ponding when: (current_date < starting_date) and (my_downstream_comp.my_output_unmanaged_flow.my_flow>=1) and (ponding=false){
		function_attributes["my_fqt"] <- max(0,function_attributes["my_fqt"]-1);
		ponding <- true;
		create failure_event {
			my_name <- "unusual_ponding";
			impacted_agent <- my_name;
			impacted_attribute <- "my_fqt";	
			last_failure <- current_date;
			ask agents of_generic_species component where (each.my_name=impacted_agent) {	
				add myself to: my_failures;
			}
		}		
	}
	
	// if there hasn't been any runoff >= 2 for the next 2 days after an unsual ponding event, ponding ends
	reflex ponding_ended when: (ponding=true){
		ask rain {
			if (sum(copy_between(runoff_history, length(runoff_history) - 2 ,length(runoff_history))))>= 4{
				ask myself {
					function_attributes["my_fqt"] <- min(3,function_attributes["my_fqt"]+1);
					ponding <- false;
					save [current_date,"ponding_ended",my_name,"my_fqt"] to: "../results/failures.csv" format:"csv" rewrite: false;
				}
			}
		}
		

	}	
		

	aspect default {
		draw ellipse(30,5) border:#blue color:my_color ;
		draw my_name color:#black  font:font("Helvetica", 12, #bold) at: location anchor: #center;
	
	}
	
}

/************************************************** FILTER MEDIA **********************************************/
species filter_media parent: engineered_component {
//	aspect default {
//		draw rectangle(30, 20) color: #pink;
//	}
	
	float partpoll_acc <- 0.0;
	
	// sediment accumulation dynamic = 0.3 cm/year (Chabert et al., 2025) 
	reflex partpoll_accumulation when: every(1 #year) and (current_date > starting_date){
		partpoll_acc <- partpoll_acc + 0.3;
	}
	
	//when filter_media is getting clogged (because of sediment accumulation or excess veg), vegetation health is impacted
	reflex clogged_fm when: (function_attributes["my_fqt"] <=1) and every(2# week){
		ask agents of_generic_species vegetal_component {
			do clogged_fm_on_veg;
		}
	}
	
	//when vegetation is unhealthy, infiltration performance of filter media is impacted
	action unhealthy_veg_on_fm {
		function_attributes["my_fqt"] <- max(0,function_attributes["my_fqt"]-0.25);
		create failure_event {
			my_name <- "unhealthy_veg_on_fm";
			impacted_agent <- "filter_media";
			impacted_attribute <- "my_fqt";
			last_failure <- current_date;
			ask agents of_generic_species component where (each.my_name=impacted_agent) {	
				add myself to: my_failures;
			}
		}
		
	}

//	aspect default {
//		draw rectangle(30,5) border:#sienna color:my_color;
//		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location anchor: #center;
//	}
}


/***************************************************** OUTLET *************************************/
species outlet parent: engineered_component {
	aspect default {
		draw circle(4) border:#black color:my_color;
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -7, 1} anchor: #center;
	}
}



/**************************************** PARENT : VEGETAL COMPONENTS*************************************************/

species vegetal_component parent: component {
	bool climate_stress <- false;

	// find the min and max of the list of spei3 for each season 
	reflex spei3_season when: (current_date.month = 2 or current_date.month=5 or current_date.month=8 or current_date.month=11)  and current_date.day = 1 {
		loop i from:0 to:spei_data.rows-1 {
			if current_date = date(string(int(spei_data[0,i]))){
				float max_spei3_season <- max(float(spei_data[2,i]),float(spei_data[2,i-1]), float(spei_data[2,i-2]));
				float min_spei3_season <- min(float(spei_data[2,i]),float(spei_data[2,i-1]), float(spei_data[2,i-2]));
				if (max_spei3_season >= 1.5) { // water stress/drowning
					do dying(); 
					create failure_event {
						my_name <- "water_stress";
						impacted_agent <- my_name;
						impacted_attribute <- "my_health";
						last_failure <- current_date;
						ask agents of_generic_species component where (each.my_name=impacted_agent) {	
							add myself to: my_failures;
						}
					}
					climate_stress <- true;
				}
				if (min_spei3_season <= -1.5 and current_season!= "winter") { // drought stress - we do not consider drought stress in winter
					do dying();
					create failure_event {
						my_name <- "drought_stress";
						impacted_agent <- my_name;
						impacted_attribute <- "my_health";
						last_failure <- current_date;
						ask agents of_generic_species component where (each.my_name=impacted_agent) {	
							add myself to: my_failures;
						}
					}climate_stress <- true;
				}
				else { // if no drought or water stress, my_health is increased by 1 or maintained at 3
					do recovering();
					
				}
			}
		}
			
	}
	
	action dying {
		function_attributes["my_health"] <- max(0,function_attributes["my_health"] -1);
			
	}
	
	action recovering {
		if (climate_stress = true) and (function_attributes["my_health"]!= 0) {
			function_attributes["my_health"] <- min(3,function_attributes["my_health"] +1);	
			climate_stress <- false;
		}
	}
	
	//when filter_media is getting clogged (because of sediment accumulation), vegetation health is impacted
	action clogged_fm_on_veg {
		function_attributes["my_health"] <- max(0,function_attributes["my_health"] - 0.25);
		create failure_event {
			my_name <- "clogged_fm_on_veg";
			impacted_agent <- my_name;
			impacted_attribute <- "my_health";
			last_failure <- current_date;
			ask agents of_generic_species component where (each.my_name=impacted_agent) {	
				add myself to: my_failures;
			}
		}
		
	}
	
	// critical state that will lead to run-to-failure maintenance
	reflex veg_critic_state when: (function_attributes["my_health"]=0) and (rtf_state=false){
		rtf_state <- true;	
		create rtf_maintenance {	
			impacted_component <- myself;
			rtf_state_date <- current_date;
		}
		
	}
	
}


/***************************************************** GRASS *******************************************/

species grass parent: vegetal_component {
	map <string,int> function_attributes <- ["my_health"::3,"my_diversity"::3];
	aspect default {
		draw square(1) border: #black color: #lightgreen;
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -5, 1} anchor: #top_center;
	}
}

/***************************************************** SHRUBS and PLANTS *******************************************/

species shrubs_plants parent: vegetal_component {
	map <string,int> function_attributes <- ["my_health"::3,"my_diversity"::3];
	aspect default {
		//draw rectangle(10,10) at: my_surface.location + {0,-5,1};
		//draw shrubs_plants_image size: {20.0, 12.0, 0.0} at: my_surface.location + {8, -8, 1};
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -8, 1} anchor: #top_center;
	}
	
}

/***************************************************** TREES *******************************************/

species trees parent: vegetal_component {
	map <string,int> function_attributes <- ["my_health"::3];
	aspect default {
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -12, 1} anchor: #top_center;
	}
}

/******************************************* VEGETATION COVER***********************************************/

// Vegetation cover , can be made of one or multiple vegetal components
species vegetation_cover parent: component {
	map <string,int> function_attributes <- ["my_health"::3,"my_diversity"::3];
	bool invasive <- false; //!!! weeds nécessaire ?

	// when the vegetation cover's global health reaches 1, it impacts the filter media "my_fqt" attribute by -0.25 every month
	reflex unhealthy_veg when: (function_attributes["my_health"]<=1) and every(1 #month) {
		ask any(filter_media){
			do unhealthy_veg_on_fm;
		}
	}
	
	// if invasive_plants impacted vegetation_cover than the "excess_veg" failure trigger frequency in ext_failures will go from every year in spring to once a season (expect for winter)
	reflex invasive_taking_over when: (invasive=true) {
		ask ext_time_failure where (my_name="excess_veg"){
				season_dep <- true;
				my_frequency <- 12.0;
				my_winter_factor<- 0;
				my_spring_factor <-1;
				my_summer_factor <- 1;
				my_fall_factor<- 1;
		}
		invasive <- false;
	}
	
	reflex degraded when: ((function_attributes["my_diversity"]<=1) or (function_attributes["my_health"]<= 1)){
		days_vegetation_degraded <- days_vegetation_degraded +1;
	}
	
}

/***************************************************** URBAN ENVIRONMENT *******************************************/

species urban_environment {
	string my_name;
	rgb my_color;
	unmanaged_flow overflow;

		reflex update_color {
		// what color should I use for the urban environment since it doesn't have a "condition" ? 
		//my_color<-condition_color[overflow];	
	}
	
	action update_overflow(float input_flow){
		overflow.my_flow <- input_flow;
	}
	
	aspect default {
		draw rectangle(100,75) border:#sienna color:#tan ;
		draw my_name font:font("Helvetica", 12, #bold) color:#sienna at: location + {0, -41, 1} anchor: #top_center;
	}
	
}

/***************************************************** SEWER SYSTEM *******************************************/

species sewer_system {
	string my_name;
	aspect default {
		draw circle(10) border:#black color:#grey;
		draw my_name font:font("Helvetica", 12, #bold) color:#black at: location + {0, -13, 1} anchor: #top_center;
	}
}


/***************************************************** NATURAL ENVIRONMENT *******************************************/

species natural_environment {
	string my_name;
	aspect default {
		draw circle(10) border:#black color:#grey;
		draw my_name font:font("Helvetica", 12, #bold) color:#black at: location + {0, -13, 1} anchor: #top_center;
	}
}


/***************************************************** PARENT : OUTPUT FLOW *******************************************/

species output_flow {
	agent my_component;
	float my_flow;
		
}

/***************************************************** MANAGED OUTPUT FLOW *******************************************/
species managed_flow parent: output_flow {


}


/***************************************************** UNMANAGED OUTPUT FLOW *******************************************/
species unmanaged_flow parent: output_flow {
	
}


/***************************************************** FAILURE EVENT *******************************************/
species failure_event{
	string my_name;
	string impacted_agent;
	string impacted_attribute;
	date last_maintenance <- starting_date;	
	date last_failure <- starting_date;
	bool failure_happened <- false;

	// impact of a failure event on attributes
	action failure_impact (failure_event failure) {
		ask agents of_generic_species component where (each.my_name=failure.impacted_agent){
			function_attributes[failure.impacted_attribute] <- max(0,function_attributes[failure.impacted_attribute]-1);
			// debug
			write function_attributes[failure.impacted_attribute];
			write failure.impacted_agent;
			if self is inlet {
				write inlet(self).type;
				write function_attributes["my_fqt"];
			}
			// fin debug
			failure.last_failure <- current_date;
			add myself to:self.my_failures;
			is_failure_event <- true;
		}
	}
	
	reflex failure_happened when: (failure_happened = true) and (last_failure != current_date) {
		failure_happened <- false;
	}
	
	reflex failure_happening when:(last_failure = current_date) and (last_failure > starting_date) and (failure_happened = false) {	
		write my_name + " on " + impacted_agent + " on " + string(current_date,"dd MM yyyy");
		failure_happened <- true;

	}
	

	
}

/**********************  External factor failures - trash, leaf accumulation, excessive vegetation, invasive plants etc.. *****************************************/

species ext_time_failure parent: failure_event {
	float my_frequency;
	bool season_dep; //=false if the failure is not season-dependent i.e. frequency is given in weeks per simulation_duration; =true when season-dependent and frequency is given according to weeks in the season
	
	// failure occurence can depend of the season, seasonal_factor will take one of the four following values according to the current_season 
	int my_winter_factor;
	int my_spring_factor;
	int my_summer_factor;
	int my_fall_factor;
	int seasonal_factor;
	
	reflex update_seasonal_factor {
		if (current_season = "winter") {
			seasonal_factor <- my_winter_factor;
		}
		if (current_season = "spring") {
			seasonal_factor <- my_spring_factor;
		}
		if (current_season = "summer") {
			seasonal_factor <- my_summer_factor;
		}
		if (current_season = "fall") {
			seasonal_factor <- my_fall_factor;
		}
	}
	
	reflex ext_time_trigger when: (current_date!=starting_date) {
		if (season_dep = false) {
			loop i from:1 to: (simulation_duration*52)/(my_frequency) {
				if (current_date=last_maintenance + (i*my_frequency #week)){
					// Some failures occur under conditions : excess_veg on inlet if vegetation_cover.my_health >= 2 and invasive_plants if vegetation_cover.my_health <= 1
					if (my_name="excess_veg"){
						ask any(vegetation_cover) {
							if (function_attributes["my_health"] >= 2) {
								ask myself {
									do failure_impact(self);
								}
							}
						}
						
					}
					if (my_name="invasive_plants"){
							ask any(vegetation_cover) {
								invasive <- true;
								if (function_attributes["my_health"] <= 1) {
									ask myself {
										do failure_impact(self);
									}
							}
						}
						
					}
					else if (my_name!= "invasive_plants" and my_name != "excess_veg"){
							do failure_impact(self);
					}
				}
			}	
		}
		if (season_dep = true and seasonal_factor != 0) {
			int season_duration_weeks <-int((season_end - season_start) / (7 * 24 * 3600));
			loop i from:1 to: (simulation_duration*4) step: (season_duration_weeks /(my_frequency*seasonal_factor)){
				if (current_date=last_maintenance + (i*my_frequency #week)){
					// Some failures occur under conditions : excess_veg on inlet if vegetation_cover.my_health >= 2 and invasive_plants if vegetation_cover.my_health <= 1
					if (my_name="excess_veg"){
						ask any(vegetation_cover) {
							if (function_attributes["my_health"] >= 2) {
								ask myself {
									do failure_impact(self);
								}
							}
						}
						
					}
					if (my_name="invasive_plants"){
							ask any(vegetation_cover) {
								invasive <- true;
								if (function_attributes["my_health"] <= 1) {
									ask myself {
										do failure_impact(self);
									}
							}
						}
						
					}
					else if (my_name!= "invasive_plants" and my_name != "excess_veg"){
							do failure_impact(self);
					}
				}
			}	

		}
	}
}



/**********************  External failures based on metric values : sediment accumulation on filter media *****************************************/

species ext_metric_failure parent: failure_event {
	float my_value; // accumulation value
	int my_threshold;  // threshold that leads to failure
	int my_iteration <- 1; 
	
	reflex get_metric_value {
		ask agents of_generic_species component where (each.my_name=impacted_agent) {
			myself.my_value <- self get myself.my_name; 
		}
	}
	
	reflex ext_metric_trigger when: (my_value >= my_iteration*my_threshold){
		if (current_date != last_failure) {
			do failure_impact(self);
			}
			my_iteration <- my_iteration +1;	
		}	
	}
	
/***************************************************** MAINTENANCE PRACTICE *******************************************/

species programmed_maintenance  {
	// data from maintenance_programmed.csv
	string practice_name;
	float maintenance_frequency;
	string department;
	bool prog_season_dep; //some maintenance practices are season-dependent, i.e. they have a positive impact only if carried out during their target season(s)
	list<string> prog_target_season;
	float cost;
	
	
	list<failure_event> processed_failures;
	
	// 
	//Loading data from MP_pos_impact.csv which states what failures the MP responds to 
	file mapping_mp_failure <- csv_file("../includes/maintenance_practices/MP_pos_impact.csv",";");
	matrix mp_failure_map <- matrix(mapping_mp_failure);
	list<string> linked_failures; // failures for which the maintenance practice responds to 

	// Loading data from MP_neg_impact_seasons.csv which states if the MP can have a negative impact on a component and if it depends of the season during which it is carried out
	file mp_target_season <- csv_file("../includes/maintenance_practices/MP_neg_impact_seasons.csv",";");
	matrix mp_season_map <- matrix(mp_target_season);
	bool my_neg_impact; // true if the mp can have a negative impact on a component when carried out
	bool freq_sensitive; // true if the mp can have a negative impact on component when carried out too often
	bool season_sensitive;// true if the mp can have a negative impact if not carried out during a specific season
	list<string> my_target_seasons; // seasons during which the practice should be carried out or it will have a negative impact on "my_neg_impacted_attribute" or "my_neg_impacted_component"
	string my_neg_impacted_component;
	string my_neg_impacted_attribute;
	
	bool season_target_reached <- false;
	bool freq_target_reached <- false;
	
	//some maintenance practices are season-dependent, i.e. they have a positive impact only if carried out during their target season(s) 
	// this reflex checks if the season when the maintenance is carried out is the "correct" one
	reflex check_season_criteria when: (current_date=starting_date) {
		loop index_row from: 0 to: mp_season_map.rows -1 {
			if mp_season_map[0,index_row] = practice_name { // find the row corresponding to the maintenance practice in the mp_season map
				my_neg_impact <-mp_season_map[1,index_row];
				freq_sensitive <- mp_season_map[2,index_row];
				season_sensitive <- mp_season_map[3,index_row];
				loop index_column from:4 to: 6 { // columns 4 to 6 store the targeted seasons in MP_Season.csv
					add mp_season_map[index_column, index_row] to:my_target_seasons;
				}
				my_neg_impacted_component <- mp_season_map[7,index_row];
				my_neg_impacted_attribute <- mp_season_map[8,index_row];
			}
		}
	}
	
	// for each  maintenance practice created,create the list of linked_failures from failure_mp_map
	// TODO: make sure that if a maintenance practice is created it should have a linked failure to it OR create another option..
	reflex link_mp_to_failure when: (maintenance_type="programmed") and (current_date = starting_date) {
		loop index_column from: 0 to: mp_failure_map.columns -1 {
			if mp_failure_map[index_column,0] = practice_name { // find the column corresponding to the maintenance practice in the mp_failure map 
				loop index_row from:1 to: mp_failure_map.rows-1{ // 
					add mp_failure_map[index_column,index_row] to: linked_failures;
				}
			}

		}
	}

	reflex trigger_prog_maintenance when: (maintenance_type="programmed")and every(maintenance_frequency #week) and (current_date>starting_date){ 
		days_maintained <- days_maintained +1;
//		ask agents of_generic_species vegetal_component {
//			if length(my_failures)>=1{
//				loop j over:my_failures {
//					loop i over:myself.linked_failures {
//						if j.my_name=i{
//							ask j {
//								myself.function_attributes[impacted_attribute] <- min(3,myself.function_attributes[impacted_attribute]+1);
//								
//								//reset failure event frequency with maintenance date
//								 last_maintenance <- current_date; 
//								
//							}
//							add j to:myself.processed_failures;
//						} 
//					}
//				}
//			}remove myself.processed_failures from:my_failures;
//		}
		ask agents of_generic_species component {
			if length(my_failures)>=1{	
				loop j over:my_failures {
					loop i over:myself.linked_failures {
						if j.my_name =i{
							ask j {
								myself.function_attributes[impacted_attribute] <- min(3,myself.function_attributes[impacted_attribute]+1);
								//reset failure event frequency with maintenance date
								 last_maintenance <- current_date; 
								 if (impacted_agent = "filter_media") {
									ask myself.my_NBSS.my_filter_media{
									partpoll_acc <- 0.0;
								 }
								}
							}add j to:myself.processed_failures;
						}
					}
				}
			} remove myself.processed_failures from:my_failures;
		}
		// possible negative impact from maintenance practice if not carried out during target season
		if (my_neg_impact=true) {	
			if (season_sensitive=true) {
				loop k over:my_target_seasons {
					if current_season = k {	
						season_target_reached <- true;
					}
				}
			}
			if (freq_sensitive=true){
				ask agents of_generic_species component where (each.my_name=my_neg_impacted_component){
					if (function_attributes[myself.my_neg_impacted_attribute] <= 2){
						myself.freq_target_reached<-true;
					}
				}
			}
			if (season_target_reached = false and freq_target_reached=false){
				ask agents of_generic_species component where (each.my_name=my_neg_impacted_component){
					function_attributes[myself.my_neg_impacted_attribute]<-max(0,function_attributes[myself.my_neg_impacted_attribute]-1);
					write "negative impact of " + myself.practice_name + " on " + myself.my_neg_impacted_attribute + " of " + myself.my_neg_impacted_component;
				}
				
			}	

		}

	}

}

// run to failure maintenance agent
species rtf_maintenance  {
	component impacted_component;
	date rtf_state_date <- starting_date; 
	
	reflex trigger_rtf_maintenance when: (maintenance_type="run-to-failure") and (current_date = rtf_state_date + intervention_delay_days #day ) and (rtf_state_date !=starting_date) and (maintenance_type = "run-to-failure") {
			days_maintained <- days_maintained +1;
			ask agents of_generic_species vegetal_component where (each.my_name=impacted_component.my_name) {
				function_attributes["my_health"] <- 3.0;
				rtf_state <- false;
				//reset failure event frequency with maintenance date
				ask self.my_failures {
					last_maintenance <- current_date;
				}
			}
			ask agents of_generic_species engineered_component where (each.my_name=impacted_component.my_name) {
			//ask agents of_generic_species engineered_component where (each.critic_state=true){
				function_attributes["my_fqt"] <- 3 ;
				rtf_state <- false;
				if (my_name = "filter_media") {
					ask my_NBSS.my_filter_media{
						partpoll_acc <- 0.0;
				 	}
				}
				//reset failure event frequency with maintenance date
				ask self.my_failures  {
					last_maintenance <- current_date;
				}

			}
		}
}

//******************** EXPERIMENT  *****************************************
	
// Tests for sensitivity analysis	
experiment "tests" type: batch repeat:3 until:end_sim{
	parameter "maintenance" var: maintenance_type among:["no maintenance", "run-to-failure", "programmed"];
		output {
		monitor "Accepted flood" value: days_accepted_flood;
		monitor "Flooding" value: days_flooding;
		monitor "Degraded vegetation days" value:days_vegetation_degraded;
		monitor "Maintenance days" value:days_maintained;
		}
}

// Simple run of model without interface 
experiment "run" type: gui {
	output {
		monitor "Accepted flood" value: days_accepted_flood;
		monitor "Flooding" value: days_flooding;
		monitor "Degraded vegetation days" value:days_vegetation_degraded;
		monitor "Maintenance days" value:days_maintained;
		}
	
}

//TODO: display the environment with the different species so that xp is the one used in VR gama file

// Interface 
experiment "Interface (EN)"	type: gui {
	//parameter "maintenance type" var:maintenance_type among:["no maintenance", "run-to-failure", "programmed"];
	parameter "maintenance type" var:maintenance_type among:["no maintenance"];
	output {
		monitor "Accepted flood" value: days_accepted_flood;
		monitor "Flooding" value: days_flooding;
		monitor "Degraded vegetation days" value:days_vegetation_degraded;
		monitor "Maintenance days" value:days_maintained;
		display map {
			graphics "free_area" {
				draw free_space color: #lightgreen;
			}
		}
		display "Rain" type: 2d {
			chart "Rain events" type: series y_label: "level" y2_label:"mm" y_range: {0,3.5} y2_range:{-120,0} y_tick_unit:1   y2_tick_unit:5 x_serie_labels:string(current_date,"dd MM yyyy"){
				data "Rain" value:rain collect(each.rainfall) color:#lightblue line_visible:true style:line use_second_y_axis: true;
				data "Runoff events" value:rain collect(each.runoff.my_flow) color:#blue line_visible:true marker_shape: marker_up_triangle ;
				}
		}
		display "Inlet" type: 2d {
			chart "Inlet evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				//data "Inflow" value:rain collect (each.runoff.my_flow)color: #darkblue marker_shape: marker_down_triangle;
				data "Inflow performance level" value:inlet collect (each.function_attributes["my_fqt"])color: #grey marker_shape: marker_down_triangle;
				//data "Outflow" value:inlet collect (each.my_output_managed_flow.my_flow) color:#deepskyblue marker_shape: marker_up_triangle;
			}
		}
		display "Ponding area" type: 2d{
			chart "Ponding area evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				//data "Inflow" value:inlet collect (each.my_output_managed_flow.my_flow) color: #darkblue marker_shape: marker_down_triangle;
				data "Retention performance level" value:ponding_area collect (each.function_attributes["my_fqt"])color: #grey marker_shape: marker_down_triangle;
				//data "Outflow" value:ponding_area collect (each.my_output_managed_flow.my_flow) color:#deepskyblue marker_shape: marker_up_triangle;
			}
		}
		display "Filter media" type: 2d {
			chart "Filter media evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				//data "Inflow" value:ponding_area collect (each.my_output_managed_flow.my_flow) color: #darkblue marker_shape: marker_down_triangle;
				data "Infiltration performance level" value:filter_media collect (each.function_attributes["my_fqt"])color: #grey marker_shape: marker_down_triangle;
				data "Sediment accumulation" value:filter_media collect (each.partpoll_acc) color: #red;
				//data "Outflow" value:filter_media collect (each.my_output_managed_flow.my_flow) color:#deepskyblue marker_shape: marker_up_triangle;
			}
		}
//		display "Outlet" type: 2d {
//			chart "Outlet evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
//				data "Inflow" value:filter_media collect (each.my_output_managed_flow.my_flow) color: #darkblue marker_shape: marker_down_triangle;
//				data "Outflow performance level" value:outlet collect (each.function_attributes["my_fqt"])color: #grey style:dot;
//				data "Outflow" value:outlet collect (each.my_output_managed_flow.my_flow) color:#deepskyblue marker_shape: marker_up_triangle;
//			}
//		}
		display "Vegetation cover" type: 2d {
			chart "Vegetation cover evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				data "Tree Health" value:trees collect (each.function_attributes["my_health"]) color: #pink marker_shape: marker_down_triangle;
				data "Main vegetation cover health" value:vegetation_cover collect (each.function_attributes["my_health"]) color: #darkblue marker_shape: marker_down_triangle;
				data "Main vegetation cover diversity" value:vegetation_cover collect (each.function_attributes["my_diversity"])color: #thistle style: dot;
				
			}
		}
		display "Performance" type: 2d {
			chart "Performance assessment" type:histogram
			y_range:[0,7000]
			y_tick_unit:1000		
			y_label: "nb of days"
			series_label_position: onchart {
				datalist legend:["Unmanaged flooding", "Accepted flooding","Unhealthy vegetation","Maintenance days"] 
						style: bar
						value:[days_flooding,days_accepted_flood,days_vegetation_degraded,days_maintained] 
						color:[#lightblue,#blue,#green,#purple];
						
			}
			

		}
	}
}








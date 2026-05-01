/**
* Name: NBSSAM
* Based on the internal empty template. 
* Author: egirot
* Tags: 
* 
*/

/* v4.1 evolutions : 
* grass & shrubs are associated to  inlet, outlet and filter media / tree is only associated to filter media
* still have to do something about unusual ponding 
* have two modes 
* 	one with the graphical part and one with outputs in a csv file (where I can do longer simulations)
 */

model NBSSAM

//******************** GLOBAL *****************************************
global {
	float step <-1 #day;
	float step1 <- 1.0;
	
	// Loading csv rainfall file
	file weather_file <- csv_file("../includes/RR_Temp_Lyon.csv",";");
	matrix weather_data <- matrix(weather_file);
	
	// Setting simulation timeline
	date starting_date <-date(string(int(weather_data[0,0])));  // starting date of simulation;
	float simulation_duration <- float((years_between(starting_date,end_date)));
	date end_date <- date(string(int(weather_data[0,length(rows_list(weather_data))-1])));
	int current_event_number<-0;	
	
	// Defining seasons
	string current_season;
	reflex season_update {
		
		if (month(current_date)=12 or month(current_date)<=2){
			current_season <- "winter";
		}
		if (month(current_date)>=3 or month(current_date)<=5){
			current_season<- "spring";
		}
		if (month(current_date)>=6 or month(current_date)<=8){
			current_season <- "summer";
		}
		if (month(current_date)>=9 or month(current_date)<=11){
			current_season <- "fall";
		}
	}
	

	// Loading csv files that has the logic table which calculates the output flow depending on input and condition values
	file output_flow_LT_file <- csv_file( "../includes/output_flow_LT.csv",';',int);
	file output_poll_LT_file <- csv_file("../includes/output_poll_load_LT.csv",";",int);
	
	
	// Loading image files for NBSS visualization
	image_file grass_image <- image_file("../images/grass.png");
	image_file shrubs_plants_image <- image_file("../images/shrubs_plants.png");
	image_file tree_image <- image_file("../images/tree.png");	
	
	// Performance map -> to add in NBSS species ?
	map <string,int> performance <- ["Flood protection"::3,"Natural receiving ecosystem preservation"::3, "Biodiversity preservation"::3,"Climate change adaptation"::3]; 
	
	bool end_sim<-false;
	bool static_arrows<-true;
	
	// failure parameters
	bool weather_failures_active <- true ;
	bool internal_failures_active <- true;
	bool external_failures_active <- false ;

	
	// maintenance parameters 
	string maintenance_type <- "no maintenance";// parameter: maintenance_type among:["no maintenance", "run-to-failure", "programmed"];
	int intervention_delay_days <- 5;// parameter:true  min:2 max: 30;

	
	init {

		create rain {
			ADD_days <-0;
			create managed_flow{
				my_component<- myself;
				myself.runoff <- self;
			}
		}
		create NBSS with: [location::{50, 40}]{
			my_name <- "Bioretention cell";
			create inlet with: [location::{20, 25}]{
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
				create grass {
					my_surface <- myself;
					my_name <- "grass";
					my_growth <- 3;
					my_growing_period <- 10;
					myself.my_grass <- self;
				}
				create shrubs_plants {
					my_surface <- myself;
					myself.my_shrubs_plants <- self;
					my_name <- "shrubs_plants";
					my_growth <- 3;
					my_growing_period <- 20;
				}
			}
			create ponding_area with: [location::{45, 40}] {
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
			create main_vegetation_cover with: [location::{45,30}]{
				my_name<-"vegetation_cover";
				my_NBSS<- myself;
				my_upstream_comp <- my_NBSS.my_ponding_area;
				my_downstream_comp <- my_NBSS.my_filter_media;
				create grass {
					my_surface <- myself;
					my_name <- "grass";
					myself.my_grass <- self;
					my_growing_period <- 10;
					add self to:myself.my_NBSS.my_vegetal_components;

				}
				create shrubs_plants {
					my_surface <- myself;
					my_name <- "shrubs_plants";
					myself.my_shrubs_plants <- self;
					my_growing_period <- 20;
					add self to:myself.my_NBSS.my_vegetal_components;

				}
				create trees {
					my_name <- "trees";
					my_surface <- myself;
					my_growing_period <- 10;
					myself.my_trees <- self;
					add self to:myself.my_NBSS.my_vegetal_components;
				}
			}	
			create filter_media with: [location::{45, 46}]{
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
		
			
			create outlet with: [location::{75, 60}]{
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
				create grass {
					my_surface <- myself;
					my_name <- "grass";
					myself.my_grass <- self;
					my_growing_period <- 10;
				}
				create shrubs_plants {
					my_surface <- myself;
					my_name <- "shrubs_plants";
					myself.my_shrubs_plants <- self;
					my_growing_period <- 20;
				}
			}
			my_components <- my_engineered_components union my_vegetal_components;	
			
		}
		create urban_environment with: [location::{50, 37.5}] {
			my_name <- "Urban environment";
			create unmanaged_flow{
				my_component<- myself;
				myself.overflow <- self;
			}
			
		}
		
		create sewer_system with: [location::{50,90}]{
			my_name <- "Sewer system";
		}
		
		create natural_environment with: [location::{50,90}]{
			my_name <- "Receiving natural environment";
		}
			
	
		// The following 3 csv files contain lines of failure events and their attributes.
		// Here I am creating as many failure events agent as there are lines in the CSV file.
		// For failures dependent of external elements
		if (external_failures_active = true) {
		create ext_failure from:csv_file( "../includes/ext_failures.csv",';',true) with:
			[my_name::string(get("failure_name")), 
				my_frequency::float(get("failure_frequency_weeks")),
				my_winter_factor::int(get("winter_factor")),
				my_spring_factor::int(get("spring_factor")),
				my_summer_factor::int(get("summer_factor")),
				my_fall_factor::int(get("fall_factor")),
				impacted_agent::string(get("impacted_agent")),
					impacted_attribute::string(get("impacted_attribute"))
			];
		}
		// For failures dependent of internal NBSS elements
		if (internal_failures_active = true){
		create int_failure from:csv_file( "../includes/int_failures.csv",';',true) with:
				[my_name::string(get("failure_name")), 
				impacted_agent::string(get("impacted_agent")),
					impacted_attribute::string(get("impacted_attribute")),
					my_threshold::int(get("threshold"))

			];	
		}
		// For failures dependent of the rain
		if (weather_failures_active = true){
		create weather_failure from:csv_file( "../includes/weather_failures.csv",';',true) with:
				[my_name::string(get("failure_name")), 
				impacted_agent::string(get("impacted_agent")),
					impacted_attribute::string(get("impacted_attribute")),
					my_min_fail_inflow::int(get("fail_min_inflow")),
					my_min_fail_duration::int(get("fail_min_duration")),
					my_min_sol_inflow::int(get("sol_min_inflow")),
					my_min_sol_duration::int(get("sol_min_duration")),
					my_winter_factor::int(get("winter_factor")),
					my_spring_factor::int(get("spring_factor")),
					my_summer_factor::int(get("summer_factor")),
					my_fall_factor::int(get("fall_factor"))				
			];
		}
		// The maintenance_practices.csv file containes lines of maintenance practices and their attributes.
		// Here I am creating as many maintenance practice agent as there are lines in the CSV file. 
		if maintenance_type = "programmed" {
			create maintenance_practice from:csv_file( "../includes/maintenance_programmed.csv",';',true) with:
				[practice_name::string(get("practice_name")), 
					practice_scope::string(get("practice_scope")),
					practice_level::int(get("practice_level")),
					maintenance_frequency::float(get("practice_frequency_weeks"))#week, 
					impacted_agent::string(get("impacted_agent")),
					linked_failure_event::string(get("linked_failure_event"))
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
				ask agents of_generic_species output_flow where(each.my_component=self){
					do update_output_partpoll_load(myself.function_attributes["my_fql"], self.my_partpoll_load);
				}
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
/* Declaration of the rain species */
species rain {
	managed_flow runoff;
	date last_rain;
	list<int> runoff_history <- [];
	int ADD_days;
	
	reflex create_runoff {
		runoff.my_flow <- 0.0;
		loop i from:0 to:weather_data.rows-1 {
			if current_date = date(string(int(weather_data[0,i]))) {
				//Rainfall event <= 20mm in a day are considered as a runoff flow of 1
				if (float(weather_data[3,i]) <= 20.0 and float(weather_data[3,i]) > 5.0) {
					runoff.my_flow <- 1.0;
				}
				//Rainfall event between 20mm and 80mm in a day are considered as a runoff flow of 2
				if (float(weather_data[3,i]) > 20.0 and float(weather_data[3,i]) <= 80.0 ) {
					runoff.my_flow <- 2.0;
				}
				//Rainfall event > 80mm in a day are considered as a runoff flow of 3
				if (float(weather_data[3,i]) > 80.0 ) {
					runoff.my_flow <- 3.0;
				}

			}

		}
		add(runoff.my_flow) to: runoff_history;
			if (runoff.my_flow != 0) {
				last_rain <- current_date;
				
		}	
		runoff.my_partpoll_load <- runoff.my_flow;
		runoff.my_disspoll_load <- runoff.my_flow;
		save [current_date,runoff.my_flow, runoff.my_partpoll_load,runoff.my_disspoll_load] to: "../results/runoff.csv" format:"csv" rewrite: false;	
	}
	// adjust runoff pollution according to antecedent dry days ( long ADDs = more sediment in runoff) -> what is long ADD ?
	// TODO : runoff part poll also depends of temperature 
	reflex adjust_runoff_poll_to_ADD when: (runoff.my_flow!=0) {
		ADD_days <-0;
		loop i from:length(runoff_history)-2 to:0 step:-1 {
			if (runoff_history[i]=0) {
				ADD_days <- ADD_days +1;
			}
			if (runoff_history[i]!=0) {
				break;
			}
		}			
		runoff.my_partpoll_load <- max(runoff.my_flow,runoff.my_flow +int(ADD_days/10));	

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
		draw rectangle(80,55) border:#black color:#white;
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -31, 1} anchor: #top_center;
	}

}

/* Declaration of the parent species component */
species component {
	NBSS my_NBSS; //to which NBSS this component belongs	
	string my_name;
	map <string,float> function_attributes <- ["my_fqt"::3,"my_fql"::3];
	output_flow my_output_managed_flow;
	output_flow my_output_unmanaged_flow;
	rgb my_color;
	list<failure_event> my_failures;
	map <int,rgb> condition_color <- [3::#green,2::#yellow,1::#orange,0::#red];
	component my_upstream_comp;
	component my_downstream_comp;
	list<string> my_impacted_agents;
	grass my_grass;
	shrubs_plants my_shrubs_plants;
	float my_vegetation_cover; // % sum of grass and shrubs_plants growth
	bool rtf_state <- true;
	int buffer_upstream <- 2; // TODO : what is this?
	
	
	reflex update_color {
		my_color<-condition_color[int(min(function_attributes.values))];	
	}

	action flow_downstream {
		do update_output_flows(my_upstream_comp.my_output_managed_flow.my_flow);
		ask agents of_generic_species output_flow where(each.my_component=self){
			do update_output_disspoll_load(myself.function_attributes["my_fql"], self.my_disspoll_load);
			do update_output_partpoll_load(myself.function_attributes["my_fql"], self.my_partpoll_load);
		} 
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
		ask agents of_generic_species output_flow {
			my_disspoll_load <- my_flow;
			my_partpoll_load <- my_flow;
		}
		
	}
	

}

/**************************** PARENT : ENGINEERED COMPONENTS*****************************************/

species engineered_component parent: component {
	// parameters that will help create a delay when impacting upstream components
	float upstream_impact_buffer <- 3.0; // here i choose that 3 days are needed to impact upstream component
	float upstream_timer <- 0.0;
	//bool upstream_state <- true; // ça sert à quoi ça ? 
	
	// critical state that will lead to run-to-failure maintenance
	reflex eng_critic_state when: (function_attributes["my_fqt"]=1) and (rtf_state=true){
		rtf_state <- false;	
		ask rtf_maintenance {
			rtf_state_date <- current_date;
		}
		
	}


}
	

/********************************************** INLET ***************************************/
species inlet parent: engineered_component {
	
	// update the vegetation size around inlet
	reflex update_vegetation_size {
		if (my_grass!=nil or my_shrubs_plants!=nil) {
			ask int_failure where (each.my_name="overgrown_vegetation" and each.impacted_agent=self.my_name){
				my_value <- max(myself.my_grass.my_growth, myself.my_shrubs_plants.my_growth);
			}
		}
	
	}
	
	aspect default {
		draw circle(4) border:#black color:my_color;
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -7, 1} anchor: #top_center;
		//draw line([ponding_area(0).location -0.01,self.location + 3]) color: #dodgerblue begin_arrow: 2 end_arrow: -7 width: 2.0;
	}
	
}

/******************************************** PONDING AREA ********************************************/
species ponding_area parent: engineered_component {
	bool temporary<-true;
	bool ponding <- false;

	
//	//unusual ponding occurs when filter media has output unmanaged flow
//	// TODO: je sais pas comment faire avec le unusual ponding 
	// quand le filter media a du unmanaged output flow , ça va venir faire baisser la capacité de stockage du ponding area pendant un temps limité non?
	reflex unusual_ponding when: (my_NBSS.my_filter_media.my_output_unmanaged_flow.my_flow=2){
		ask failure_event where (each.my_name="unusual_ponding"){
			if (current_date != last_failure){
				do failure_impact(self);
				myself.ponding <- true;
			}
		}
	}
	
	reflex ponding_ok when: (ponding=true) {
		if (my_NBSS.my_filter_media.my_output_unmanaged_flow.my_flow=0){
			ask failure_event where (each.my_name="unusual_ponding"){
				if (current_date >= last_failure plus_days 1){
					loop attribute_keys over: myself.function_attributes.keys {
					myself.function_attributes[attribute_keys] <- min(3,myself.function_attributes[attribute_keys]+0.25);
					}
					myself.ponding <- false;
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
	float partpoll_acc <- 0.0;
	float disspoll_acc <- 0.0;

	
	// sediments progressively deposit on filter media 
	reflex partpoll_accumulation {
	// the lower the flow rate, the more sediment is deposited (Deletic et al., 2006) 
		if (int(my_upstream_comp.my_output_managed_flow.my_flow) = 1) {
			partpoll_acc <- partpoll_acc + (my_upstream_comp.my_output_managed_flow.my_partpoll_load/5);
			}
		if (int(my_upstream_comp.my_output_managed_flow.my_flow) = 2) {
			partpoll_acc <- partpoll_acc + (my_upstream_comp.my_output_managed_flow.my_partpoll_load/10);
			}
		if (int(my_upstream_comp.my_output_managed_flow.my_flow) = 3) {
			partpoll_acc <- partpoll_acc + (my_upstream_comp.my_output_managed_flow.my_partpoll_load/20);
			}
		ask int_failure where (each.my_name="partpoll_acc" and each.impacted_agent="filter_media"){
			my_value <- myself.partpoll_acc;
		}
	}
	
	// dissolved pollution progressively accumulates in filter media 
	reflex disspoll_accumulation {
		disspoll_acc <-disspoll_acc + (my_upstream_comp.my_output_managed_flow.my_disspoll_load/10);
		ask int_failure where (each.my_name="disspoll_acc"){
			my_value <- myself.disspoll_acc;
		}
	}	
	

	aspect default {
		draw rectangle(30,5) border:#sienna color:my_color;
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location anchor: #center;
	}
}


/***************************************************** OUTLET *************************************/
species outlet parent: engineered_component {
	aspect default {
		draw circle(4) border:#black color:my_color;
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -7, 1} anchor: #center;
	}
}



/**************************************** PARENT : VEGETAL COMPONENTS*************************************************/

// main NBSS vegetation cover , can be made of one or multiple vegetal components
species main_vegetation_cover parent: component {
	trees my_trees;
	
	
}


species vegetal_component parent: component {
	component my_surface; // associated NBSS component of vegetatal components -> grass growing around the inlet will have inlet as its my_surface
	float my_growth <- 3.0; // 3 is optimal growth, 2 is a bit too overgrown, 1 is way too overgrown, 0 is completely out of control
	float my_health <- 3.0;
	float my_density <- 3.0; // 3 is optimal density, 2 is with a bit of spare spots, 1 is with more than 50% of bare spots, 0 is 90% of bare spots and only 10% vegetation left
	list<float> my_health_history;
	int my_growing_period; //nb of days at health=3 that trigger growth by 0.1 
	int my_declining_period <- 6; // nb of days at health = 1 that trigger vegetation growth to decrease by 0.1
	date last_growth <- starting_date;
	date last_decline <- starting_date;
	
	// change growing factor according to season
	reflex update_growing_factor_season {
		
	}
	
	reflex health_history {
		add my_health to: my_health_history;
	}
	
	// vegetation growth depends of its health history -> can lead to overgrowing
	reflex overgrowing {
		if (sum(copy_between(my_health_history, length(my_health_history) - my_growing_period ,length(my_health_history)))>=2*my_growing_period) and (current_date >= last_growth + my_growing_period #days){
			my_growth <- min(0,my_growth - 0.1);
			last_growth <- current_date;
		}
//		if (sum(copy_between(my_health_history, length(my_health_history) - my_declining_period ,length(my_health_history)))=my_declining_period) and (current_date >= last_decline + my_declining_period #days){
//			my_growth <- min(0,my_growth-0.1);
//			last_decline <- current_date;
//		}
	}
	
//	// when vegetation health is deteriorating for a certain amount of time -> growing stops and can diminishes
//	reflex declining {
//		if (sum(copy_between(my_health_history, length(my_health_history) - my_declining_period ,length(my_health_history)))=my_declining_period) and (current_date >= last_decline + my_declining_period #days){
//			my_growth <- min(0,my_growth-0.1);
//			last_decline <- current_date;
//		}
//
//	}
	
	// critical state that will lead to run-to-failure maintenance
	reflex veg_rtf_state when: (my_health <= 1) and (my_surface.rtf_state =true){
			my_surface.rtf_state <- false;
			ask rtf_maintenance {
				rtf_state_date <- current_date;
			}
	}

}


/***************************************************** GRASS *******************************************/

species grass parent: vegetal_component {

	
	aspect default {
		draw grass_image size: {20.0, 10.0, 0.0};
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -5, 1} anchor: #top_center;
	}
}

/***************************************************** SHRUBS and PLANTS *******************************************/

species shrubs_plants parent: vegetal_component {
	
	aspect default {
		//draw rectangle(10,10) at: my_surface.location + {0,-5,1};
		//draw shrubs_plants_image size: {20.0, 12.0, 0.0} at: my_surface.location + {8, -8, 1};
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -8, 1} anchor: #top_center;
	}
	
}

/***************************************************** TREES *******************************************/

species trees parent: vegetal_component {

	aspect default {
		draw tree_image size: {20.0, 20.0, 0.0};
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -12, 1} anchor: #top_center;
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
	float my_disspoll_load; // dissolved pollutant load
	float my_partpoll_load; // particulate pollutant load 
	
	action update_output_disspoll_load(float current_fql,float current_poll_load){
		matrix data<-matrix(output_poll_LT_file);
		loop i from: 0 to: data.rows -1 {
			if (data[0,i] = int(current_fql) and data[1,i] = int(current_poll_load)){
				my_disspoll_load <- float(data[2,i]);
			}
		}
	}
	
	action update_output_partpoll_load(float current_fql, float current_poll_load){
		matrix data<-matrix(output_poll_LT_file);
		loop i from: 0 to: data.rows -1 {
			if (data[0,i] = int(current_fql) and data[1,i] = int(current_poll_load)){
				my_partpoll_load <- float(data[2,i]);
			}
		}
	}
	
	
	
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
	
	// failure occurence can depend of the season, seasonal_factor will take one of the four following values according to the current_season 
	int my_winter_factor;
	int my_spring_factor;
	int my_summer_factor;
	int my_fall_factor;
	int seasonal_factor;
	
	string impacted_agent;
	string impacted_attribute;
	date last_maintenance <- starting_date;	
	date last_failure <- starting_date;

	// this could be a function?
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

	// impact of a failure event on attributes
	action failure_impact (failure_event failure) {
		ask agents of_generic_species vegetal_component where (each.my_name=failure.impacted_agent){
			if failure.impacted_attribute = "my_health" {
				my_health <- max(0, my_health - 0.25);
				loop attribute_keys over: function_attributes.keys {
					function_attributes[attribute_keys] <- max(0,function_attributes[attribute_keys]-0.25);
				}
			}
			else {
				function_attributes[failure.impacted_attribute] <- max(0,function_attributes[failure.impacted_attribute]-0.25);
			}
			failure.last_failure <- current_date;
			write failure.my_name + " on " + failure.impacted_agent + " on " + string(current_date,"dd MM yyyy");
			add failure to:self.my_failures;
			save [current_date,failure.my_name,failure.impacted_agent,failure.impacted_attribute] to: "../results/failures.csv" format:"csv" rewrite: false;

		}
		ask agents of_generic_species engineered_component where (each.my_name=failure.impacted_agent){
			function_attributes[failure.impacted_attribute] <- max(0,function_attributes[failure.impacted_attribute]-0.25);
			write failure.my_name + " on " + failure.impacted_agent + " on " + string(current_date,"dd MM yyyy");
			add failure to:my_failures;
			save [current_date,failure.my_name,failure.impacted_agent,failure.impacted_attribute] to: "../results/failures.csv" format:"csv" rewrite: false;
			failure.last_failure <- current_date;
		}
	}
	
}

/**********************  External factor failures - trash and leaf accumulation *****************************************/

species ext_failure parent: failure_event {
	float my_frequency;
	
	
	reflex trigger_ext_failure when: (current_date!=starting_date){
		loop i from:1 to: (simulation_duration*52)/(my_frequency*seasonal_factor) {
			if (current_date = last_maintenance + (i*my_frequency #week)) {
				do failure_impact(self);
			}
		}
	}
}


/**********************  Internal factor failures - pollutant accumulation around inlet, on ponding area, in vegetation; vegetation accumulation around inlet/outlet *****************************************/

species int_failure parent: failure_event {
	float my_value; // accumulation value
	int my_threshold;  // threshold that leads to failure
	int my_iteration <- 1; 
	
	reflex trigger_int_failure when: (my_value = my_iteration*my_threshold){
		if (current_date != last_failure) {
			do failure_impact(self);
			}
			my_iteration <- my_iteration +1;	
		}	
	}
	
	
	
/**********************  Rain-dependent failures - water stress, drowning, filter media saturation *****************************************/
	
species weather_failure parent: failure_event {
	int my_min_fail_inflow; // this is the minimum value of the rain that will lead to failure for a set duration (my_min_fail_duration)
	int my_min_fail_duration; //TODO : add seasonality
	int my_min_sol_inflow; // this is the minimum value of the rain that will resolve the failure for a set duration (my_min_sol_duration)
	int my_min_sol_duration; //TODO : add seasonality
	bool happened <- false;
	
	
	
	reflex trigger_weather_failure {
			ask rain { 
				if (10<= month(current_date) and month(current_date)<= 3) { // "winter months", fail duration is multiplied by 2
					if (sum(copy_between(runoff_history, (length(runoff_history) - (myself.my_min_fail_duration*2)) ,length(runoff_history)))= (2*myself.my_min_fail_duration*myself.my_min_fail_inflow)) and (current_date >= myself.last_failure plus_days (2*myself.my_min_fail_duration)){
						write "hello";
						ask myself {
							do failure_impact(self);
							happened <- true;
					}
				}
			}
			if ( month(current_date)>=4 and month(current_date)<= 9) { // 
					if (sum(copy_between(runoff_history, length(runoff_history) - myself.my_min_fail_duration ,length(runoff_history)))= (myself.my_min_fail_duration*myself.my_min_fail_inflow)) and (current_date >= myself.last_failure plus_days myself.my_min_fail_duration){
						ask myself {
							do failure_impact(self);
							happened <- true;
					}
				}
			}
		}
	}
	
	// weather failures "resolve" themselves according to the weather forecast
	reflex weather_failure_resolved {
		if (current_date >= last_failure plus_days my_min_sol_duration) and (happened = true) {
			ask rain {
				if (sum(copy_between(runoff_history, length(runoff_history) - myself.my_min_sol_duration ,length(runoff_history)))>= (myself.my_min_sol_duration*myself.my_min_sol_inflow)){
					ask agents of_generic_species vegetal_component where (each.my_name=myself.impacted_agent){
						my_health <- max(3.0,my_health+0.25);
						function_attributes[] <- max(3,function_attributes[] + 0.25);
					}
					ask agents of_generic_species engineered_component where (each.my_name=myself.impacted_agent){
						function_attributes[] <- max(3,function_attributes[] + 0.25);
					}
				}
			} happened <- false;
		}
	}
	
	
}
/***************************************************** MAINTENANCE PRACTICE *******************************************/
species maintenance_practice {
	string practice_name;
	string practice_scope;
	int practice_level;
	float maintenance_frequency;
	string impacted_agent;
	string linked_failure_event;

	
	reflex trigger_prog_maintenance when: (maintenance_type="programmed")and every(maintenance_frequency){
		// if the maintenance practice's scope is specific, find the impacted_agent
		if (practice_scope = "specific"){
			ask agents of_generic_species vegetal_component where (each.my_name=impacted_agent){
				my_health <- 3.0;
				function_attributes[] <- 3;
		
				//reset failure event frequency with maintenance date
				ask self.my_failures where (each.my_name=myself.linked_failure_event){
					last_maintenance <- current_date;
				}
				// remove failure events that are going to be maintained from the my_failures list
				remove all:(self.my_failures where (each.my_name=myself.linked_failure_event)) from:self.my_failures;
				}
			ask agents of_generic_species engineered_component where (each.my_name=impacted_agent){
				function_attributes[] <- 3;
				if (my_name = "filter_media") {
						ask my_NBSS.my_filter_media{
							disspoll_acc <- 0.0;
							partpoll_acc <- 0.0;
				 }
				}
				//reset failure event frequency with maintenance date
				ask self.my_failures where (each.my_name=myself.linked_failure_event){
					last_maintenance <- current_date;
				}
				
				// remove failure events that are going to be maintained from the my_failures list
				remove all:(self.my_failures where (each.my_name=myself.linked_failure_event)) from:self.my_failures;

			}
		}
//		// if the maintenance practice's scope is general, find all the components impacted by linked_failure_event = find all components whose failure name in the list my failures = linked_failure_event of maintenance practice-> ASK FRANCK
//		else if (practice_scope = "general") {
//			ask  NBSS[0].my_components {
//				 loop the_failures over: my_failures {
//				 	if (the_failures.my_name = myself.linked_failure_event){
//						//do eng_response_to_maintenance(myself);
//					}
//				 }	
//			}				
//		}
	}
}

// run to failure maintenance agent 
species rtf_maintenance {
	date rtf_state_date <- starting_date; 
	
	reflex trigger_rtf_maintenance when: (current_date = rtf_state_date + intervention_delay_days #days) and (rtf_state_date !=starting_date) and (maintenance_type = "run-to-failure") {
			ask agents of_generic_species vegetal_component {
				my_health <- 3.0;
				function_attributes[] <- 3;
			rtf_state<- true;	
				//reset failure event frequency with maintenance date
				ask self.my_failures {
					last_maintenance <- current_date;
				}
				// remove failure events that are going to be maintained from the my_failures list
				remove all:(self.my_failures) from:self.my_failures;
			}
			ask agents of_generic_species engineered_component{
				function_attributes[] <- 3;
				rtf_state<- true;
				if (my_name = "filter_media") {
						ask my_NBSS.my_filter_media{
							disspoll_acc <- 0.0;
							partpoll_acc <- 0.0;
				 }
				}
				//reset failure event frequency with maintenance date
				ask self.my_failures  {
					last_maintenance <- current_date;
				}
				
				// remove failure events that are going to be maintained from the my_failures list
				remove all:(self.my_failures) from:self.my_failures;

			}
		}
}

//******************** EXPERIMENT  *****************************************
	
	
experiment "tests" type: batch repeat:10 until:end_sim{
	
}

experiment "Composants"	type: gui {
	output {
		display "Runoff events" type: 2d {
			chart "Evenements pluvieux" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				data "Ruissellement" value:rain collect(each.runoff.my_flow) color:#blue line_visible:false style: dot ;
				data "Pollution particulairedu ruissellement" value: rain collect(each.runoff.my_partpoll_load) color:#maroon style:dot;
				}
		}
		display "Inlet" type: 2d {
			chart "Inlet evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				data "Inflow" value:rain collect (each.runoff.my_flow)color: #darkblue marker_shape: marker_down_triangle;
				data "Inflow performance level" value:inlet collect (each.function_attributes["my_fqt"])color: #grey style: dot;
				data "Outflow" value:inlet collect (each.my_output_managed_flow.my_flow) color:#deepskyblue marker_shape: marker_up_triangle;
			}
		}
		display "Filter media" type: 2d {
			chart "Filter media evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				data "Inflow" value:inlet collect (each.my_output_managed_flow.my_flow) color: #darkblue marker_shape: marker_down_triangle;
				data "Infiltration performance level" value:filter_media collect (each.function_attributes["my_fqt"])color: #grey style: dot;
				data "Sedimentation" value:filter_media collect (each.partpoll_acc) color: #red;
				data "Outflow" value:filter_media collect (each.my_output_managed_flow.my_flow) color:#deepskyblue marker_shape: marker_up_triangle;
			}
		}
		display "Outlet" type: 2d {
			chart "Outlet evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				data "Inflow" value:filter_media collect (each.my_output_managed_flow.my_flow) color: #darkblue marker_shape: marker_down_triangle;
				data "Outflow performance level" value:outlet collect (each.function_attributes["my_fqt"])color: #grey style:dot;
				data "Outflow" value:outlet collect (each.my_output_managed_flow.my_flow) color:#deepskyblue marker_shape: marker_up_triangle;
			}
		}
		display "Vegetation" type: 2d {
			chart "Vegetation evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				data "Inflow" value:filter_media collect (each.my_output_managed_flow.my_flow) color: #darkblue marker_shape: marker_down_triangle;
				data "Grass health level" value:grass collect (each.my_health)color: #thistle style: dot;
				data "Shrubs & plants health level" value:shrubs_plants collect (each.my_health)color: #crimson style: dot;
				data "Grass growth" value:grass collect (each.my_growth) color:#green;
				data "Shurbs & plants growth" value:shrubs_plants collect(each.my_growth) color: #darkgreen;
				data "Pollutant accumulation" value:filter_media collect (each.disspoll_acc) color:#red;
			}
		}
	}
}

experiment "Interface" type: gui {
	output {
		display NBSS_cross_section type: 3d {
			species urban_environment;
			species NBSS;
			species inlet;
			species ponding_area;
			species filter_media; 
			species grass;
			species shrubs_plants;
			species trees;
			species outlet;
			species sewer_system;
		}
		display "Runoff events" type: 2d {
			chart "Evenements pluvieux" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				data "Ruissellement" value:rain collect(each.runoff.my_flow) color:#blue line_visible:false style: dot ;
				data "Pollution particulaire du ruissellement" value: rain collect(each.runoff.my_partpoll_load) color:#maroon style:dot;
				}
		
		}
		display "Runoff quantity control" type: 2d {
			chart "Gestion du ruissellement" type: series y_label: "fonctionnalité" y_range: {0,3} y2_label: "accumulation (% de surface recouverte)" y2_range: {0,100} y_tick_unit:1 y2_tick_unit:5 x_serie_labels:string(current_date,"dd MM yyyy"){
				data "Entrée d'eau" value:inlet collect (each.function_attributes["my_fqt"])color: #grey marker_shape: marker_down_triangle;
				data "Zone de rétention" value:ponding_area collect (each.function_attributes["my_fqt"]) color: #deepskyblue marker_shape: marker_circle;
				data "Média filtrant" value:filter_media collect (each.function_attributes["my_fqt"]) color: #darkgoldenrod marker_shape: marker_diamond;
				//data "Sortie d'eau / Rejet" value:outlet collect (each.function_attributes["my_fqt"]) color:#black marker_shape: marker_up_triangle;
				data "Accumulation de sédiments sur média filtrant" value:filter_media collect (each.partpoll_acc)color: #maroon marker_shape: marker_circle use_second_y_axis: true;
				data "Accumulation de pollution dissoute dans média filtrant" value:filter_media collect (each.disspoll_acc)color: #red marker_shape: marker_circle use_second_y_axis: true;
				
			}
		}
		display "Vegetation state" type: 2d {
			chart "Santé et densité de la végétation" type: series y_label: "état de santé" y_tick_unit:1 y2_label: "densité %" y2_range: {0,200} y2_tick_unit:10 x_serie_labels:string(current_date,"dd MM yyyy"){
				data "Santé du couvert herbacée" value:grass collect (each.my_health) color: #lime marker_shape: marker_square;
				data "Santé des plantes" value:shrubs_plants collect (each.my_health) color: #limegreen marker_shape: marker_square;
				data "Santé des arbres" value:trees collect (each.my_health) color: #forestgreen marker_shape: marker_square;
				//data "Couverture herbacée et arbustive" value:NBSS collect (each.my_vegetation_cover) color:#yellowgreen marker_shape: marker_diamond use_second_y_axis: true;
			}
		}
		display "Output flows" type: 2d {
			chart "Débits non gérés" type: series y_label: "flow level" y_range: {0,3} y_tick_unit:1 x_serie_labels:string(current_date,"dd MM yyyy"){
				data "Arrivée d'eau" value:inlet collect (each.my_output_unmanaged_flow.my_flow)color: #grey style:dot;
				//data "Zone de rétention" value:ponding_area collect (each.my_output_unmanaged_flow.my_flow) color: #deepskyblue style:dot;
			}
		}
//	    display "Runoff quality control" type: 2d {
//			chart "Runoff quality control" type: series y_label: "level" y_range: {0,3} y_tick_unit:1 {
//				data "Inlet" value:inlet collect (each.function_attributes["my_fql"])color: #grey marker_shape: marker_down_triangle;
//				data "Ponding area" value:ponding_area collect (each.function_attributes["my_fql"]) color: #deepskyblue marker_shape: marker_circle;
//				data "Filter media" value:filter_media collect (each.function_attributes["my_fql"]) color: #darkgoldenrod marker_shape: marker_diamond;
//				data "Grass" value:grass collect (each.function_attributes["my_fql"]) color: #limegreen marker_shape: marker_square;
//				data "Shrubs&Plants" value:shrubs_plants collect (each.function_attributes["my_fql"]) color: #gamagreen marker_shape: marker_square;
//				data "Trees" value:trees collect (each.function_attributes["my_fql"]) color: #darkgreen marker_shape: marker_square;
//				data "Outlet" value:outlet collect (each.function_attributes["my_fql"]) color:#black marker_shape: marker_up_triangle;
//			}
//		}
//		display "datalist_bar_chart" type:2d {
//			chart "Performance assessment" type:histogram  
//			series_label_position: onchart y_range: {0,3.5} y_tick_unit:1
//			{
//				datalist legend: performance.keys 
//					style: bar
//					value: performance.values
//					color:[#blue,#green,#purple,#pink];
//
//			}
//		}
	}
}







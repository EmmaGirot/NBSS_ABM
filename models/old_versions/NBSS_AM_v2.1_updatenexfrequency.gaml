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
 * maintenance_scheduled.csv
 * 	in the climate folder : 
 * climate_spei.csv
 * weather_input_gama.csv
 * 	in the failures folder : 
 * ext_metric_failures.csv
 * ext_time_failures.csv
*	in the maintenance_practices folder
 * MP_pos_impact.csv
 * MP_neg_impact_seasons.csv

 
 * TODO :
 * - call R from GAMA for spei calculation  
 * - add randomness in the days of week in which ext_failures are triggered
 */

model NBSSAM

//******************** GLOBAL *****************************************
global {
	float step <-1 #day;
	float step1 <- 1.0;

	
	// Setting simulation timeline
	date starting_date <- date(string(int(weather_data[0,0])));  // starting date of simulation;
	date end_date <- date(string(int(weather_data[0,length(rows_list(weather_data))-1])));
	float simulation_duration <- float((years_between(starting_date,end_date)));
	
	// Loading csv rainfall and spei file
	file weather_file <- csv_file("../includes/climate/weather_input_gama.csv",",");
	matrix weather_data <- matrix(weather_file);
	
	/// Maintenance practices rules
	//Loading data from MP_pos_impact.csv which states what failures the MP responds to 
	file mapping_mp_failure <- csv_file("../includes/maintenance_practices/MP_pos_impact.csv",";");
	matrix mp_failure_map <- matrix(mapping_mp_failure);
	
	// TODO : create spei_file according to weather_file by calling R from GAMA
	file spei_file <- csv_file("../includes/climate/climate_spei.csv",",");
	matrix spei_data <- matrix(spei_file);
	
	// Defining seasons
	string current_season;
	int y <- year(current_date);
	date season_end;
	date season_start;
	
	// Loading csv files that has the logic table which calculates the output flow depending on input and condition values
	file output_flow_LT_file <- csv_file( "../includes/output_flow_LT.csv",';',int);
	bool end_sim<-false;
		
	// maintenance input parameters 
	// maintenance_type refers to the type of maintenance plan we're testing
	string maintenance_type <- "preventive";//<- "no_maintenance";// among:["no_maintenance", "run-to-failure", "scheduled","preventive"];
	// nb of days needed to intervene in a run-to-failure maintenance plan
	int intervention_delay_days <- 5;// parameter:true  min:2 max: 30;
	
	map results <- [];
	
	//performance parameters
	int maintenance_actions <- 0;
	int accepted_flood_days <- 0;
	int flooding_days <- 0;
	int degraded_vegetation_days <- 0; 
	int poor_well_being_days <-0;
	
	init {
		
		// Initialization of Rain agent : 
		create rain {
			create managed_flow{
				my_component<- myself;
				myself.runoff <- self;
			}
		}
		// Initialization of NBSS and all its components :
		create NBSS {
			my_name <- "Swale1";
			create inlet {
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
				myself.my_vegetation_cover <- self;
			}
			create trees {
				my_name <- "trees";
				my_NBSS<- myself;
				myself.my_trees <- self;
			}
			create filter_media {
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
				my_name <- "outlet";
				my_NBSS<- myself;
				my_color <- #antiquewhite;
				my_upstream_comp <- my_NBSS.my_filter_media;
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
			my_components <- my_engineered_components union my_vegetal_components;	
			
		}
		create urban_environment {
			my_name <- "Urban environment";
			create unmanaged_flow{
				my_component<- myself;
				myself.overflow <- self;
			}
			
		}
		
		create seasons {}
	
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
					my_threshold::float(get("threshold"))

			];		
		
		// TODO: create maintenance agent from failure_map
		create maintenance{}
		
		// The "scheduled" maintenance refers to a blindly scheduled maintenance plan written in the maintenance_scheduled.csv file
		// For this plan, the model will be creating as many maintenance practice agent as there are lines in the CSV file. 
		if maintenance_type = "scheduled" {
			create scheduled_maintenance from:csv_file( "../includes/maintenance_scheduled.csv",';',true) with:
				[practice_name::string(get("practice_name")), 
					maintenance_frequency::float(get("practice_frequency_weeks")), 
					prog_season_dep::bool(get("season_dep")),
					prog_target_season::list<string>(get("target_season")),
					department::string(get("department")),
					cost::float(get("cost_euros_m²"))
				];	
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
//	
//	reflex save_reults when : (current_date=end_date){
//		   save [maintenance_actions,accepted_flood_days,flooding_days,degraded_vegetation_days,poor_well_being_days] to: "results.csv" format:"csv" rewrite: false header: true ;
//		
//	}
//			
	reflex stop_simulation when: (current_date > end_date){
    	end_sim<-true;
		do pause;
	}
}

//************************ SPECIES DECLARATION ***************************

species seasons {
		reflex season_update {
		
		if (month(current_date)=12 or month(current_date)<=2){
			current_season <- "winter";
			season_start <- date(string(y)+ "-12-01");
			season_end <-date(string(y+1)+ "-03-01") minus_days 1;
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
	vegetation_cover my_vegetation_cover;
	trees my_trees;
	list<engineered_component> my_engineered_components;
	list<vegetal_component> my_vegetal_components;
	list<component> my_components;
	float my_global_condition;
	
	bool well_being_impacted <- false;
	bool vegetation_impacted <- false;
	
	reflex global_condition {
		list<float> vals <- [];
		loop c over: my_components {
		    vals <- vals + c.function_attributes.values;
		}
		my_global_condition <- min(vals);
	}
	
	reflex accepted_flood when: (my_inlet.my_output_unmanaged_flow.my_flow =3 or my_ponding_area.my_output_unmanaged_flow.my_flow=3){
		accepted_flood_days <- accepted_flood_days +1 ;
	}
	
	reflex flooding when: ((my_inlet.my_output_unmanaged_flow.my_flow >= 1 and my_inlet.my_output_unmanaged_flow.my_flow <3) or (my_ponding_area.my_output_unmanaged_flow.my_flow >= 1 and my_ponding_area.my_output_unmanaged_flow.my_flow <3) ){
		flooding_days <- flooding_days +1 ;
	}
	
	//Because performance indicators are calculated daily, multiple dysfunctions occurring on the same day are counted only once thanks to this reflex
	reflex daily_performance_reset when: every(1 #day){
		 well_being_impacted <- false;
		 vegetation_impacted <- false;
	}
	
	reflex littering when: (length(my_components where (length(each.my_failures where (each.my_name contains "trash_acc")) mod 2 = 0)) > 0) and (length(my_components where (length(each.my_failures where (each.my_name contains "trash_acc")) mod 2 != 0)) > 0)  {
		do well_being_impacted();
	}
	
	action well_being_impacted {
		if (well_being_impacted=false){
			poor_well_being_days <- poor_well_being_days +1;
			well_being_impacted <- true;
		}
	}
	
	action vegetation_impacted {
		if (vegetation_impacted=false){
			degraded_vegetation_days <- degraded_vegetation_days+1; 
			vegetation_impacted <- true;
		}
	}
	

	aspect default {
		draw rectangle(80,55) border:#black color:#white;
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -31, 1} anchor: #top_center;
	}

}

/* Declaration of the parent species component */
species component {
	NBSS my_NBSS; //to which NBSS this component belongs	
	string my_name;
	output_flow my_output_managed_flow;
	output_flow my_output_unmanaged_flow;
	rgb my_color;
	list<failure_event> my_failures ;
	map <string,float> function_attributes;
	component my_upstream_comp;
	component my_downstream_comp;
	list<string> my_impacted_agents;
	bool rtf_state <- false; // to signal if run-to-failure state is being carried out
	bool preventive_state <- false; // preventive maintenance state

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
			if (data[0,i] = int(function_attributes["my_qtf"]) and data[1,i] = int(current_inflow)){
				my_output_managed_flow.my_flow <- float(data[2,i]);
				my_output_unmanaged_flow.my_flow <- float(data[3,i]);	
			}
		}
		
	}
	
		
	//critical state is triggered whenener one of the functions of the component is equal to zero, this will lead to run-to-failure maintenance
	reflex critic_state when: (any(function_attributes)=0) and (rtf_state=false) and (maintenance_type = "run-to-failure"){
		rtf_state <- true;
		// if vegetation cover is in critic state because health = 0, only consider failures that impacted health (although biodiversity will also be at 0)
		list<string> functions_to_repair;
		if (my_name = "vegetation_cover" and function_attributes["my_health"]=0){
			 functions_to_repair <- ["my_health"];
		}
		else {
			functions_to_repair <- function_attributes.keys where (function_attributes[each]=0);
		}
		list<failure_event> my_failures_to_repair <-  my_failures where (each.impacted_attribute=any(functions_to_repair));
		map<failure_event, float> different_failures <- [];
		// we want to count how many different failure types there are and sum the impact level of similar failures, 
		loop i over: my_failures_to_repair {
		    failure_event rep <- first(my_failures_to_repair where (each.my_name = i.my_name));
		    different_failures[rep] <- (different_failures[rep] = nil ? 0 : different_failures[rep]) + i.level_of_impact;
		}
		// for run-to-failure maintenance, create a maintenance practice whose impact level will be equal to the number of failure types that have impacted the component
		if length(different_failures)!= 0 {
			loop i over: different_failures.keys {
				loop index_column from: 0 to: mp_failure_map.columns -1 { // go through the columns 
					loop index_row from:1 to: mp_failure_map.rows -1 { // go through the rows of linked failures for each column
						if mp_failure_map[index_column,index_row] = i.my_name {// find the name of a failure from the list of failures that have impacted the component
							create rtf_maintenance {
								practice_name <- mp_failure_map[index_column,0];
								impacted_component <- myself;
								impacted_attribute <- i.impacted_attribute;
								impact_level <-  different_failures[i];
								rtf_state_date <- current_date;	
								linked_failure_name <-i.my_name ;
								write practice_name + linked_failure_name + impacted_component;
								}
							}
						}
					}
				}
			}
		}
		
	// dysfunctional state is triggered whenener one of the functions of the component is equal to one or less, this state will lead to preventive maintenance
	reflex dys_state when: (any(function_attributes)<=1) and (preventive_state=false) and (maintenance_type = "preventive"){
		preventive_state <- true;
		// if vegetation cover is in critic state because health = 0, only consider failures that impacted health (although biodiversity will also be at 0)
		list<string> functions_to_repair;
		if (my_name = "vegetation_cover" and function_attributes["my_health"]<=1){
			 functions_to_repair <- ["my_health"];
		}
		else {
			functions_to_repair <- function_attributes.keys where (function_attributes[each]<=1);
		}
		list<failure_event> my_failures_to_repair <-  my_failures where (each.impacted_attribute=any(functions_to_repair));
		map<failure_event, float> different_failures <- [];
		// we want to count how many different failure types there are and sum the impact level of similar failures, 
		loop i over: my_failures_to_repair {
		    failure_event rep <- first(my_failures_to_repair where (each.my_name = i.my_name));
		    different_failures[rep] <- (different_failures[rep] = nil ? 0 : different_failures[rep]) + i.level_of_impact;
		}
		// for run-to-failure maintenance, create a maintenance practice whose impact level will be equal to the number of failure types that have impacted the component
		if length(different_failures)!= 0 {
			loop i over: different_failures.keys {
				loop index_column from: 0 to: mp_failure_map.columns -1 { // go through the columns 
					loop index_row from:1 to: mp_failure_map.rows -1 { // go through the rows of linked failures for each column
						if mp_failure_map[index_column,index_row] = i.my_name {// find the name of a failure from the list of failures that have impacted the component
							create preventive_maintenance {
								practice_name <- mp_failure_map[index_column,0];
								impacted_component <- myself;
								impacted_attribute <- i.impacted_attribute;
								impact_level <-  different_failures[i];
								linked_failure_name <-i.my_name ;
								do trigger_preventive_maintenance();
								}
							}
						}
					}
				}
			}
		}
	

}

/**************************** PARENT : ENGINEERED COMPONENTS*****************************************/

species engineered_component parent: component {
	// my_qtf means my quantity control function linked to stormwater control
	map <string,float> function_attributes <- ["my_qtf"::3];
		
	
}
	

/********************************************** INLET ***************************************/
species inlet parent: engineered_component {
	
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
	
	//unusual ponding occurs when filter media has an output_unmanaged_flow
	reflex unusual_ponding when: (current_date < starting_date) and (my_downstream_comp.my_output_unmanaged_flow.my_flow>=1) and (ponding=false){
		ponding <- true;
		create failure_event {
			my_name <- "unusual_ponding";
			impacted_agent <- myself.my_name;
			impacted_attribute <- "my_qtf";	
			last_failure <- current_date;
			do failure_impact(1.0);
		}		
	}
	
	// if there hasn't been any runoff >= 2 for the next 2 days after an unsual ponding event, ponding ends
	reflex ponding_ended when: (ponding=true){
		ask rain {
			if (sum(copy_between(runoff_history, length(runoff_history) - 2 ,length(runoff_history))))>= 4{
				ask myself {
					function_attributes["my_qtf"] <- min(3,function_attributes["my_qtf"]+1);
					ponding <- false;
					save [current_date,"ponding_ended",my_name,"my_qtf"] to: "../results/failures.csv" format:"csv" rewrite: false;
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
	float partpoll_yearly_dynamic <- 0.3; // sediment accumulation dynamic = 0.3 cm/year (Chabert et al., 2025) 
	bool saturation <- false;
	date sediment_practice <- starting_date + 1 #year;
	
	// TODO: add randomness
	reflex partpoll_accumulation when: (current_date=sediment_practice) and (current_date > starting_date){
		partpoll_acc <- partpoll_acc + partpoll_yearly_dynamic;
		sediment_practice <- current_date + 1 #year;
	}
	
	// this resets the value of the partpoll accumulation when a sediment removal pratice has been done (action called in maintenance agent)
	action update_sediment_removal (float acc_to_remove){
		if (acc_to_remove = 3.0) {
			partpoll_acc <- 0.0;
		}
		if (acc_to_remove!=3.0) {
			partpoll_acc <- partpoll_acc - acc_to_remove;
		}

		if (function_attributes["my_qtf"]!=3){
			function_attributes["my_qtf"]<- max(3,function_attributes["my_qtf"]+(acc_to_remove/0.9));
		}
		sediment_practice <- current_date + 1 #year;
	}
	
	
	//when filter_media is getting clogged (because of sediment accumulation), vegetation health is impacted
	reflex clogged_fm when: (function_attributes["my_qtf"] <=1) and ((length(my_failures where (each.my_name="partpoll_acc")))>=1) and every(1 #month) and flip(0.7){
		ask my_NBSS.my_vegetation_cover {
			do clogged_fm_on_veg;
		}
	}
	
	//filter media saturation occurs when outlet has an output_unmanaged_flow
	reflex saturation when: (my_downstream_comp != nil) and (my_downstream_comp.my_output_unmanaged_flow.my_flow>=1) and (saturation=false) {
		saturation <- true;
		create failure_event {
			my_name <- "fm_saturation";
			impacted_agent <- myself.my_name;
			impacted_attribute <- "my_qtf";	
			last_failure <- current_date;
			do failure_impact(1.0);
		}		
	}
	
	
	//when vegetation is unhealthy, infiltration performance of filter media is impacted
	action unhealthy_veg_on_fm {
		create failure_event {
			my_name <- "unhealthy_veg_on_fm";
			impacted_agent <- myself.my_name;
			impacted_attribute <- "my_qtf";
			last_failure <- current_date;
			do failure_impact(0.1);
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

species vegetal_component parent: component {
	bool climate_stress <- false;

	// this reflex calculates the Standardized Precipitation Evapotranspiration Index (SPEI) for each season using the data from spei_data retrieved from the climate_spei.csv file
	reflex spei3_season when: (current_date.month = 2 or current_date.month=5 or current_date.month=8 or current_date.month=11)  and (current_date.day = 1) {
		loop i from:0 to:spei_data.rows-1 {
			if current_date = date(string(int(spei_data[0,i]))){
				// find the min and max of the list of spei3 for each season 
				float max_spei3_season <- max(float(spei_data[2,i]),float(spei_data[2,i-1]), float(spei_data[2,i-2]));
				float min_spei3_season <- min(float(spei_data[2,i]),float(spei_data[2,i-1]), float(spei_data[2,i-2]));
				if (max_spei3_season >= 1.5) { // water stress/drowning
					create failure_event {
						my_name <- "water_stress";
						impacted_agent <- my_name;
						impacted_attribute <- "my_health";
						last_failure <- current_date;
						if (my_name="vegetation_cover") {
							do failure_impact(1.0);
						}
						if (my_name="trees") {
							do failure_impact(0.5);
						}

					}
					climate_stress <- true;
				}
				if (min_spei3_season <= -1.5 and current_season!= "winter") { // drought stress - we do not consider drought stress in winter
					create failure_event {
						my_name <- "drought_stress";
						impacted_agent <- my_name;
						impacted_attribute <- "my_health";
						last_failure <- current_date;
						if (my_name="vegetation_cover") {
							do failure_impact(1.0);
						}
						if (my_name="trees") {
							do failure_impact(0.5);
						}

					}climate_stress <- true;
				}
				else { // if no drought or water stress, my_health is increased by 1 or maintained at 3
					do recovering();
					
				}
			}
		}
			
	}
	
	
	// if the vegetation underwent a climate stress at the last spei calculation but is not dead, it can recover if the following spei calculation is between -1.5 and 1.5 
	action recovering {
		if (climate_stress = true) and (function_attributes["my_health"]!= 0) {
			function_attributes["my_health"] <- min(3,function_attributes["my_health"] +1);	
			climate_stress <- false;
		}
	}
	
	//when filter_media is getting clogged (because of sediment accumulation), vegetation health is impacted
	action clogged_fm_on_veg {
		create failure_event {
			my_name <- "clogged_fm_on_veg";
			impacted_agent <- myself.my_name;
			impacted_attribute <- "my_health";
			last_failure <- current_date;
			level_of_impact <- 0.25;
			do failure_impact(level_of_impact);
		}	
	}


	
	
	reflex degraded when: ((function_attributes["my_biodiversity"]<=1 and (function_attributes["my_biodiversity"]!=nil ) or (function_attributes["my_health"]<= 1) and function_attributes["my_health"]!= nil)){
		ask my_NBSS {
				do well_being_impacted ();
				do vegetation_impacted();
		}

	}
	
}



/******************************************* VEGETATION COVER***********************************************/

// Vegetation cover , can be made of one or multiple vegetal components
species vegetation_cover parent: vegetal_component {
	map <string,float> function_attributes <- ["my_health"::3 ,"my_biodiversity"::3];
	bool invasive <- false;
	// this is the delay that it takes for biodiversity to recover when vegetation health has been recovered
	date biodiversity_delay ;
	
	// biodiversity cannot be greather than vegetation health 
		reflex update_biodiversity {
//		// if health of vegetation was recovered by maintenance, biodiversity follows but with a delay
//		if (length(my_failures where (each.impacted_attribute="my_health"))=0 and any(my_failures where (each.last_maintenance != starting_date)) != nil) {
//			biodiversity_delay <- current_date + 15 #day;
//		}
//		else {	function_attributes["my_biodiversity"] <- min(function_attributes["my_health"],function_attributes["my_biodiversity"]);
		//}
		
	}
//	
//	reflex update_biodiversity_delay when: (current_date=biodiversity_delay) {
//		function_attributes["my_biodiversity"] <- function_attributes["my_health"];
//	}
	// when the vegetation cover's global health reaches 1, it impacts the filter media "my_qtf" attribute by -0.25 every month
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
	
}

/***************************************************** TREES *******************************************/

species trees parent: vegetal_component {
	map <string,float> function_attributes <- ["my_health"::3];
	
	
	aspect default {
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -12, 1} anchor: #top_center;
	}
}


/***************************************************** URBAN ENVIRONMENT *******************************************/

species urban_environment {
	string my_name;
	rgb my_color;
	unmanaged_flow overflow;

	action update_overflow(float input_flow){
		overflow.my_flow <- input_flow;
	}
	
	aspect default {
		draw rectangle(100,75) border:#sienna color:#tan ;
		draw my_name font:font("Helvetica", 12, #bold) color:#sienna at: location + {0, -41, 1} anchor: #top_center;
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
	float level_of_impact;
	date last_maintenance <- starting_date;	
	date last_failure <- starting_date;
	
	// impact of a failure event on attributes
	action failure_impact (float impact_level) {
		level_of_impact <- impact_level;
		ask agents of_generic_species component where (each.my_name=impacted_agent){
			function_attributes[myself.impacted_attribute] <- max(0,function_attributes[myself.impacted_attribute]-impact_level);
			myself.last_failure <- current_date;
			add myself to:self.my_failures;
		}
		write my_name + " on " + impacted_agent + " on " + string(current_date,"dd MM yyyy");
		
	}

	
}

/**********************  External failures based on temporal values - trash, leaf accumulation, excessive vegetation, invasive plants etc.. *****************************************/

species ext_time_failure parent: failure_event {
	float my_frequency;
	bool season_dep; //=false if the failure is not season-dependent i.e. frequency is given in weeks per simulation_duration; =true when season-dependent and frequency is given according to weeks in the season
	date next_failure <- starting_date + (my_frequency + rnd(5) - 2)*7 # day;
	
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
	
	// set the date for the next failure
	reflex update_next_failure when: (current_date=next_failure) {
		// for failures independent of seasons
		if (season_dep=false) {
			do ext_time_trigger();
			//The reference date used to compute the next failure is the most recent between last_maintenance and last_failure
			next_failure <- (last_maintenance > last_failure) ? last_maintenance  + (my_frequency + rnd(5) - 2)*7 # day : last_failure + (my_frequency + rnd(5) - 2)*7 # day;
		}
		// for failures dependent of seasons
		if (season_dep=true and seasonal_factor!=0) {
			do ext_time_trigger();
			// if there hasn't been any failure in the season yet, the reference date used to compute the next failure is the most recent between last_maintenance and season_start
			if (last_failure < season_start){
				next_failure <- (last_maintenance < season_start ) ? season_start + (my_frequency + rnd(5) - 2)*7 # day : last_failure + (my_frequency + rnd(5) - 2)*7 # day ;
			}
			if (last_failure > season_start){
				next_failure <- (last_maintenance > last_failure) ? last_maintenance  + (my_frequency + rnd(5) - 2)*7 # day : last_failure + (my_frequency + rnd(5) - 2)*7 # day;
			}

		}
		// if failure should not be triggered at this season, wait for the start of the next season to trigger next failure
		if (season_dep=true and seasonal_factor=0) {
			next_failure <- season_end + 1#day;		
		}
	}
		
		
	action ext_time_trigger  {
		// Some failures occur under conditions : excess_veg on inlet if vegetation_cover.my_health >= 2 and invasive_plants if vegetation_cover.my_health <= 1
		if (my_name="excess_veg"){
			ask any(vegetation_cover) {
				if (function_attributes["my_health"] >= 2) {
					ask myself {
						do failure_impact(1.0);
					}	
				}
			}		
		}
		if (my_name="invasive_plants"){
				ask any(vegetation_cover) {
					invasive <- true;
					if (function_attributes["my_health"] <= 1) {
						ask myself {
						do failure_impact(1.0);
						}
				}
			}
			
		}
		else if (my_name!= "invasive_plants" and my_name != "excess_veg"){
			do failure_impact(1.0);
		}
	}


 }

/**********************  External failures based on metric values : sediment accumulation on filter media *****************************************/

species ext_metric_failure parent: failure_event {
	float my_value; // accumulation value
	float my_threshold;  // threshold that leads to failure (=-1)
	//int my_iteration <- 1; 
	float previous_threshold_crossed <-0;
	
	int last_triggered_n <- -1;
	bool was_outside <- true;
	
	reflex get_metric_value {
		ask agents of_generic_species component where (each.my_name=impacted_agent) {
			myself.my_value <- self get myself.my_name;
		}
	}
	
	reflex ext_metric_trigger { 
		int n <- round(my_value / my_threshold);
		float target <- n * my_threshold;

		bool in_threshold_zone <- abs(my_value - target) <= 0.1;
		if ((current_date != last_failure) and n > 0 and in_threshold_zone and was_outside ){
			do failure_impact(1.0);		
			last_triggered_n <- n;
    		was_outside <- false;	
		}
		if (!in_threshold_zone) {
    		was_outside <- true;
		}	
	}	
}
	
/***************************************************** MAINTENANCE PRACTICE *******************************************/

species maintenance {
	string practice_name;
	
	component impacted_component;
	string impacted_attribute;
	float impact_level; //positive impact of the practice (of how much it improves the value of the attribute)
	
	string my_target_season; // some maintenance practice have to be carried out at a specific season to not impact negatively the vegetation
	bool freq_sensitive <- false;
		
	string linked_failure_name;
	
	// some maintenance practice' execution is delayed so these three parameters are here to trigger delay
	date execution_start<-starting_date;
	float execution_month_delay ;

	// this boolean is used for impact of vegetation sediment removal on filter media
	bool veg_impact_done <- false;
		
	// this represents the delayed date at which the vegetation will respond to the maintenance practice
	float check_veg_delay {
		// if the mp is here to respond to plant_removal then it will take at least one year and a half for the vegetation to get back on track
		if (impacted_component is vegetal_component){
			if (linked_failure_name = "plant_removal") {
				execution_month_delay <- 16.0;
				execution_start <- current_date;
				write "hello execution delay is " + (execution_start + execution_month_delay #month);
			}
			if (linked_failure_name != "plant_removal"){
				int nb_failures <- length(impacted_component.my_failures);
				if (current_season != "winter"){
					execution_month_delay <- ceil(nb_failures / 5.0);
					}
				// if the mp is happening in winter it will take longer
				if (current_season = "winter"){
					execution_month_delay <- ceil(nb_failures / 3.0) ;
				}
			
			}
		}
			
		else {execution_month_delay <-0.0;}
		return execution_month_delay;
	}

	reflex eng_maintenance_practice when: (current_date=execution_start) and (impacted_component is engineered_component) {
		ask agents of_generic_species component where (each.my_name=impacted_component.my_name) {
			function_attributes[myself.impacted_attribute] <- min(3,function_attributes[myself.impacted_attribute]+myself.impact_level);
			rtf_state <- false;	
			preventive_state <- false;
			if (myself.practice_name = "fm_sediment_removal"){
				ask my_NBSS.my_filter_media {
					do update_sediment_removal(3.0);
					//fm_sediment_removal erases also all of the other failures (unhealthy veg and excess veg) that can impact the filter media and sets their last maintenance dat to today = it's like a media replacement
					ask my_failures  where (each.my_name != "partpoll_acc"){
						last_maintenance <- current_date;
					}
					my_failures <- [];
				}
			}
			//reset frequency of failure_events that have been taken care of with maintenance date
			ask my_failures where (each.my_name = myself.linked_failure_name)  {
				last_maintenance <- current_date;

			}
			// in the failures list there will only be left the failures that haven't had a maintenance practice linked to them
			my_failures <- my_failures where (each.my_name != myself.linked_failure_name);
		}
		//do check_veg_negative_impact();

	}

	reflex veg_maintenance_practice when: every(1#month) and (current_date>execution_start) and (current_date <=(execution_start + execution_month_delay #month)) and (impacted_component is vegetal_component) {
		ask agents of_generic_species component where (each.my_name=impacted_component.my_name) {
			function_attributes[myself.impacted_attribute] <- min(3,function_attributes[myself.impacted_attribute]+(myself.impact_level/myself.execution_month_delay));
			rtf_state <- false;
			preventive_state <- false;
			//veg_sediment_removal has a positive impact on filter media as well
			if ((myself.practice_name = "veg_sediment_removal") and (myself.veg_impact_done = false)){
				ask my_NBSS.my_filter_media {
					// sediment removal from the vegetation (i.e., scraping a bit) -> only removes the top layer of sediment_accumulation = what has accumulated over a year
					do update_sediment_removal(partpoll_yearly_dynamic);
					// this removes one partpoll failure event from the list of failures of the filter media
						//remove myself from:my_failures;
				}
				myself.veg_impact_done <- true;
			}
			//reset frequency of failure_events that have been taken care of with maintenance date
			ask my_failures where (each.my_name = myself.linked_failure_name)  {
				last_maintenance <- current_date;

			}
			// in the failures list there will only be left the failures that haven't had a maintenance practice linked to them
			my_failures <- my_failures where (each.my_name != myself.linked_failure_name);
		}
		//do check_veg_negative_impact();

	}


	// some maintenance practices have a negative impact on vegetation cover 
	action check_veg_negative_impact {
		if (impacted_component != nil) {
			ask vegetation_cover where (each.my_NBSS=impacted_component.my_NBSS) {
				// sediment_removal if done when filter media is completely clogged and needs replacement kills all the vegetation if not done in winter
				if (myself.practice_name = "fm_sediment_removal"){
					create failure_event {
						my_name <-"plant_removal";
						impacted_agent <- myself.my_name;
						impacted_attribute <- "my_health";	
						last_failure <- current_date;
						do failure_impact(3.0);
						//Plant_removal takes out all of the failures that have previously impacted vegetation_cover as there will be complete replacement of vegetation
						myself.my_failures <- [];
						// we only keep on failure which is plant_removal 
						add self to:myself.my_failures;
					}
				}
				// when mowing is done in summer, biodiversity is impacted
				if (myself.practice_name="mowing") and (current_season = "summer") {
					create failure_event {
						my_name <- "summer_mowing";
						impacted_agent <- myself.my_name;
						impacted_attribute <- "my_biodiversity";	
						last_failure <- current_date;
						do failure_impact(0.2);
					}
				}
				// when to much vegetation management is done although it is healthy, it impacts the biodiversity
				if (myself.practice_name="excess_veg_management") {
					if (function_attributes["my_health"] = 3) {
						create failure_event {
							my_name <- "excess_veg_management";
							impacted_agent <- myself.my_name;
							impacted_attribute <- "my_biodiversity";	
							last_failure <- current_date;
							do failure_impact(0.2);
						}
					}
				}
				
			}
		}
		}
	

	
}
	


species rtf_maintenance parent: maintenance {
	date rtf_state_date <- starting_date; 
	
	reflex trigger_rtf_maintenance when: (maintenance_type="run-to-failure") and (current_date = rtf_state_date + intervention_delay_days #day ) and (rtf_state_date !=starting_date) {
		maintenance_actions <- maintenance_actions +1;
		do check_veg_negative_impact();
		if (impacted_component is vegetal_component){
			if (impacted_component.my_name = "vegetation_cover"){
				write "youpiiii";
			}
			execution_month_delay <- check_veg_delay();
		}
		else {
			execution_month_delay <-0.0;
		}
		execution_start <- current_date; 
		

	}
		

}

species preventive_maintenance parent: maintenance {
	bool plan_seasonal_practice <- false;
	bool practice_done <- false;
	
	
	action trigger_preventive_maintenance {
		maintenance_actions <- maintenance_actions +1;
		// it's best to do sediment removal when there's no more vegetation = winter
		if (impacted_component is vegetal_component){
			execution_month_delay <- check_veg_delay();
		}
		if (practice_name="sediment_removal"){
			my_target_season <- "winter";
			plan_seasonal_practice <- true;
			
		}
		if (practice_name="mowing"){
			my_target_season <- "fall";
			plan_seasonal_practice <- true;
			
		}
		else {
			execution_month_delay <-0.0;
			execution_start <- current_date; 
		}	
	}
	
	
	reflex plan_seasonal_practice when: (plan_seasonal_practice=true) {
		if (current_season=my_target_season) and (practice_done = false){
			practice_done <- true;
			execution_month_delay <-0.0;
			execution_start <- current_date;
			plan_seasonal_practice <- false;	
		}
	}
}



species scheduled_maintenance parent: maintenance {
	// data from maintenance_scheduled.csv
	float maintenance_frequency;
	string department;
	bool prog_season_dep; //some maintenance practices are season-dependent, i.e. they have a positive impact only if carried out during their target season(s)
	list<string> prog_target_season;
	float cost;
	list<string> processed_failures; // the failures the maintenance practice has taken care of
	
	list<string> linked_failures; // failures for which the maintenance practice responds to 
	
	
	// for each  maintenance practice created, create the list of linked_failures from failure_mp_map
	// TODO: make sure that if a maintenance practice is created it should have a linked failure to it OR create another option..
	reflex link_mp_to_failure  {
		loop index_column from: 0 to: mp_failure_map.columns -1 {
			if mp_failure_map[index_column,0] = practice_name { // find the column corresponding to the maintenance practice in the mp_failure map 
				loop index_row from:1 to: mp_failure_map.rows-1{ // 
					add mp_failure_map[index_column,index_row] to: linked_failures;
				}
			}

		}
	}
	

	reflex trigger_scheduled_maintenance when: (maintenance_type="scheduled")and every(maintenance_frequency #week) and (current_date>starting_date){ 
		maintenance_actions <- maintenance_actions +1;
		ask agents of_generic_species component {
			// go over every failure that has impacted the component and repair specific failure with triggered maintenance practice
			if length(my_failures)>=1{	
				loop j over:my_failures {
					loop i over:myself.linked_failures {
						//the maintenance practice will have a positive impact of +1 = it will repair (+1) as many failures as it is linked to that have impacted the component
						if j.my_name =i{
							ask j {
								myself.function_attributes[impacted_attribute] <- min(3,myself.function_attributes[impacted_attribute]+1);
								//reset failure event frequency with maintenance date
								 last_maintenance <- current_date; 
							}
							add j.my_name to:myself.processed_failures;
						}
					}
				}
			} 
			my_failures <-my_failures where (!(each.my_name in myself.processed_failures)); 
		}
		do check_veg_negative_impact();
	}

}


//******************** EXPERIMENT  *****************************************
	
// Tests for sensitivity analysis	
experiment "explore" type: batch repeat:10 until: (current_date = end_date) {
   parameter 'maintenance:' var: maintenance_type among:["no_maintenance", "run-to-failure", "scheduled", "preventive"] init: "no_maintenance";
	//method exploration with: [[maintenance_type :: "no_maintenance"],[maintenance_type::"run-to-failure"], [maintenance_type::"preventive"],[maintenance_type::"scheduled"]];
	reflex save_results {
		
		ask simulations {
			write "maintenance_type " + maintenance_type ;
		   save [maintenance_actions,accepted_flood_days,flooding_days,degraded_vegetation_days,poor_well_being_days] to: "results.csv" format:"csv" rewrite: false header: true ;
		}
	}

}

// Simple run of model without interface 
experiment "run" type: gui {
	//parameter "maintenance type" var:maintenance_type ; //among:["no maintenance", "run-to-failure", "scheduled", "preventive"];
	output {
		monitor "Accepted flood" value: accepted_flood_days;
		monitor "Flooding" value: flooding_days;
		monitor "Degraded vegetation " value:degraded_vegetation_days;
		monitor "Poor well-being" value:poor_well_being_days;
		monitor "Maintenance" value:maintenance_actions;
		}
	
}

// Interface 
experiment "Interface (EN)"	type: gui {
	//parameter "maintenance type" var:maintenance_type among:["no maintenance", "run-to-failure", "scheduled",  "preventive"];
	output {
		monitor "Accepted flood" value: accepted_flood_days;
		monitor "Flooding" value: flooding_days;
		monitor "Degraded vegetation " value:degraded_vegetation_days;
		monitor "Poor well-being" value:poor_well_being_days;
		monitor "Maintenance" value:maintenance_actions;
		display "Rain" type: 2d {
			chart "Rain events" type: series y_label: "level" y2_label:"mm" y_range: {0,3.5} y2_range:{-120,0} y_tick_unit:1   y2_tick_unit:5 x_serie_labels:string(current_date,"dd MM yyyy"){
				data "Rain" value:rain collect(each.rainfall) color:#lightblue line_visible:true style:line use_second_y_axis: true;
				data "Runoff events" value:rain collect(each.runoff.my_flow) color:#blue line_visible:true marker_shape: marker_up_triangle ;
				}
		}
		display "NBSS performance" type: 2d {
			chart "NBSS evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				//data "Inflow" value:rain collect (each.runoff.my_flow)color: #darkblue marker_shape: marker_down_triangle;
				data "NBSS performance evolution" value:NBSS collect (each.my_global_condition)color: #lightgreen marker_shape: marker_down_triangle;
				//data "Outflow" value:inlet collect (each.my_output_managed_flow.my_flow) color:#deepskyblue marker_shape: marker_up_triangle;
			}
		}
		display "Inlet" type: 2d {
			chart "Inlet evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				//data "Inflow" value:rain collect (each.runoff.my_flow)color: #darkblue marker_shape: marker_down_triangle;
				data "Inflow performance level" value:inlet collect (each.function_attributes["my_qtf"])color: #grey marker_shape: marker_down_triangle;
				//data "Outflow" value:inlet collect (each.my_output_managed_flow.my_flow) color:#deepskyblue marker_shape: marker_up_triangle;
			}
		}
//		display "Ponding area" type: 2d{
//			chart "Ponding area evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
//				//data "Inflow" value:inlet collect (each.my_output_managed_flow.my_flow) color: #darkblue marker_shape: marker_down_triangle;
//				data "Retention performance level" value:ponding_area collect (each.function_attributes["my_qtf"])color: #grey marker_shape: marker_down_triangle;
//				//data "Outflow" value:ponding_area collect (each.my_output_managed_flow.my_flow) color:#deepskyblue marker_shape: marker_up_triangle;
//			}
//		}
		display "Filter media" type: 2d {
			chart "Filter media evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				//data "Inflow" value:ponding_area collect (each.my_output_managed_flow.my_flow) color: #darkblue marker_shape: marker_down_triangle;
				data "Infiltration performance level" value:filter_media collect (each.function_attributes["my_qtf"])color: #grey marker_shape: marker_down_triangle;
				data "Sediment accumulation" value:filter_media collect (each.partpoll_acc) color: #red;
				//data "Outflow" value:filter_media collect (each.my_output_managed_flow.my_flow) color:#deepskyblue marker_shape: marker_up_triangle;
			}
		}
//		display "Outlet" type: 2d {
//			chart "Outlet evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
//				data "Inflow" value:filter_media collect (each.my_output_managed_flow.my_flow) color: #darkblue marker_shape: marker_down_triangle;
//				data "Outflow performance level" value:outlet collect (each.function_attributes["my_qtf"])color: #grey style:dot;
//				data "Outflow" value:outlet collect (each.my_output_managed_flow.my_flow) color:#deepskyblue marker_shape: marker_up_triangle;
//			}
//		}
		display "Vegetation cover" type: 2d {
			chart "Vegetation cover evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				//data "Tree Health" value:trees collect (each.function_attributes["my_health"]) color: #pink marker_shape: marker_down_triangle;
				data "Main vegetation cover health" value:vegetation_cover collect (each.function_attributes["my_health"]) color: #darkblue marker_shape: marker_down_triangle;
				data "Main vegetation cover diversity" value:vegetation_cover collect (each.function_attributes["my_biodiversity"])color: #thistle style: dot;
				
			}
		}
//		display "Performance" type: 2d {
//			chart "Performance assessment" type:histogram
//			y_range:[0,7000]
//			y_tick_unit:1000		
//			y_label: "nb of days"
//			series_label_position: onchart {
//				datalist legend:["Unmanaged flooding", "Accepted flooding","Unhealthy vegetation","Poor well-being","Maintenance actions"] 
//						style: bar
//						value:[flooding_days,accepted_flood_days,degraded_vegetation_days,poor_well_being_days,maintenance_actions] 
//						color:[#lightblue,#blue,#green,#purple,#red];
//						
//			}
//			
//
//		}
	}
}








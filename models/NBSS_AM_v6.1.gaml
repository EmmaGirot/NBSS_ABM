/**
* Name: NBSSAM
* Based on the internal empty template. 
* Author: egirot
* Tags: 
* 
*/

/* v1.6 : 
 * TODO for v6.2
 * - call R from GAMA for spei calculation
 * - add randomness in the days of week in which ext_failures are triggered
 * - add programmed maintenance
 * - add performance indicators 
 */

model NBSSAM

//******************** GLOBAL *****************************************
global {
	float step <-1 #day;
	float step1 <- 1.0;
	
	// Loading csv rainfall and spei file
	file weather_file <- csv_file("../includes/weather_input_gama.csv",",");
	matrix weather_data <- matrix(weather_file);
	
	// TODO : create spei_file according to weather_file by calling R from GAMA
	file spei_file <- csv_file("../includes/climate_spei.csv",",");
	matrix spei_data <- matrix(spei_file);
	
	// Setting simulation timeline
	date starting_date <- date(string(int(weather_data[0,0])));  // starting date of simulation;
	date end_date <- date(string(int(weather_data[0,length(rows_list(weather_data))-1])));
	float simulation_duration <- float((years_between(starting_date,end_date)));
	
	
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
	
	// Loading image files for NBSS visualization
	image_file grass_image <- image_file("../images/grass.png");
	image_file shrubs_plants_image <- image_file("../images/shrubs_plants.png");
	image_file tree_image <- image_file("../images/tree.png");	
	
	// Performance map -> to add in NBSS species ?
	map <string,int> performance <- ["Flood protection"::3,"Natural receiving ecosystem preservation"::3, "Biodiversity preservation"::3,"Aesthetics"::3]; 
	
	bool end_sim<-false;
	bool static_arrows<-true;
	
	// maintenance parameters 
	string maintenance_type <- "no maintenance" parameter: maintenance_type among:["no maintenance", "run-to-failure", "programmed"];
	int intervention_delay_days <- 5 parameter:true  min:2 max: 30;

	
	init {
		
		// Initialization of Rain agent : 
		create rain {
			create managed_flow{
				my_component<- myself;
				myself.runoff <- self;
			}
		}
		// Initialization of NBSS and all its components :
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
			create vegetation_cover {
				my_name<-"vegetation_cover";
				my_NBSS<- myself;
				my_upstream_comp <- my_NBSS.my_ponding_area;
				my_downstream_comp <- my_NBSS.my_filter_media;
				create grass {
					my_name <- "grass";
					myself.my_grass <- self;
				}
				create shrubs_plants {
					my_name <- "shrubs_plants";
					myself.my_shrubs <- self;
				}
				create trees {
					my_name <- "trees";
					myself.my_trees <- self;
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
	
		// The following 2 csv files contain failure event parameters.
		// Here I am creating as many failure events agent as there are lines in the CSV file.
		create ext_time_failure from:csv_file( "../includes/ext_time_failures.csv",';',true) with:
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
		create ext_metric_failure from:csv_file( "../includes/ext_metric_failures.csv",';',true) with:
				[my_name::string(get("failure_name")), 
				impacted_agent::string(get("impacted_agent")),
				impacted_attribute::string(get("impacted_attribute")),
					my_threshold::int(get("threshold"))

			];		
		// The maintenance_practices.csv file contains maintenance practices parameters
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
		save [current_date,runoff.my_flow] to: "../results/runoff.csv" format:"csv" rewrite: true;	
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
	output_flow my_output_managed_flow;
	output_flow my_output_unmanaged_flow;
	rgb my_color;
	list<failure_event> my_failures;
	map <string,int> function_attributes;
	map <int,rgb> condition_color <- [3::#green,2::#yellow,1::#orange,0::#red];
	component my_upstream_comp;
	component my_downstream_comp;
	list<string> my_impacted_agents;
	bool rtf_state <- true;
	
	
	reflex update_color {
		my_color<-condition_color[int(min(function_attributes.values))];	
	}

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
	reflex eng_critic_state when: (function_attributes["my_fqt"]=1) and (rtf_state=true){
		rtf_state <- false;	
		ask rtf_maintenance {
			rtf_state_date <- current_date;
		}
		
	}



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
	reflex unusual_ponding when: (current_date < starting_date) and (my_downstream_comp.my_output_unmanaged_flow.my_flow>=2) and (ponding=false){
		function_attributes["my_fqt"] <- max(0,function_attributes["my_fqt"]-1);
		ponding <- true;
		save [current_date,"unsual_ponding",my_name,"my_fqt"] to: "../results/failures.csv" format:"csv" rewrite: false;
		
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
	float partpoll_acc <- 0.0;
	
	// sediment accumulation dynamic = 0.3 cm/year (Chabert et al., 2025) 
	reflex partpoll_accumulation when: every(1 #year){
		partpoll_acc <- partpoll_acc + 0.3;
	}
	
	//when filter_media is getting clogged (because of sediment accumulation), vegetation health is impacted
	reflex clogged_fm when: (function_attributes["my_fqt"] <=1) and every(1# month){
		ask agents of_generic_species vegetal_component {
			do clogged_fm_on_veg;
		}
	}
	
	//when vegetation is unhealthy, infiltration performance of filter media is impacted
	action unhealthy_veg_on_fm {
		function_attributes["my_fqt"] <- max(0,function_attributes["my_fqt"]-0.25);
		save [current_date,"unhealthy_veg_on_fm",my_name,"my_fqt"] to: "../results/failures.csv" format:"csv" rewrite: false;
		
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
	map <string,float> function_attributes <- ["my_health"::my_health];
	float my_health <- 3.0;	
	float my_health_pre_spei ;

	// find the min and max of the list of spei3 for each season 
	reflex spei3_season when: (current_date.month = 2 or current_date.month=5 or current_date.month=8 or current_date.month=11)  and current_date.day = 1 {
		loop i from:0 to:spei_data.rows-1 {
			if current_date = date(string(int(spei_data[0,i]))){
				float max_spei3_season <- max(float(spei_data[2,i]),float(spei_data[2,i-1]), float(spei_data[2,i-2]));
				float min_spei3_season <- min(float(spei_data[2,i]),float(spei_data[2,i-1]), float(spei_data[2,i-2]));
				if (max_spei3_season >= 1.5) { // water stress/drowning
					do dying();  
					save [current_date,"water_stress",my_name,"my_health"] to: "../results/failures.csv" format:"csv" rewrite: false;
					
				}
				if (min_spei3_season <= -1.5 and current_season!= "winter") { // drought stress - we do not consider drought stress in winter
					do dying();
					save [current_date,"drought_stress",my_name,"my_health"] to: "../results/failures.csv" format:"csv" rewrite: false;
					
				}
				else { // if no drought or water stress, my_health is increased by 1 or maintained at 3
					do recovering();
					save [current_date,"recovering",my_name,"my_health"] to: "../results/failures.csv" format:"csv" rewrite: false;
					
				}
			}
		}
			
	}
	
	action dying {
		my_health <- max(0,my_health -1);	
	}
	
	action recovering {
		my_health <- min(3,my_health +1);		
	}
	
	//when filter_media is getting clogged (because of sediment accumulation), vegetation health is impacted
	action clogged_fm_on_veg {
		my_health <- max(0,my_health - 0.25);
		save [current_date,"clogged_fm_on_veg",my_name,"my_health"] to: "../results/failures.csv" format:"csv" rewrite: false;
		
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

/******************************************* VEGETATION COVER***********************************************/

// Vegetation cover , can be made of one or multiple vegetal components
species vegetation_cover parent: component {
	component my_surface;
	grass my_grass;
	shrubs_plants my_shrubs;
	trees my_trees;
	map <string,int> function_attributes <- ["my_health"::my_global_health,"my_diversity"::my_diversity];
	int my_diversity <- 3;
	float my_global_health;
	bool invasive <- false;
	
	reflex my_health {
		my_global_health <- min(my_grass.my_health,my_shrubs.my_health);
	}
	
	// when the vegetation cover's global health reaches 1, it impacts the filter media "my_fqt" attribute by -0.25 every month
	reflex unhealthy_veg when: (my_global_health<=1) and every(1 #month) {
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

	// impact of a failure event on attributes
	action failure_impact (failure_event failure) {
		ask agents of_generic_species component where (each.my_name=failure.impacted_agent){
			function_attributes[failure.impacted_attribute] <- max(0,function_attributes[failure.impacted_attribute]-1);
			failure.last_failure <- current_date;
			write failure.my_name + " on " + failure.impacted_agent + " on " + string(current_date,"dd MM yyyy");
			add failure to:self.my_failures;
			save [current_date,failure.my_name,failure.impacted_agent,failure.impacted_attribute] to: "../results/failures.csv" format:"csv" rewrite: false;

		}
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
							if (my_global_health >= 2) {
								ask myself {
									do failure_impact(self);
								}
							}
						}
						
					}
					if (my_name="invasive_plants"){
							ask any(vegetation_cover) {
								invasive <- true;
								if (my_global_health <= 1) {
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
							if (my_global_health >= 2) {
								ask myself {
									do failure_impact(self);
								}
							}
						}
						
					}
					if (my_name="invasive_plants"){
							ask any(vegetation_cover) {
								invasive <- true;
								if (my_global_health <= 1) {
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
				function_attributes["my_health"] <- 3;
		
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
				function_attributes["my_health"] <- 3;
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
	
// Tests for sensitivity analysis	
experiment "tests" type: batch repeat:10 until:end_sim{
	
}

// Simple run of model without interface 
experiment "run" {
	
}

// Interface 
experiment "Interface (EN)"	type: gui {
	output {
		display "Rain" type: 2d {
			chart "Runoff" type: series y_label: "class" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				data "Runoff events" value:rain collect(each.runoff.my_flow) color:#blue line_visible:false style: dot ;
				}
		}
		display "Inlet" type: 2d {
			chart "Inlet evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				data "Inflow" value:rain collect (each.runoff.my_flow)color: #darkblue marker_shape: marker_down_triangle;
				data "Inflow performance level" value:inlet collect (each.function_attributes["my_fqt"])color: #grey style: dot;
				data "Outflow" value:inlet collect (each.my_output_managed_flow.my_flow) color:#deepskyblue marker_shape: marker_up_triangle;
			}
		}
		display "Ponding area" type: 2d{
			chart "Ponding area evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				data "Inflow" value:inlet collect (each.my_output_managed_flow.my_flow) color: #darkblue marker_shape: marker_down_triangle;
				data "Retention performance level" value:ponding_area collect (each.function_attributes["my_fqt"])color: #grey style: dot;
				data "Outflow" value:ponding_area collect (each.my_output_managed_flow.my_flow) color:#deepskyblue marker_shape: marker_up_triangle;
			}
		}
		display "Filter media" type: 2d {
			chart "Filter media evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				data "Inflow" value:ponding_area collect (each.my_output_managed_flow.my_flow) color: #darkblue marker_shape: marker_down_triangle;
				data "Infiltration performance level" value:filter_media collect (each.function_attributes["my_fqt"])color: #grey style: dot;
				data "Sediment accumulation" value:filter_media collect (each.partpoll_acc) color: #red;
				data "Outflow" value:filter_media collect (each.my_output_managed_flow.my_flow) color:#deepskyblue marker_shape: marker_up_triangle;
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
			chart "Vegetation evolution" type: series y_label: "level" y_range: {0,3.5} x_serie_labels:string(current_date,"dd MM yyyy") y_tick_unit:1 {
				data "Health" value:vegetation_cover collect (each.my_global_health) color: #darkblue marker_shape: marker_down_triangle;
				data "Diversity" value:vegetation_cover collect (each.my_diversity)color: #thistle style: dot;
			}
		}
	}
}







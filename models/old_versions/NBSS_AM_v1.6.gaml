/**
* Name: NBSSAM
* Based on the internal empty template. 
* Author: egirot
* Tags: 
* 
*/

/* v4.1 evolutions : 
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
	
	// maintenance parameters 
	string maintenance_type <- "no maintenance" parameter: maintenance_type among:["no maintenance", "run-to-failure", "programmed"];
	int intervention_delay_days <- 5 parameter:true  min:2 max: 30;

	
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
				create failure_event {
					my_name<-"overly_dense_vegetation"; 
				    impacted_agent<-myself.my_name;
				    impacted_attribute<-"my_fqt";
				    internal <- true;
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
				create failure_event {
					my_name<-"vegetation_cover_dying"; 
				    impacted_agent<-myself.my_name;
				    impacted_attribute<-"my_fql";
				    internal <- true;
				}
				create failure_event {
					my_name<-"unusual_ponding"; 
				    impacted_agent<-myself.my_name;
				    impacted_attribute<-"my_fqt";
				    internal <- true;
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
				create failure_event {
					my_name<-"sediment_acc"; 
				    impacted_agent<-myself.my_name;
				    impacted_attribute<-"my_fqt";
				    internal <- true;
				}
				create failure_event {
					my_name<-"saturation"; 
				    impacted_agent<-myself.my_name;
				    impacted_attribute<-"my_fqt";
				    internal <- true;
				}
			}	
		
			create grass with: [location::{45, 33}] {
				my_name <- "grass";
				my_NBSS<- myself;
				my_upstream_comp <- my_NBSS.my_filter_media;
				my_water_stress_threshold <- 20 #days;
				my_growing_factor <- 10;
				myself.my_grass <- self;
				add self to:myself.my_vegetal_components;
				create managed_flow{
					my_component <- myself;
					myself.my_output_managed_flow <- self;
				}
				create unmanaged_flow {
					my_component <- myself;
					myself.my_output_unmanaged_flow <- self;
				}
				create failure_event {
					my_name<-"drowning"; 
				    impacted_agent<-myself.my_name;
				    impacted_attribute<-"my_health";
				    internal <- true;
				}
				create failure_event {
					my_name<-"water_stress"; 
				    impacted_agent<-myself.my_name;
				    impacted_attribute<-"my_health";
				    internal <- true;
				}
				create failure_event {
					my_name<-"disspoll_acc"; 
				    impacted_agent<-myself.my_name;
				    impacted_attribute<-"my_health";
				    internal <- true;
				}
			}
			
			create shrubs_plants with: [location::{62, 31}] {
				my_name <- "shrubs_plants";
				my_NBSS<- myself;
				my_upstream_comp <- my_NBSS.my_filter_media;
				my_water_stress_threshold <- 30 #days;
				my_growing_factor <- 20;
				myself.my_shrubs_plants <- self;
				add self to:myself.my_vegetal_components;
				create managed_flow{
					my_component <- myself;
					myself.my_output_managed_flow <- self;
				}
				create unmanaged_flow {
					my_component <- myself;
					myself.my_output_unmanaged_flow <- self;
				}
				create failure_event {
					my_name<-"drowning"; 
				    impacted_agent<-myself.my_name;
				    impacted_attribute<-"my_health";
				    internal <- true;
				}
				create failure_event {
					my_name<-"water_stress"; 
				    impacted_agent<-myself.my_name;
				    impacted_attribute<-"my_health";
				    internal <- true;
				}
				create failure_event {
					my_name<-"disspoll_acc"; 
				    impacted_agent<-myself.my_name;
				    impacted_attribute<-"my_health";
				    internal <- true;
				}
			}
			
			create trees with: [location::{80, 27}]{
				my_name <- "trees";
				my_NBSS<- myself;
				my_upstream_comp <- my_NBSS.my_filter_media;
				my_water_stress_threshold <- 40 #days;
				my_growing_factor <- 10;
				myself.my_trees <- self;
				add self to:myself.my_vegetal_components;
				create managed_flow{
					my_component <- myself;
					myself.my_output_managed_flow <- self;
				}
				create unmanaged_flow {
					my_component <- myself;
					myself.my_output_unmanaged_flow <- self;
				}
				create failure_event {
					my_name<-"drowning"; 
				    impacted_agent<-myself.my_name;
				    impacted_attribute<-"my_health";
				    internal <- true;
				}
				create failure_event {
					my_name<-"water_stress"; 
				    impacted_agent<-myself.my_name;
				    impacted_attribute<-"my_health";
				    internal <- true;
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
				create failure_event {
					my_name<-"overly_dense_vegetation"; 
				    impacted_agent<-myself.my_name;
				    impacted_attribute<-"my_fqt";
				    internal <- true;
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
			
	
		// The csv file containes lines of failure events and their attributes.
		// Here I am creating as many failure events agent as there are lines in the CSV file. 
		create failure_event from:csv_file( "../includes/failures.csv",';',true) with:
			[my_name::string(get("failure_name")), 
				my_frequency::float(get("failure_frequency_weeks")), 
				impacted_agent::string(get("impacted_agent")),
					impacted_attribute::string(get("impacted_attribute")),
					internal :: false
			];
			
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
	grass my_grass;
	shrubs_plants my_shrubs_plants;
	trees my_trees;
	list<engineered_component> my_engineered_components;
	list<vegetal_component> my_vegetal_components;
	list<component> my_components;
	float my_vegetation_cover; // % sum of grass and shrubs_plants density

	 
	reflex update_vegetation_cover {
		my_vegetation_cover <- (my_grass.my_density + my_shrubs_plants.my_density)/2;
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
	map <string,float> function_attributes <- ["my_fqt"::3,"my_fql"::3];
	output_flow my_output_managed_flow;
	output_flow my_output_unmanaged_flow;
	rgb my_color;
	list<failure_event> my_failures;
	map <int,rgb> condition_color <- [3::#green,2::#yellow,1::#orange,0::#red];
	component my_upstream_comp;
	component my_downstream_comp;
	list<string> my_impacted_agents;
	int vegetation_iteration <- 1; // 
	int my_vegetation_threshold <- 150; //%
	date critic_state_date <- starting_date; // date qui va déclencher le run to failure maintenance 
	bool critic_state <- true;
	int buffer_upstream <- 2;
	
	
	reflex update_color {
		my_color<-condition_color[int(min(function_attributes.values))];	
	}
	
	reflex overly_dense_vegetation_cover when: (my_NBSS.my_vegetation_cover >= vegetation_iteration*my_vegetation_threshold) {
		ask failure_event where (each.my_name="overly_dense_vegetation"){
			if (current_date != last_failure) {
				do trigger_internal_failure(self);
				}
		}
		vegetation_iteration <- vegetation_iteration +1;
	}

	action flow_downstream {
		do update_output_flows(my_upstream_comp.my_output_managed_flow.my_flow);
		ask agents of_generic_species output_flow where(each.my_component=self){
			do update_output_disspoll_load(myself.function_attributes["my_fql"], self.my_disspoll_load);
			do update_output_partpoll_load(myself.function_attributes["my_fql"], self.my_partpoll_load);
		} 
		ask my_NBSS.my_components where(each.my_upstream_comp = self) {
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
	bool upstream_state <- true;

	//failure event decreases impacted_attribute value by 0.25
	action eng_response_to_failure (failure_event failure) {
		function_attributes[failure.impacted_attribute] <- max(0,function_attributes[failure.impacted_attribute]-0.25);
		write failure.my_name + " on " + failure.impacted_agent + " on " + string(current_date,"dd MM yyyy");
		add failure to:my_failures;
		save [current_date,failure.my_name,failure.impacted_agent,failure.impacted_attribute] to: "../results/failures.csv" format:"csv" rewrite: false;
		failure.last_failure <- current_date;
	}
	

	reflex eng_critic_state when: (function_attributes["my_fqt"]=1) and (upstream_state=true){
		critic_state_date <- current_date;
		critic_state <- false;	
	}


//	// TODO: it would be good if I actually put this in maintenance practice agent no?
	reflex eng_rtf_maintenance when: (critic_state_date!= starting_date) and (current_date = critic_state_date + intervention_delay_days #days) and (maintenance_type = "run-to-failure"){
			function_attributes[] <- 3;
			critic_state<- true;
			if (my_name = "filter_media") {
				ask my_NBSS.my_filter_media{
					disspoll_acc <- 0.0;
					sediment_acc <- 0.0;
					function_attributes[] <- 3;
				}
				
			}
	}
	
		
//	//all function attributes of impacted_agent are back to best performance = 3
//	action eng_response_to_maintenance (maintenance_practice maintenance) {
//		function_attributes[] <- 3;
//		
//		//reset failure event frequency with maintenance date
//		ask my_failures where (each.my_name=maintenance.linked_failure_event){
//			last_maintenance <- current_date;
//		}
//		
//		// remove failure events that are going to be maintained from the my_failures list
//		remove all:(my_failures where (each.my_name=maintenance.linked_failure_event)) from:my_failures;
//
//	}
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
	
			
	// when grass and shrubs_plants densities are too low (sum <= 2), ponding area fql (sedimentation process) is impacted (put a buffer?)
	reflex vegetation_cover_dying when: (my_NBSS.my_vegetation_cover <=30) and (current_date != starting_date) {
		ask failure_event where (each.my_name="vegetation_cover_dying"){
			do trigger_internal_failure(self);
		}
	}

	
//	//unusual ponding occurs when filter media has output unmanaged flow
//	// TODO: je sais pas comment faire avec le unusual ponding 
	// quand le filter media a du unmanaged output flow , ça va venir faire baisser la capacité de stockage du ponding area pendant un temps limité non?
	reflex unusual_ponding when: (my_NBSS.my_filter_media.my_output_unmanaged_flow.my_flow=2){
		ask failure_event where (each.my_name="unusual_ponding"){
			if (current_date != last_failure){
				do trigger_internal_failure(self);
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
	// sediment related attributes
	int sediment_iteration <- 1;
	float sediment_acc <- 0.0;
	int my_sediment_threshold <- 5; // modify according to what we want
	
	// saturation related attributes
	int my_saturation_delay_period <- 3; //nb of rainy days until filter media is saturated
	date last_saturation <- starting_date;
	bool saturated <- false;
	
	// dissolved pollution related attributes
	float disspoll_acc<-0.0;
	
	
	// sediments progressively deposit on filter media which blocks infiltration (internal failure)
	reflex sediment_accumulation {
	// the lower the flow rate, the more sediment is deposited (Deletic et al., 2006) 
	// TODO : affect correct values 
	// if inflow = 1 -> sediment_acc = partpoll_load/5 , if inflow = 2 -> sediment crust = partpoll_load/10, if inflow = 3 -> sediment crust = partpoll_load/20
		if (int(my_upstream_comp.my_output_managed_flow.my_flow) = 1) {
			sediment_acc <-sediment_acc + (my_upstream_comp.my_output_managed_flow.my_partpoll_load/5);
			}
		if (int(my_upstream_comp.my_output_managed_flow.my_flow) = 2) {
			sediment_acc <- sediment_acc + (my_upstream_comp.my_output_managed_flow.my_partpoll_load/10);
			}
		if (int(my_upstream_comp.my_output_managed_flow.my_flow) = 3) {
			sediment_acc <- sediment_acc + (my_upstream_comp.my_output_managed_flow.my_partpoll_load/20);
			}
	}
	// TODO : à tous les multiples de sediment_threshold, FM clogging est appelé (si sediment_threshold c'est 10, alors FM clogging est appelé quand sediment threshold = 10,20 puis 30
	reflex clogging when: (sediment_acc = sediment_iteration*my_sediment_threshold) {
		ask failure_event where (each.my_name="sediment_acc") {
			do trigger_internal_failure(self);
			
		}sediment_iteration <- sediment_iteration +1;	
	}
	
	// if it's been raining for more than x amount of days (my_saturation_delay_period) straight : filter media is saturated with water not possible to infiltrate anymore -> ponding occurs as well 
	// this is something temporary, whenever it doesn't rain anymore, functionality is back
	reflex saturation {
		ask rain { 
			if (sum(copy_between(runoff_history, length(runoff_history) - myself.my_saturation_delay_period ,length(runoff_history)))>=3) and (current_date >= myself.last_saturation plus_days myself.my_saturation_delay_period ){
				ask failure_event where (each.my_name="saturation") {
					do trigger_internal_failure(self);
					
				}
				myself.last_saturation <- current_date;
				myself.saturated <- true;
			}
		}	
		
	
	}
	
	
	reflex saturation_ok when: (saturated = true){
		ask rain {
			if (sum(copy_between(runoff_history, length(runoff_history) - 3,length(runoff_history)))= 0) {
				loop attribute_keys over: myself.function_attributes.keys {
				myself.function_attributes[attribute_keys] <- min(3,myself.function_attributes[attribute_keys]+0.25);	
				myself.saturated <- false;
				}
			}
		}
	}

		
	
		// dissolved pollution progressively accumulates in filter media which deteriorates health of vegetation (?) 
	reflex disspoll_accumulation {
		// TODO : affect correct values 
		disspoll_acc <-disspoll_acc + (my_upstream_comp.my_output_managed_flow.my_disspoll_load/10);

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
	int my_density <- 50; // in % -> allows to calculate vegetation_cover that will impact ponding area fql as well as inlet and outlet fqt (overly_dense_vegetation)
	float my_health <- 3.0;
	float my_water_stress_threshold;
	list<float> my_health_history;
	int my_growing_factor; //nb of days at health=3 needed for the vegetation density to increases of 0.25 (?) -> it will eventually become overly dense and create a dysfunction
	date last_growth <- starting_date;
	int disspoll_threshold <- 9; // why did I put 9 ? what can I put ? 
	int disspoll_iteration <- 1;
	int drowning_threshold <- 5; // number of continuous rainy days that will lead to vegetation drowning
	
	reflex health_history {
		add my_health to: my_health_history; //creates a list with all the previous values of my health
		// when the vegetation's health is good for a certain amount of time (my_growing_factor) -> its density increases
		if (sum(copy_between(my_health_history, length(my_health_history) - my_growing_factor ,length(my_health_history)))=3*my_growing_factor) and (current_date >= last_growth + my_growing_factor #days){
			my_density <- min(200,my_density + 5);
			last_growth <- current_date;
		}
	}
	
	// when FM has accumulated to much pollution, health of vegetation is deteriorated
	reflex contaminated when: (my_NBSS.my_filter_media.disspoll_acc = disspoll_iteration*disspoll_threshold){
		ask failure_event where (each.my_name="disspoll_acc") {
			do trigger_internal_failure(self);
		}disspoll_iteration <- disspoll_iteration +1;
	}
	
		//  water sufficiency on vegetation
	// TODO : affect correct values
	reflex water_sufficiency when: (any(rain).runoff.my_flow != 0) {
			loop attribute_keys over: function_attributes.keys {
				function_attributes[attribute_keys] <- min(3,function_attributes[attribute_keys]+0.25);
			}
			my_health <- min(3,my_health + 0.25);
	}
	
	// water stress on vegetal components  
	reflex water_stress when: (any(rain).last_rain != nil and current_date = any(rain).last_rain + my_water_stress_threshold){
			ask failure_event where (each.my_name="water_stress" and each.impacted_agent=self.my_name) {
				do trigger_internal_failure(self);
			}
	}
	
	//  vegetation drowning when too much runoff 
	reflex drowning {
		ask rain { 
			// TODO : affect correct values 
			if (sum(copy_between(runoff_history, length(runoff_history) - 6 ,length(runoff_history)))>= 6){
				ask failure_event where (each.my_name="drowning" and each.impacted_agent=myself.my_name) {
					if (current_date != last_failure) {
						do trigger_internal_failure(self);
					}
				}
			}
		}
	}
	
	// when vegetation health is deteriorating it slowly impacts its density (diminishes by 0.1)
	reflex dying when: (my_health<=1){ // + buffer to show that vegetation needs time to respond ?
			my_density <- min(0,my_density-10);
	}
	
	//failure event decreases impacted_attribute value by 0.25
	action veg_response_to_failure (failure_event failure) {
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
		add failure to:my_failures;
		save [current_date,failure.my_name,failure.impacted_agent,failure.impacted_attribute] to: "../results/failures.csv" format:"csv" rewrite: false;
		
	}
	
	// TODO: it would be good if I actually put this in maintenance practice agent no?
	reflex veg_critic_state when: (my_health <= 1) and (critic_state =true){
			critic_state_date <- current_date;
			critic_state <- false;
	}
	
	// TODO: it would be good if I actually put this in maintenance practice agent no?
	reflex veg_rtf_maintenance when: (current_date = critic_state_date + intervention_delay_days #days) and (critic_state_date !=starting_date) and (maintenance_type = "run-to-failure"){
			my_health <- 3.0;
			function_attributes[] <- 3;
			critic_state<- true;
	}

//	
//	//all function attributes of impacted_agent are back to best performance = 3
//	action veg_response_to_maintenance (maintenance_practice maintenance) {
//		my_health <- 3.0;
//		function_attributes[] <- 3;
//		
//		//reset failure event frequency with maintenance date
//		ask my_failures where (each.my_name=maintenance.linked_failure_event){
//			last_maintenance <- current_date;
//		}
//		
//		// remove failure events that are going to be maintained from the my_failures list
//		remove all:(my_failures where (each.my_name=maintenance.linked_failure_event)) from:my_failures;
//
//	}

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
		draw shrubs_plants_image size: {20.0, 12.0, 0.0};
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
	float my_frequency;
	string impacted_agent;
	string impacted_attribute;
	date last_maintenance <- starting_date;	
	date last_failure <- starting_date;
	bool internal;
	
	
	// the failure event has a fixed frequency but the frequency is reset every time a maintenance practice is carried out
	reflex trigger_external_failure when: (internal = false) and (current_date!=starting_date){
		loop i from:1 to: (simulation_duration*52)/my_frequency {
			if (current_date = last_maintenance + (i*my_frequency #week)) {
				// change the performance level of the impacted attribute of the impacted agent
				ask agents of_generic_species vegetal_component where (each.my_name=self.impacted_agent){
					do veg_response_to_failure(myself);
				}
				ask agents of_generic_species engineered_component where (each.my_name=self.impacted_agent){
					do eng_response_to_failure(myself);
				}
			}			
		}
	}
	
	//action trigger_internal_failure(string name_of_failure, string agent_to_impact, string attribute_to_impact) {
	action trigger_internal_failure (failure_event failure) {
		ask agents of_generic_species vegetal_component where (each.my_name=failure.impacted_agent){
			do veg_response_to_failure(failure);
		}
		ask agents of_generic_species engineered_component where (each.my_name=failure.impacted_agent){
			do eng_response_to_failure(failure);
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

	
//	reflex trigger_prog_maintenance when: (maintenance_type="programmed")and every(maintenance_frequency){
//		// if the maintenance practice's scope is specific, find the impacted_agent
//		if (practice_scope = "specific"){
//			ask agents of_generic_species vegetal_component where (each.my_name=impacted_agent){
//				do veg_response_to_maintenance(myself);
//			}
//			ask agents of_generic_species engineered_component where (each.my_name=impacted_agent){
//				do eng_response_to_maintenance(myself);
//			}
//		}
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
//	}
}


//******************** EXPERIMENT  *****************************************
	
	
experiment "tests" type: batch repeat:10 until:end_sim{
	
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
				data "Pollution particulairedu ruissellement" value: rain collect(each.runoff.my_partpoll_load) color:#maroon style:dot;
				}
		
		}
		display "Runoff quantity control" type: 2d {
			chart "Gestion du ruissellement" type: series y_label: "fonctionnalité" y_range: {0,3} y2_label: "accumulation (% de surface recouverte)" y2_range: {0,100} y_tick_unit:1 y2_tick_unit:5 x_serie_labels:string(current_date,"dd MM yyyy"){
				data "Entrée d'eau" value:inlet collect (each.function_attributes["my_fqt"])color: #grey marker_shape: marker_down_triangle;
				data "Zone de rétention" value:ponding_area collect (each.function_attributes["my_fqt"]) color: #deepskyblue marker_shape: marker_circle;
				data "Média filtrant" value:filter_media collect (each.function_attributes["my_fqt"]) color: #darkgoldenrod marker_shape: marker_diamond;
				//data "Sortie d'eau / Rejet" value:outlet collect (each.function_attributes["my_fqt"]) color:#black marker_shape: marker_up_triangle;
				data "Accumulation de sédiments sur média filtrant" value:filter_media collect (each.sediment_acc)color: #maroon marker_shape: marker_circle use_second_y_axis: true;
				data "Accumulation de pollution dissoute dans média filtrant" value:filter_media collect (each.disspoll_acc)color: #red marker_shape: marker_circle use_second_y_axis: true;
				
			}
		}
		display "Vegetation state" type: 2d {
			chart "Santé et densité de la végétation" type: series y_label: "état de santé" y_tick_unit:1 y2_label: "densité %" y2_range: {0,200} y2_tick_unit:10 x_serie_labels:string(current_date,"dd MM yyyy"){
				data "Santé du couvert herbacée" value:grass collect (each.my_health) color: #lime marker_shape: marker_square;
				data "Santé des plantes" value:shrubs_plants collect (each.my_health) color: #limegreen marker_shape: marker_square;
				data "Santé des arbres" value:trees collect (each.my_health) color: #forestgreen marker_shape: marker_square;
				data "Couverture herbacée et arbustive" value:NBSS collect (each.my_vegetation_cover) color:#yellowgreen marker_shape: marker_diamond use_second_y_axis: true;
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







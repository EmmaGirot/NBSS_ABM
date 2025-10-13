/**
* Name: NBSSAM
* Based on the internal empty template. 
* Author: egirot
* Tags: 
* 
*/

/* v3.1 evolutions : 
 * - Each NBSS component has two types of functions instead of my_condition :
 * 	fqt linked to runoff quantity control 
 *  fql linked to runoff quality control
 * - Vegetation species does not exist anymore and is divided into three different species : grass, shrubs_plants, trees
 * - Maintenance practices are divided into 3 level groups defined by new attribute called practice_level in maintenance_practices.csv: 
 * 	Level 1 : inspection -> no impact on functionality but if a failure event appears before an inspection, the inspection leads to function rehabilitation
 * 	Level 2 : routine maintenance -> positive impact on functionality impacted by corresponding FE
 *  Level 3 : rehabilitation -> positive impact on all functionalities 
 * - Maintenance practice specie has a new attribute called practice_scope. Practice_scope can be : 
 *  Specific to an NBSS agent and in that case maintenance practice is carried out only on that agent (restores score of all attributes of impacted_agent)
 *  General : maintenance practice is carried out on all NBSS agents impacted by linked failure event and restores level_of_performance of all attributes
 * 
 */

model NBSSAM

//******************** GLOBAL *****************************************
global {
	float step <-1 #day; 
	date starting_date <- date([2014, 1, 1, 8, 0, 0]);  // starting date of simulation;
	float simulation_duration <- 10 #years;
	date end_date <- starting_date + simulation_duration;
	list<component> all_components;
	int current_event_number<-0;
	map <string,int> level_of_performance <- ["excellent"::3,"good"::2,"moderate"::1,"poor"::0];
	map <int,rgb> condition_color <- [3::#green,2::#yellow,1::#orange,0::#red];
	// csv file that has the logic table which calculates the output flow depending on input and condition values
	file output_flow_LT_file <- csv_file( "../includes/output_flow_LT.csv",';',int);
	file output_poll_LT_file <- csv_file("../includes/output_poll_load_LT.csv",";",int);
	image_file NBSS_image_file <- image_file("../includes/NBSS_image.png");
	//float choose_event_frequency <- 3 #week parameter: true min:0.0 max: 10.0;
	//float choose_maintenance_frequency <- 7 #week parameter: true min:0.0 max: 10.0;
	
	bool end_sim<-false;
	bool static_arrows<-true;
	
	//nb of events
	int nb_trash<-0;
	int nb_sediment<-0;
	
	init {

		create rain {
			create managed_flow{
				my_component<- myself;
				myself.runoff <- self;
			}
		}
		create NBSS {
			my_name <- "bioretention";
		
		}
		create inlet {
			add self to:all_components;
			my_NBSS<-one_of(NBSS where (each.my_name ="bioretention"));
			// we start the simulation with all performance attributes at an excellent level of performance
			my_name<-"inlet";
			create managed_flow{
				my_component <- myself;
				myself.my_output_managed_flow <- self;
			}
			create unmanaged_flow {
				my_component <- myself;
				myself.my_output_unmanaged_flow <- self;

			}
		}
		
		create ponding_area {
			add self to:all_components;
			my_NBSS<-one_of(NBSS where (each.my_name ="bioretention"));
			// we start the simulation with all performance attributes at an excellent level of performance
			my_name<-"ponding_area";
			create managed_flow{
				my_component <- myself;
				myself.my_output_managed_flow <- self;
			}
			create unmanaged_flow {
				my_component <- myself;
				myself.my_output_unmanaged_flow <- self;
			}
		}	
		
		create filter_media {
			add self to:all_components;
			my_NBSS<-one_of(NBSS where (each.my_name ="bioretention"));
			// we start the simulation with all performance attributes at an excellent level of performance
			my_name<-"filter_media";
			create managed_flow{
				my_component <- myself;
				myself.my_output_managed_flow <- self;
			}
			create unmanaged_flow {
				my_component <- myself;
				myself.my_output_unmanaged_flow <- self;
			}
		}	
		
		create grass {
			add self to:all_components;
			my_NBSS<-one_of(NBSS where (each.my_name="bioretention"));
			my_name <- "grass";
			create managed_flow{
				my_component <- myself;
				myself.my_output_managed_flow <- self;
			}
			create unmanaged_flow {
				my_component <- myself;
				myself.my_output_unmanaged_flow <- self;
			}
		}
		
		create shrubs_plants {
			add self to:all_components;
			my_NBSS<-one_of(NBSS where (each.my_name="bioretention"));
			my_name <- "shrubs_plants";
			create managed_flow{
				my_component <- myself;
				myself.my_output_managed_flow <- self;
			}
			create unmanaged_flow {
				my_component <- myself;
				myself.my_output_unmanaged_flow <- self;
			}
		}
		
		create trees {
			add self to:all_components;
			my_NBSS<-one_of(NBSS where (each.my_name="bioretention"));
			my_name <- "trees";
			create managed_flow{
				my_component <- myself;
				myself.my_output_managed_flow <- self;
			}
			create unmanaged_flow {
				my_component <- myself;
				myself.my_output_unmanaged_flow <- self;
			}
		}
		
		create outlet {
			add self to:all_components;
			my_NBSS<-one_of(NBSS where (each.my_name="bioretention"));
			my_name <- "outlet";
			create managed_flow{
				my_component <- myself;
				myself.my_output_managed_flow <- self;
			}
			create unmanaged_flow {
				my_component <- myself;
				myself.my_output_unmanaged_flow <- self;
			}
		}		

		create urban_environment {
			create unmanaged_flow{
				my_component<- myself;
				myself.overflow <- self;
			}
			
		}
		// The csv file containes lines of failure events and their attributes.
		// Here I am creating as many failure events agent as there are lines in the CSV file. 
		create failure_event from:csv_file( "../includes/failures.csv",';',true) with:
			[failure_name::string(get("failure_name")), 
				failure_frequency::float(get("failure_frequency_weeks"))#week, 
				impacted_agent::string(get("impacted_agent")),
					impacted_attribute::string(get("impacted_attribute")
				)
			];
			
		// The maintenance_practices.csv file containes lines of maintenance practices and their attributes.
		// Here I am creating as many maintenance practice agent as there are lines in the CSV file. 
//		create maintenance_practice from:csv_file( "../includes/maintenance_practices.csv",';',true) with:
//			[practice_name::string(get("practice_name")), 
//				practice_scope::string(get("practice_scope")),
//				practice_level::int(get("practice_level")),
//				maintenance_frequency::float(get("practice_frequency_weeks"))#week, 
//				impacted_agent::string(get("impacted_agent")),
//				linked_failure_event::string(get("linked_failure_event"))
//			];	
		
	}	


	reflex go{
				
			// first, compute inlet output flow and associated pollutant loads with runoff as input flow
			ask any(inlet){ 
				do update_output_flows(any(rain).runoff.my_flow);
				ask agents of_generic_species output_flow where(each.my_component=self){
					do update_output_partpoll_load(myself.function_attributes["my_fql"], self.my_partpoll_load);
				}
			}
	
			// then compute ponding area output flows and associated pollutant loads with inlet output_managed_flow as input flow
			// ponding area allows for water storage and sedimentation (settles partpoll load)
			ask any(ponding_area) {		
				do update_output_flows(any(inlet).my_output_managed_flow.my_flow);
				ask agents of_generic_species output_flow where(each.my_component=self){
					do update_output_partpoll_load(myself.function_attributes["my_fql"], self.my_partpoll_load);
				}
			}
			
			// then compute filter media output flows and associated pollutant loads with ponding area output_managed_flow as input flow
			// filter media allows for runoff infiltration, adsorption of dissolved contaminants and filtration of particulate contaminant
			ask any(filter_media){
				do update_output_flows(any(ponding_area).my_output_managed_flow.my_flow);
				ask agents of_generic_species output_flow where(each.my_component=self){
					do update_output_disspoll_load(myself.function_attributes["my_fql"], self.my_disspoll_load);
					do update_output_partpoll_load(myself.function_attributes["my_fql"], self.my_partpoll_load);
				}
			}
			// then compute how grass, shrubs&plants and trees manage the runoff water from filter media  
		    // grass filters allows for filtration of particulate pollution 
			ask any(grass){
				do update_output_flows(any(filter_media).my_output_managed_flow.my_flow);
				ask agents of_generic_species output_flow where(each.my_component=self){
					do update_output_partpoll_load(myself.function_attributes["my_fql"],self.my_partpoll_load);
				}
			}
			//shrubs & plants allows for more infiltration and uptake of dissolved pollution adsorbed by filter media
			ask any(shrubs_plants){
				do update_output_flows(any(filter_media).my_output_managed_flow.my_flow);
				ask agents of_generic_species output_flow where(each.my_component=self){
					do update_output_disspoll_load(myself.function_attributes["my_fql"], self.my_disspoll_load);
				}
			}
			// trees allows for more infilration and uptake of dissolved pollution adsorbed in filter media
			ask any(trees){
				do update_output_flows(any(filter_media).my_output_managed_flow.my_flow);
				ask agents of_generic_species output_flow where(each.my_component=self){
					do update_output_disspoll_load(myself.function_attributes["my_fql"], self.my_disspoll_load);
				}
			}
			
		   // lastly outlets allows for flow and filters remaining particulate pollution
			ask any(outlet){
				do update_output_flows(any(filter_media).my_output_managed_flow.my_flow);
				ask agents of_generic_species output_flow where(each.my_component=self){
					do update_output_partpoll_load(myself.function_attributes["my_fql"],self.my_partpoll_load);
				}
			}
		}
	
	reflex stop_simulation when: current_date > end_date {
		end_sim<-true;
		do pause;
	}
}

//************************ SPECIES DECLARATION ***************************
species rain {
	managed_flow runoff;
	reflex create_runoff {
			runoff.my_flow <- rnd(0.0);
		
			// small rain events (every week)
			if flip(1/7) {runoff.my_flow <- rnd(0.0,1.0);

			}
			 // moderate rain events
			else if flip(1/365) {runoff.my_flow <- 1.0;
			}
			
			// heavy rain events
			else if flip(1/1825) {runoff.my_flow <- 2.0;
			}
			
			// extreme rain events
			else if flip(1/3650) {runoff.my_flow <- 3.0;
			}
			write (runoff.my_flow);
			runoff.my_disspoll_load <- runoff.my_flow;
			runoff.my_partpoll_load <- runoff.my_flow;
	}
}

/* Declaration of the species NBSS */
species NBSS {
	string my_name;
		aspect default {
		draw NBSS_image_file size: {90, 50, 0.0};
	}
}

/* Declaration of the parent species component */
species component {
	NBSS my_NBSS; //to which NBSS this component belongs	
	string my_name;
//	int my_fqt <- 3; //runoff quantity control function
//	int my_fql <- 3;  //runoff quality control function	
	map <string,int> function_attributes <- ["my_fqt"::3,"my_fql"::3];
	output_flow my_output_managed_flow;
	output_flow my_output_unmanaged_flow;
	rgb my_color;
	list<failure_event> my_failures;
	
	//failure event decreases impacted_attribute value by 1
	action respond_to_failure (failure_event failure) {
		function_attributes[failure.impacted_attribute] <- max(0,function_attributes[failure.impacted_attribute]-1);
		add failure to:my_failures;
	}
	
	//all function attributes of impacted_agent are back to best performance = 3
	action respond_to_maintenance (maintenance_practice maintenance) {
		function_attributes[] <- 3;
		
		//reset failure event frequency with maintenance date
		ask my_failures where (each.failure_name=maintenance.linked_failure_event){
			last_maintenance <- current_date;
		}
		
		// remove failure events that are going to be maintained from the my_failures list
		remove all:(my_failures where (each.failure_name=maintenance.linked_failure_event)) from:my_failures;

		}
		
	
	action update_output_flows (float current_inflow){
		matrix data <- matrix(output_flow_LT_file);
		//loop on the matrix rows (skip the first header line)
	 	loop i from: 0 to: data.rows -1 {
			if (data[0,i] = function_attributes["my_fqt"] and data[1,i] = int(current_inflow)){
				my_output_managed_flow.my_flow <- float(data[2,i]);
				my_output_unmanaged_flow.my_flow <- float(data[3,i]);	
			}
		}
		ask agents of_generic_species output_flow {
			my_disspoll_load <- my_flow;
			my_partpoll_load <- my_flow;
		}
		if (my_name="inlet" or "ponding_area") {
			ask any(urban_environment) {
				do update_overflow(myself.my_output_unmanaged_flow.my_flow);
				
			}
		}
	}

}
/* Declaration of the species inlet which is a child species of component */
species inlet parent: component {
	
	aspect default {
		draw circle(5) border:#black color:my_color  at: {20,20};
		draw "Inlet" color:#black font:font("Helvetica", 12, #bold) at: {17,14};
	}
	
}


/* Declaration of the species ponding_area which is a child species of component */
species ponding_area parent: component {
	bool temporary<-true;
		
	aspect default {
		draw rectangle(30,10) border:#aqua color:my_color  at: {64,23};
		draw "Ponding area" color:#black  font:font("Helvetica", 12, #bold) at: {52,17};
	
	}
	
}

/* Declaration of the species filter_media which is a child species of component */
species filter_media parent: component {
	aspect default {
		draw rectangle(30,5) border:#brown color:my_color  at: {64,47};
		draw "Filter media" color:#black font:font("Helvetica", 12, #bold) at: {52,53};
	}
}

species grass parent: component {
}

species shrubs_plants parent: component {
	
}

species trees parent: component {
	
}

species outlet parent: component {
	
}


species urban_environment {
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
		draw rectangle(30,5) border:#grey color:my_color at: {90,5};
		draw "Urban environment" font:font("Helvetica", 12, #bold) color:#black at: {88,2};
	}
	
}

species output_flow {
	agent my_component;
	float my_flow;
	float my_disspoll_load; // dissolved pollutant load
	float my_partpoll_load; // particulate pollutant load 
	
	action update_output_disspoll_load(int current_fql,float current_poll_load){
		matrix data<-matrix(output_poll_LT_file);
		loop i from: 0 to: data.rows -1 {
			if (data[0,i] = current_fql and data[1,i] = int(current_poll_load)){
				my_disspoll_load <- float(data[2,i]);
			}
		}
	}
	
	action update_output_partpoll_load(int current_fql, float current_poll_load){
		matrix data<-matrix(output_poll_LT_file);
		loop i from: 0 to: data.rows -1 {
			if (data[0,i] = current_fql and data[1,i] = int(current_poll_load)){
				my_partpoll_load <- float(data[2,i]);
			}
		}
	}
	
	
	
}

species managed_flow parent: output_flow {


}

species unmanaged_flow parent: output_flow {
	
}


/* Declaration of species utility which is a parent to :
 * water_utility
 */
species utility {
	
}

species water_utility parent: utility{
	
}

/*Declaration of species failure_event */
species failure_event{
	string failure_name;
	float failure_frequency;
	string impacted_agent;
	string impacted_attribute;
	date last_maintenance <- starting_date;	
	
	// the failure event has a fixed frequency but the frequency is reset every time a maintenance practice is carried out
	reflex trigger_failure{
		loop i from:1 to: int(simulation_duration / #days){
			if current_date = last_maintenance + (i*failure_frequency) {
				// change the performance level of the impacted attribute of the impacted agent
				ask all_components where(each.my_name=impacted_agent) {
					do respond_to_failure (myself);
					string en<-myself.failure_name;
					write (en);
					if en="trash_accumulation" {nb_trash<-nb_trash+1;}
					if en="sediment_accumulation" {nb_sediment<-nb_sediment+1;}

					//export a .csv of all events instead of a having a table
					ask event_table where (each.grid_y=mod(current_event_number,10)+1) {
						if grid_x=0{my_text<-string (current_event_number+1);}
						if grid_x=1{my_text<-en;}
					}
					current_event_number<-current_event_number+1;
				}			
			}
		}
	}
	
}

/* Declaration of species maintenance_practice */
species maintenance_practice {
	string practice_name;
	string practice_scope;
	int practice_level;
	float maintenance_frequency;
	string impacted_agent;
	string linked_failure_event;
	
	reflex trigger_maintenance when: every(maintenance_frequency){
		// if the maintenance practice's scope is specific, find the impacted_agent
		if (practice_scope = "specific"){
				ask all_components where(each.my_name=impacted_agent) {
					do respond_to_maintenance(myself);
					//write (myself.practice_name);
				}
		}
		// if the maintenance practice's scope is general, find all the components impacted by linked_failure_event = find all components whose failure name in the list my failures = linked_failure_event of maintenance practice-> ASK FRANCK
		else if (practice_scope = "general") {
			ask all_components {
				ask my_failures where (each.failure_name=myself.linked_failure_event){
					do respond_to_maintenance(myself);
					}
				}				
		}	
	}

	reflex trigger_maintenance when: every(maintenance_frequency){
		ask all_components {
			do respond_to_maintenance(myself);
			//write (myself.practice_name);
		}

	}
}


grid event_table  width:7 height:10 {
	string my_text;
	rgb my_color;
	font typo <- font("Helvetica", 12, #plain);
	init {
		if grid_y=0 {my_color<-#lightblue;
			if grid_x=0 {my_text<-"Event n°";}
			if grid_x=1 {my_text<-"Day";}
			if grid_x=2 {my_text<-"Runoff value";}
			if grid_x=3 {my_text<-"Inlet condition";}
			if grid_x=4 {my_text<-"Ponding area condition";}
			if grid_x=5 {my_text<-"Filter media condition";}
			if grid_x=6 {my_text<-"Urban environment";}
		} else {my_color<-#white;}
	
	
	
	}
	
	aspect default {
		draw shape border:#black color:my_color;
		draw my_text color:#black font:typo anchor: {0.2, 0.2} at:location - {5,0};
	}
		
}

//******************** EXPERIMENT  *****************************************
	
	
experiment "tests" type: batch repeat:10 until:end_sim{
	
}	

experiment "Interface" type: gui {
	output {
//		display main {
//			species inlet;
//			species ponding_area;
//			species filter_media; 
//			species grass;
//			species shrubs_plants;
//			species trees;
//			species outlet;
//			species urban_environment;
//		}
		display "Rain events" type: 2d {
			chart "Rain events" type: series y_label: "level" y_range: {0,3} y_tick_unit:1 {
				data "Runoff" value:rain collect(each.runoff.my_flow) color:#gamablue line_visible:false style: dot ;
				}
		
		}
		display "Runoff quantity control" type: 2d {
			chart "Runoff quantity control" type: series y_label: "level" y_range: {0,3} y_tick_unit:1 {
				data "Inlet" value:inlet collect (each.function_attributes["my_fqt"])color: #grey marker_shape: marker_down_triangle;
				data "Ponding area" value:ponding_area collect (each.function_attributes["my_fqt"]) color: #deepskyblue marker_shape: marker_circle;
				data "Filter media" value:filter_media collect (each.function_attributes["my_fqt"]) color: #darkgoldenrod marker_shape: marker_diamond;
				data "Grass" value:grass collect (each.function_attributes["my_fqt"]) color: #limegreen marker_shape: marker_square;
				data "Shrubs&Plants" value:shrubs_plants collect (each.function_attributes["my_fqt"]) color: #gamagreen marker_shape: marker_square;
				data "Trees" value:trees collect (each.function_attributes["my_fqt"]) color: #darkgreen marker_shape: marker_square;
				data "Outlet" value:outlet collect (each.function_attributes["my_fqt"]) color:#black marker_shape: marker_up_triangle;
			}
		}
	    display "Runoff quality control" type: 2d {
			chart "Runoff quality control" type: series y_label: "level" y_range: {0,3} y_tick_unit:1 {
				data "Inlet" value:inlet collect (each.function_attributes["my_fql"])color: #grey marker_shape: marker_down_triangle;
				data "Ponding area" value:ponding_area collect (each.function_attributes["my_fql"]) color: #deepskyblue marker_shape: marker_circle;
				data "Filter media" value:filter_media collect (each.function_attributes["my_fql"]) color: #darkgoldenrod marker_shape: marker_diamond;
				data "Grass" value:grass collect (each.function_attributes["my_fql"]) color: #limegreen marker_shape: marker_square;
				data "Shrubs&Plants" value:shrubs_plants collect (each.function_attributes["my_fql"]) color: #gamagreen marker_shape: marker_square;
				data "Trees" value:trees collect (each.function_attributes["my_fql"]) color: #darkgreen marker_shape: marker_square;
				data "Outlet" value:outlet collect (each.function_attributes["my_fql"]) color:#black marker_shape: marker_up_triangle;
			}
		}
		
	}
}







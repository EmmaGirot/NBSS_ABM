/**
* Name: NBSSAM
* Based on the internal empty template. 
* Author: egirot
* Tags: 
* 
* v2.2 evolutions : 
* - New experiment 'tests' that runs a batch of experiments for statistical analysis
* - New gui 'Interface ok' with an image of the NBSS and a schematic of the NBSS with arrows 
*/


model NBSSAM


//******************** GLOBAL *****************************************
global {
	float step <-1 #day; 
	date starting_date <- date([2014, 1, 1, 8, 0, 0]);  // starting date of simulation;
	float simulation_duration <- 10 #years;
	date end_date <- starting_date + simulation_duration;
	list<component> all_components;
	float rain; //pluie en mm
	float runoff;
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

		create NBSS {
			my_name <- "bioretention";
		
		}
		create inlet {
			add self to:all_components;
			my_NBSS<-one_of(NBSS where (each.my_name ="bioretention"));
			// we start the simulation with all performance attributes at an excellent level of performance
			my_name<-"inlet";
			my_condition <- 3;
		}
		
		create temporary_ponding_area {
			add self to:all_components;
			my_NBSS<-one_of(NBSS where (each.my_name ="bioretention"));
			// we start the simulation with all performance attributes at an excellent level of performance
			my_name<-"temporary_ponding_area";
			my_condition <- 3;
		
		}	
		
		create filter_media {
			add self to:all_components;
			my_NBSS<-one_of(NBSS where (each.my_name ="bioretention"));
			// we start the simulation with all performance attributes at an excellent level of performance
			my_name<-"filter_media";
			my_condition <- 1;	
		}	
		
		create vegetation {
			add self to:all_components;
			my_NBSS<-one_of(NBSS where (each.my_name="bioretention"));
			my_name <- "vegetation";
			my_condition <- 4;
		}
		
		create urban_environment {
			
		}
		// The csv file containes lines of failure events and their attributes.
		// Here I am creating as many failure events agent as there are lines in the CSV file. 
		create failure_event from:csv_file( "../includes/failures.csv",';',true) with:
			[event_name::string(get("failure_name")), 
				event_frequency::float(get("failure_frequency_weeks"))#week, 
				impacted_agent::string(get("impacted_agent"))
			];
			
		// The maintenance_practices.csv file containes lines of maintenance practices and their attributes.
		// Here I am creating as many maintenance practice agent as there are lines in the CSV file. 
//		create maintenance_practice from:csv_file( "../includes/maintenance_practices.csv",';',true) with:
//			[practice_name::string(get("practice_name")), 
//				maintenance_frequency::float(get("practice_frequency_weeks"))#week, 
//				impacted_agent::string(get("impacted_agent")),
//				linked_failure_event::string(get("linked_failure_event"))
//			];	
		
	}	


	reflex go{
		
			// create rain events that lead to runoff
			
//			rain<-0.0;
//			if flip(1/3) 
//			{rain<-abs(gauss(0,2.5));
//				write rain;
//			} //pluie en mm
//			
//			runoff <- 0;
//			if rain>0 and rain<=1 {runoff <- 1;}
//			if rain>1 and rain<=5 {runoff <- 2;}
//			if rain>5 {runoff <- 3;}
//			
			
			// create "runoff" events
			runoff <- 0.0;
			
			// small rain events (every week)
			if flip(1/7) {runoff <- rnd(0.0,1.0);
			}
			 // moderate rain events
			else if flip(1/365) {runoff <- 1.0;}
			
			// heavy rain events
			else if flip(1/1825) {runoff <- 2.0;}
			
			// extreme rain events
			else if flip(1/3650) {runoff <- 3.0;}

			// first, compute inlet output flow and associated pollutant loads with runoff as input flow
			ask any(inlet){ 
				do update_output_flows(my_condition,runoff);
				// do update_output_pollutant_loads(my_condition, runoff);
			}
	
			// then compute temporary ponding area output flows and associated pollutant loads with inlet output_managed_flow as input flow
			ask any(temporary_ponding_area) {		
				do update_output_flows(my_condition, any(inlet).my_output_managed_flow);
				do update_output_partpoll_load(my_condition, any(temporary_ponding_area).my_output_managed_flow);
			}
			
			// then compute filter media output flows and associated pollutant loads with tpa output_managed_flow as input flow
			ask any(filter_media){
				do update_output_flows(my_condition, any(temporary_ponding_area).my_output_managed_flow);
				do update_output_disspoll_load(my_condition, any(filter_media).my_output_managed_flow);
			}
			
			// then compute again temporary ponding area output flow and associated pollutant loads with filter media output_unmanaged_flow as input flow
			ask any(temporary_ponding_area){
				do update_output_flows(my_condition, any(filter_media).my_output_unmanaged_flow);
				do update_output_partpoll_load(my_condition, any(temporary_ponding_area).my_output_managed_flow);
			}
			
			/*then compute how the vegetation evaporates the managed water from filter media and 
		    how it removes dissoved pollutants from filter media and particulate pollutants from temporary ponding area*/
			ask any(vegetation){
				do update_output_flows(my_condition, any(filter_media).my_output_managed_flow);
				do update_output_partpoll_load(my_density, any(temporary_ponding_area).my_output_managed_flow);
				do update_output_disspoll_load(my_condition, any(filter_media).my_output_managed_flow);
			}
		}
	
	reflex stop_simulation when: current_date > end_date {
		end_sim<-true;
		do pause;
	}
}

//************************ SPECIES DECLARATION ***************************

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
	int my_condition; 
	float my_output_managed_flow;
	float my_output_unmanaged_flow;
	float my_output_pp_load;
	float my_output_dp_load;
	rgb my_color;
	rgb my_output_managed_flow_color<-#dodgerblue;
	rgb my_output_unmanaged_flow_color<-#crimson;
	int my_output_managed_flow_size<-4;
	int my_output_unmanaged_flow_size<-4;
	rgb runoff_color<-#dodgerblue; 
	int runoff_size<-4;
	
	
	
	list<failure_event> my_failures;
	reflex update_color {
		// the color corresponds to the value of the condition
		my_color<-condition_color[my_condition];	
	}
	
	reflex update_flow_color {
		runoff_size<-runoff+1;
		my_output_unmanaged_flow_size<-my_output_unmanaged_flow+1;
		my_output_managed_flow_size<-my_output_managed_flow+1;
		//runoff_size
	}
	
	
	action respond_to_failure (failure_event failure) {
		my_condition <- max(0,my_condition-1);
		add failure to:my_failures;
	}
	
	action respond_to_maintenance (maintenance_practice maintenance) {
		// determine how many failure events are impacted by maintenance practice
		int nb_failures <- my_failures count (each.event_name=maintenance.linked_failure_event);
		write "there has been " +(nb_failures) + " " +(maintenance.linked_failure_event);
		
		//reset failure event frequency with maintenance date
		ask my_failures where (each.event_name=maintenance.linked_failure_event){
			last_maintenance <- current_date;
		}
		
		// remove failure events that have been maintained from the my_failures list
		remove all:(my_failures where (each.event_name=maintenance.linked_failure_event)) from:my_failures;
		write "remaining failure events are : " + (my_failures collect each.event_name);
		
		// improve condition value 
		my_condition<- min(my_condition+nb_failures,4);			
	}
	
	action update_output_flows (int current_condition, float current_inflow){
		matrix data <- matrix(output_flow_LT_file);
		//loop on the matrix rows (skip the first header line)
	 	loop i from: 0 to: data.rows -1 {
			if (data[0,i] = current_condition and data[1,i] = current_inflow){
				my_output_managed_flow <- float(data[2,i]);
				write(my_name + my_output_managed_flow);		
				my_output_unmanaged_flow <- float(data[3,i]);	
			}
		}
		if (my_name="inlet" or "temporary_ponding_area") {
			ask any(urban_environment) {
				do update_overflow(myself.my_output_unmanaged_flow);
				
			}
		}
	}
	
	action update_output_disspoll_load(int current_condition, float current_poll_load){
		matrix data<-matrix(output_poll_LT_file);
		loop i from: 0 to: data.rows -1 {
			if (data[0,i] = current_condition and data[1,i] = current_poll_load){
				my_output_dp_load <- float(data[2,i]);
			}
		}
	}
	
	action update_output_partpoll_load(int current_condition, float current_poll_load){
		matrix data<-matrix(output_poll_LT_file);
		loop i from: 0 to: data.rows -1 {
			if (data[0,i] = current_condition and data[1,i] = current_poll_load){
				my_output_pp_load <- float(data[2,i]);
			}
		}
	}
	
	
}

/* Declaration of the species inlet which is a child species of component */
species inlet parent: component {
	
	aspect default {
		draw circle(5) border:#black color:my_color  at: {20,20};
		draw "Inlet" color:#black font:font("Helvetica", 12, #bold) at: {17,14};
		
		if static_arrows=true {
		draw rectangle(15,4)  color:runoff_color at: {3,20};
		draw triangle(6)  color:runoff_color rotate:90 at: {12,20};
		draw rectangle(15,4)  color:my_output_managed_flow_color at: {35,22};
		draw triangle(6)  color:my_output_managed_flow_color rotate:90 at: {44,22};
		draw rectangle(4,14)  color:my_output_unmanaged_flow_color  at: {28,10};
		draw rectangle(30,4)  color:my_output_unmanaged_flow_color at: {45,5};
		draw triangle(6)  color:my_output_unmanaged_flow_color rotate:90 at: {61,5};
	
		}
		else {
		//runoff
		if runoff >0 {
		draw rectangle(15,runoff_size)  color:runoff_color at: {3,20};
		draw triangle(runoff_size+2)  color:runoff_color rotate:90 at: {12,20};
		}
		
		//my_output_managed_flow
		if my_output_managed_flow >0 {
		draw rectangle(15,my_output_managed_flow_size)  color:my_output_managed_flow_color at: {35,22};
		draw triangle(my_output_managed_flow_size+2)  color:my_output_managed_flow_color rotate:90 at: {44,22};
		}
		
		//my_output_unmanaged_flow
		if my_output_unmanaged_flow >0 {
		draw rectangle(my_output_unmanaged_flow_size,14)  color:my_output_unmanaged_flow_color  at: {28,10};
		draw rectangle(30,my_output_unmanaged_flow_size)  color:my_output_unmanaged_flow_color at: {45,5};
		draw triangle(my_output_managed_flow_size+2)  color:my_output_unmanaged_flow_color rotate:90 at: {61,5};
		}
		}
	}
	
}


/* Declaration of the species temporary_ponding_area which is a child species of component */
species temporary_ponding_area parent: component {

		
	aspect default {
		draw rectangle(30,10) border:#aqua color:my_color  at: {64,23};
		draw "Temporary ponding area" color:#black  font:font("Helvetica", 12, #bold) at: {52,17};
		
		
			if static_arrows=true {
		draw rectangle(4,10)  color:my_output_managed_flow_color at: {57,34};
		draw triangle(6)  color:my_output_managed_flow_color rotate:180 at: {57,40};
		draw rectangle(10,4)  color:my_output_unmanaged_flow_color  at: {85,25};
		draw rectangle(4,14)  color:my_output_unmanaged_flow_color at: {90,20};
		draw triangle(6)  color:my_output_unmanaged_flow_color  at: {90,12};
		}
		else {
		
		
		//my_output_managed_flow
		if my_output_managed_flow >0 {
		draw rectangle(my_output_managed_flow_size,10)  color:my_output_managed_flow_color at: {57,34};
		draw triangle(my_output_managed_flow_size+2)  color:my_output_managed_flow_color rotate:180 at: {57,40};
		}
		
		//my_output_unmanaged_flow
		if my_output_unmanaged_flow >0 {
		draw rectangle(10,my_output_unmanaged_flow_size)  color:my_output_unmanaged_flow_color  at: {85,25};
		draw rectangle(my_output_unmanaged_flow_size,14)  color:my_output_unmanaged_flow_color at: {90,20};
		draw triangle(my_output_unmanaged_flow_size+2)  color:my_output_unmanaged_flow_color  at: {90,12};
		}
	}
	
	}
	
}

/* Declaration of the species permanent_ponding_area */
//species permanent_ponding_area parent: component {
//	aspect default {
//		draw rectangle(30,10) border:#aqua color:my_color  at: {50,25};
//		draw "Permanent ponding area" color:#black at: {37,25};
//	}
//}

/* Declaration of the species filter_media which is a child species of component */
species filter_media parent: component {
	aspect default {
		draw rectangle(30,5) border:#brown color:my_color  at: {64,47};
		draw "Filter media" color:#black font:font("Helvetica", 12, #bold) at: {52,53};
		
		if static_arrows=true {
		draw rectangle(4,10)  color:my_output_managed_flow_color at: {57,59};
		draw triangle(6)  color:my_output_managed_flow_color rotate:180 at: {57,65};
		draw rectangle(4,10)  color:my_output_unmanaged_flow_color at: {72,37};
		draw triangle(6)  color:my_output_unmanaged_flow_color  at: {72,32};
		}
		else {
		
		//my_output_managed_flow
		if my_output_managed_flow >0 {
		draw rectangle(my_output_managed_flow_size,10)  color:my_output_managed_flow_color at: {57,59};
		draw triangle(my_output_managed_flow_size+2)  color:my_output_managed_flow_color rotate:180 at: {57,65};
		}
		
		//my_output_unmanaged_flow
		if my_output_unmanaged_flow >0 {
		draw rectangle(my_output_managed_flow_size,10)  color:my_output_unmanaged_flow_color at: {72,37};
		draw triangle(my_output_managed_flow_size+2)  color:my_output_unmanaged_flow_color  at: {72,32};
		}
		
		}
		
	}
	
}

species vegetation parent: component  {
	int my_density; 
	aspect default {
		draw rectangle(30,5) border:#brown color:my_color  at: {64,10};
		draw "Vegetation" color:#black font:font("Helvetica", 12, #bold) at: {52,7};
		}
	
}


species urban_environment {
	rgb my_color;
	float flow <-0.0;

		reflex update_color {
		// what color should I use for the urban environment since it doesn't have a "condition" ? 
		//my_color<-condition_color[overflow];	
	}
	
	action update_overflow(float input_flow){
		flow <- input_flow;
	}
	
	aspect default {
		draw rectangle(30,5) border:#grey color:my_color at: {90,5};
		draw "Urban environment" font:font("Helvetica", 12, #bold) color:#black at: {88,2};
	}
	
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
	string event_name;
	float event_frequency;
	string impacted_agent;
	date last_maintenance <- starting_date;	
	
	// the failure event has a fixed frequency but the frequency is reset every time a maintenance practice is carried out
	reflex trigger_failure{
		loop i from:1 to: int(simulation_duration / #days){
			if current_date = last_maintenance + (i*event_frequency) {
				// change the performance level of the impacted attribute of the impacted agent
				ask all_components where(each.my_name=impacted_agent) {
					do respond_to_failure (myself);
					string en<-myself.event_name;
					write (en);
					if en="trash_accumulation" {nb_trash<-nb_trash+1;}
					if en="sediment_accumulation" {nb_sediment<-nb_sediment+1;}

					
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
	float maintenance_frequency;
	string impacted_agent;
	string linked_failure_event;
	
	reflex trigger_maintenance when: every(maintenance_frequency){
				ask all_components where(each.my_name=impacted_agent) {
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
	
experiment "gooooo" type: gui {
	output {
		display main {
			species inlet;
			species temporary_ponding_area;
			species filter_media; 
			species vegetation;
			species urban_environment;
		}
	 	display "Hydrological layer performance" type: 2d {
			chart "Hydrological layer performance" type: series {
				data "Runoff" value:runoff color:#deepskyblue;
				data "Inlet output_managed_flow" value:inlet collect(each.my_output_managed_flow) color: #blue ;
				data "Temporary ponding area output_managed_flow" value: temporary_ponding_area collect (each.my_output_managed_flow) color: #deepskyblue;
				data "Filter media output_managed_flow" value: filter_media collect (each.my_output_managed_flow)  color: #darkgoldenrod;
				}
		}
	}
}

experiment "Interface ok" type: gui {
	output {
		display image {
			species NBSS;
		
		}
	
		display main {
			species inlet;
			species temporary_ponding_area;
			species filter_media; 
			species vegetation;
			species urban_environment;
		}
		display "Hydrologic flows" type: 2d {
			chart "Hydrologic flows" type: series {
				//data "Runoff" value:runoff color:#gamablue line_visible:false style: dot ;
				data "Inlet output_managed_flow" value:inlet collect(each.my_output_managed_flow) color: #grey marker_shape: marker_down_triangle ;
				data "Inlet output_unmanaged_flow" value:inlet collect(each.my_output_unmanaged_flow) color: #orange marker_shape: marker_down_triangle ;
				data "Temporary ponding area output_managed_flow" value: temporary_ponding_area collect (each.my_output_managed_flow) color: #deepskyblue marker_shape: marker_up_triangle ;
				data "Temporary ponding area output_unmanaged_flow" value: temporary_ponding_area collect (each.my_output_unmanaged_flow) color: #red marker_shape: marker_up_triangle;
				data "Filter media output_managed_flow" value: filter_media collect (each.my_output_managed_flow)  color: #darkgoldenrod;
				data "Filter media output_managed_flow" value: filter_media collect (each.my_output_unmanaged_flow)  color: #darkgoldenrod;
				data "Overflow to urban environment" value: urban_environment collect (each.flow) color: #blue marker_shape: marker_diamond;
				}
		}
		display "State" type: 2d {
			chart "Components condition state" type: series {
				data "Inlet condition state" value:inlet collect (each.my_condition)color: #grey marker_shape: marker_down_triangle;
				data "Temporary ponding area condition state" value:temporary_ponding_area collect (each.my_condition) color: #deepskyblue marker_shape: marker_up_triangle;
				data "Filter media condition state" value:filter_media collect (each.my_condition) color: #darkgoldenrod marker_shape: marker_square;
			}
		}
//	 	display event {
//		//	species event_table;
//		
//			chart "events" type:histogram
//			{
//				datalist legend:["trash accumulation","sediment accumulation"] 
//					style: bar
//					value:[nb_trash, nb_sediment] 
//					color:[#green,#black,#purple];
//			} 
//		
//		}
	
		
		
	
	}
}







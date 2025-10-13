/**
* Name: NBSSAM
* Based on the internal empty template. 
* Author: egirot
* 
* 
*
* v2 evolution: 
* - Creation of a runoff specie to create rain events that have a score from 0 to 3
* - The specie indicator has been deleted and replaced by the attribute 'condition' for each NBSS specie
* - Creation of 2 new attributes for each NBSS specie : output_managed_flow and output_unmanaged_flow calculated thanks to logic table output_flow_LT
*/



model NBSSAM


//******************** GLOBAL *****************************************
global {
	float step <-1 #day; 
	date starting_date <- date([2022, 1, 2, 14, 0, 0]);  // starting date of simulation;
	float simulation_duration <- 2 #years;
	date end_date <- starting_date + simulation_duration;
	list<component> all_components;
	int runoff;
	map <string,int> level_of_performance <- ["excellent"::3,"good"::2,"moderate"::1,"poor"::0];
	map <int,rgb> condition_color <- [3::#green,2::#yellow,1::#orange,0::#red];
	map <int,rgb> failure_color <- [1::#red,0::#green];
	// csv file that has the logic table which calculates the output flow depending on input and condition values
	file output_LT_file <- csv_file( "../includes/output_flow_LT.csv",';',int);
	//float choose_event_frequency <- 3 #week parameter: true min:0.0 max: 10.0;
	//float choose_maintenance_frequency <- 7 #week parameter: true min:0.0 max: 10.0;
	
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
			runoff <- 0;
			if flip(1/30) {runoff <- 1;}
			else if flip(1/365) {runoff <- 2;}
			else if flip(1/3650) {runoff <- 3;}

			// first, compute inlet output flow with runoff as input flow
			ask any(inlet){ 
				do update_output_flows(my_condition,runoff);
			}
	
			// then compute temporary ponding area output flows with inlet output_managed_flow as input flow
			ask any(temporary_ponding_area) {		
				do update_output_flows(my_condition, any(inlet).my_output_managed_flow);
			}
			
			// then compute filter media output flows with tpa output_managed_flow as input flow
			ask any(filter_media){
				do update_output_flows(my_condition, any(temporary_ponding_area).my_output_managed_flow);
			}
			
			// then compute again temporary ponding area output flow with filter media output_unmanaged_flow as input flow
			ask any(temporary_ponding_area){
				do update_output_flows(my_condition, any(filter_media).my_output_unmanaged_flow);
			}
			
		}
	
	reflex stop_simulation when: current_date > end_date {
		do pause;
	}
}

//************************ SPECIES DECLARATION ***************************

/* Declaration of the species NBSS */
species NBSS {
	string my_name;
}

/* Declaration of the parent species component */
species component {
	NBSS my_NBSS; //to which NBSS this component belongs	
	string my_name;
	int my_condition; 
	int my_output_managed_flow;
	int my_output_unmanaged_flow;
	rgb my_color;
	list<failure_event> my_failures;
	reflex update_color {
		// the color corresponds to the value of the condition
		my_color<-condition_color[my_condition];	
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
	
	action update_output_flows (int current_condition, int current_inflow){
		matrix data <- matrix(output_LT_file);
		//loop on the matrix rows (skip the first header line)
		loop i from: 1 to: data.rows -1 {
			if (data[0,i] = current_condition and data[1,i] = current_inflow){
				my_output_managed_flow <- int(data[2,i]);
				write(my_name + my_output_managed_flow);		
				my_output_unmanaged_flow <- int(data[3,i]);	
			}
		}
		if (my_name="inlet" or "temporary_ponding_area") {
			if my_output_unmanaged_flow <=2 {
			ask any(urban_environment) {
				do update_flooding(myself.my_output_unmanaged_flow);
				}
			}
		}
	}
	
	
}

/* Declaration of the species inlet which is a child species of component */
species inlet parent: component {
	aspect default {
		draw square(10) border:#black color:my_color  at: {10,20};
		draw "Inlet" color:#black at: {7,20};
	}
	
}


/* Declaration of the species temporary_ponding_area which is a child species of component */
species temporary_ponding_area parent: component {
		aspect default {
		draw rectangle(30,10) border:#aqua color:my_color  at: {50,25};
		draw "Temporary ponding area" color:#black at: {40,25};
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
		draw rectangle(30,5) border:#brown color:my_color  at: {50,35};
		draw "Filter media" color:#black at: {45,35};
	}
	
}

species urban_environment {
	rgb my_color;
	int flooding <-0;
		aspect default {
		draw rectangle(30,5) border:#grey color:my_color at: {90,20};
		draw "Urban environment" color:#black at: {70,20};
	}
		reflex update_color {
		// the color corresponds to the value of the condition
		my_color<-failure_color[flooding];	
	}
	
	action update_flooding(int input_flow){
		if input_flow >= 2{
			flooding <- 1;
		}
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
					write (myself.event_name);
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

//******************** EXPERIMENT  *****************************************
	
experiment "gooooo" type: gui {
	output {
		display main {
			species inlet;
			species temporary_ponding_area;
			species filter_media; 
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










/**
* Name: NBSSAM
* Based on the internal empty template. 
* Author: egirot
* 
* 
* v2.1 evolutions : 
* - New gui 'Interface' with a table that shows the condition of each NBSS agent at every runoff event
*/



model NBSSAM

//******************** GLOBAL *****************************************
global {
	float step <-1 #day; 
	date starting_date <- date([2022, 1, 2, 14, 0, 0]);  // starting date of simulation;
	float simulation_duration <- 10 #years;
	date end_date <- starting_date + simulation_duration;
	list<component> all_components;
	int runoff;
	int current_event_number<-0;
	map <int,string> condition_level <- [3::"excellent",2::"good",1::"moderate",0::"poor"];
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
			my_condition <- 3;	
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
		
			// create "runoff" events
			runoff <- 0;
			if flip(1/365) {runoff <- 1;}
			if flip(1/1825) {runoff <- 2;}
			if flip(1/3650) {runoff <- 3;}
		
			

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
			
						// put the runoff events in the display table 
			if runoff!=0 {
				ask event_table where (each.grid_y=current_event_number+1) {
					if grid_x=0{my_text<-string (current_event_number+1);}
					if grid_x=1{my_text<-string(current_date);}
					if grid_x=2{my_text<-string(runoff);}
					if grid_x=3{
						ask any(inlet){myself.my_text<-condition_level[my_condition];}
					}
					if grid_x=4{
						ask any(temporary_ponding_area){myself.my_text<-condition_level[my_condition];}
					}
					if grid_x=5{
						ask any(filter_media){myself.my_text<-condition_level[my_condition];}
					}
					if grid_x=6{
						ask any(urban_environment){myself.my_text<-string(overflow);}
					}
				}
				current_event_number<-current_event_number+1;
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
	// colors of the arrows for managed and unmanaged output flow for each component
	rgb my_output_managed_flow_color<-#dodgerblue;
	rgb my_output_unmanaged_flow_color<-#crimson;
	int my_output_managed_flow_size<-4;
	int my_output_unmanaged_flow_size<-4;
	// color of the runoff ? why is it in the component species?
	rgb runoff_color<-#dodgerblue; 
	int runoff_size<-4;
	
	
	
	list<failure_event> my_failures;
	reflex update_color {
		// the color corresponds to the value of the condition
		my_color<-condition_color[my_condition];	
	}
	
	// what does this do? -> change size of arrows ?
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
		
		//reset failure event frequency with maintenance date
		ask my_failures where (each.event_name=maintenance.linked_failure_event){
			last_maintenance <- current_date;
		}
		
		// remove failure events that have been maintained from the my_failures list
		remove all:(my_failures where (each.event_name=maintenance.linked_failure_event)) from:my_failures;
		
		// improve condition value 
		my_condition<- min(my_condition+nb_failures,4);			
	}
	
		action update_output_flows (int current_condition, int current_inflow){
		matrix data <- matrix(output_LT_file);
		//loop on the matrix rows (skip the first header line)
		loop i from: 0 to: data.rows-1  {
			write (my_name + " condition: " + current_condition);
			if (data[0,i] = current_condition and data[1,i] = current_inflow){
				write("calculating outputs for " + my_name);
				my_output_managed_flow <- int(data[2,i]);
				my_output_unmanaged_flow <- int(data[3,i]);	
			}
		}
		if (my_name="inlet" or "temporary_ponding_area") {
			ask any(urban_environment) {
				do update_overflow(myself.my_output_unmanaged_flow);
				
			}
		}
	}
	


	
}

/* Declaration of the species inlet which is a child species of component */
species inlet parent: component {
	
	aspect default {
		draw circle(5) border:#black color:my_color  at: {20,20};
		draw "Inlet" color:#black font:font("Helvetica", 12, #bold) at: {17,14};
		
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


/* Declaration of the species temporary_ponding_area which is a child species of component */
species temporary_ponding_area parent: component {

		
	aspect default {
		draw rectangle(30,10) border:#aqua color:my_color  at: {64,23};
		draw "Temporary ponding area" color:#black  font:font("Helvetica", 12, #bold) at: {52,17};
		
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

species urban_environment {
	rgb my_color;
	int overflow <-0;

		reflex update_color {
		// the color corresponds to the value of the condition
		my_color<-failure_color[overflow];	
	}
	
	action update_overflow(int input_flow){
		overflow <- input_flow; 
	}
	
	aspect default {
		draw rectangle(30,5) border:#grey color:my_color at: {81,5};
		draw "Urban environment" font:font("Helvetica", 12, #bold) color:#black at: {68,2};
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
					
					// 
//					string en<-myself.event_name;
//					write (en);
//					ask event_table where (each.grid_y=mod(current_event_number,10)+1) {
//						if grid_x=0{my_text<-string (current_event_number+1);}
//						if grid_x=1{my_text<-string(current_date);}
//					}
//					current_event_number<-current_event_number+1;
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


grid event_table  width:7 height:20 {
	string my_text;
	rgb my_color;
	font typo <- font("Helvetica", 12, #plain);
	init {
		if grid_y=0 {my_color<-#lightblue;
			if grid_x=0 {my_text<-"Runoff event n°";}
			if grid_x=1 {my_text<-"Date";}
			if grid_x=2 {my_text<-"Runoff value";}
			if grid_x=3 {my_text<-"Inlet condition";}
			if grid_x=4 {my_text<-"Ponding area condition";}
			if grid_x=5 {my_text<-"Filter media condition";}
			if grid_x=6 {my_text<-"Urban environment [No flooding=0; flooding=1]";}
		} else {my_color<-#white;}
	
	
	
	}
	
	aspect default {
		draw shape border:#black color:my_color;
		draw my_text color:#black font:typo anchor: {0.2, 0.2} at:location - {5,0};
	}
		
	
	
}




//******************** EXPERIMENT  *****************************************
	
experiment "goooooo" type: gui {
	output {
		display main {
			species inlet;
			species temporary_ponding_area;
			species filter_media; 
			species urban_environment;
		}
	 	display "Hydrologic flows" type: 2d {
			chart "Hydrologic flows" type: series {
				data "Runoff" value:runoff color:#gamablue style: dot ;
				data "Inlet output_managed_flow" value:inlet collect(each.my_output_managed_flow) color: #grey marker_shape: marker_down_triangle ;
				data "Inlet output_unmanaged_flow" value:inlet collect(each.my_output_unmanaged_flow) color: #orange marker_shape: marker_down_triangle ;
				data "Temporary ponding area output_managed_flow" value: temporary_ponding_area collect (each.my_output_managed_flow) color: #deepskyblue marker_shape: marker_up_triangle ;
				data "Temporary ponding area output_unmanaged_flow" value: temporary_ponding_area collect (each.my_output_unmanaged_flow) color: #red marker_shape: marker_up_triangle;
				data "Filter media output_managed_flow" value: filter_media collect (each.my_output_managed_flow)  color: #darkgoldenrod;
				data "Filter media output_managed_flow" value: filter_media collect (each.my_output_unmanaged_flow)  color: #darkgoldenrod;
				data "Overflow to urban environment" value: urban_environment collect (each.overflow) color: #blue marker_shape: marker_diamond;
				}
		}
		display "State" type: 2d {
			chart "Components condition state" type: series {
				data "Inlet condition state" value:inlet collect (each.my_condition)color: #grey marker_shape: marker_down_triangle;
				data "Temporary ponding area condition state" value:temporary_ponding_area collect (each.my_condition) color: #deepskyblue marker_shape: marker_up_triangle;
				data "Filter media condition state" value:filter_media collect (each.my_condition) color: #darkgoldenrod marker_shape: marker_square;
			}
		}
	}
}

experiment "Interface" type: gui {
	output {
		display main {
			species inlet;
			species temporary_ponding_area;
			species filter_media; 
			species urban_environment;
		}
	 	display runoff type: 2d {
			chart "Runoff" type: series {
				data "Runoff" value:runoff color:#gamablue;
						}
		}
		display event {
			species event_table;
		}
	}
}








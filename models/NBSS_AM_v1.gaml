/**
* Name: NBSSAM
* Based on the internal empty template. 
* Author: egirot
*/

/* v1 : 
 * - Creation of 5 NBBS species : inlet, outlet, temporary_ponding_area, filter_media and drainage_pipe
 * - Creation of an indicator specie for each NBSS agent
 * - Creation of failure and maintenance practice species from .csv files
 * - Creation of interactions between failure, maintenance practice agent and the NBSS agents
 */


model NBSSAM


//******************** GLOBAL *****************************************
global {
	float step <-1 #day; 
	date starting_date <- date([2022, 1, 2, 14, 0, 0]);  // starting date of simulation;
	float simulation_duration <- 2 #years;
	date end_date <- starting_date + simulation_duration;
	list<component> all_components;
	map <string,float> level_of_performance <- ["excellent"::4,"good"::3,"moderate"::2,"poor"::1];
	map <float,rgb> performance_color <- [3::#green,2::#yellow,1::#orange,0::#red];
	//float choose_event_frequency <- 3 #week parameter: true min:0.0 max: 10.0;
	//float choose_maintenance_frequency <- 7 #week parameter: true min:0.0 max: 10.0;
	
	init {
		create NBSS {
		
		}
		create inlet {
			add self to:all_components;
			my_NBSS<-one_of(NBSS);
			// we start the simulation with all performance attributes at an excellent level of performance
			my_name<-"inlet";
			create indicator {
				my_component<-myself;
				my_name<-"inflow";
				my_status<-"functioning" ;
				value<-4.0;
				date_of_blockage <- end_date;
				add self to:myself.my_indicators;
				
			}				
		}
		
		create outlet {
			add self to:all_components;
			my_NBSS<-one_of(NBSS);
			// we start the simulation with all performance attributes at an excellent level of performance
			my_name<-"outlet";
			create indicator {
				my_component<-myself;
				my_name<-"outflow";
				my_status <- "functioning" ;
				value<-4.0;
				date_of_blockage <- end_date;
				add self to:myself.my_indicators;
				
			}			
		}
		create temporary_ponding_area {
			add self to:all_components;
			my_NBSS<-one_of(NBSS);
			// we start the simulation with all performance attributes at an excellent level of performance
			my_name<-"temporary_ponding_area";
			create indicator {
				my_component<-myself;
				my_name<-"temporary_water_retention";
				my_status<- "functioning";
				value<-4.0;
				date_of_blockage <- end_date;
				add self to:myself.my_indicators;
				
			}		
		}	
		
		create filter_media {
			add self to:all_components;
			my_NBSS<-one_of(NBSS);
			// we start the simulation with all performance attributes at an excellent level of performance
			my_name<-"filter_media";
			create indicator {
				my_component<-myself;
				my_name<-"infiltration";
				my_status <- "functioning";
				value<-4.0;
				add self to:myself.my_indicators;
				
			}		
		}	
		
		create drainage_pipe {
			add self to:all_components;
			my_NBSS<-one_of(NBSS);
			// we start the simulation with all performance attributes at an excellent level of performance
			my_name<-"filter_media";
			create indicator {
				my_component<-myself;
				my_name<-"collection";
				value<-4.0;
				add self to:myself.my_indicators;
				
			}		
		}
		
		// The csv file containes lines of failure events and their attributes.
		// Here I am creating as many failure events agent as there are lines in the CSV file. 
		create failure_event from:csv_file( "../includes/failures.csv",';',true) with:
			[event_name::string(get("failure_name")), 
				event_frequency::float(get("failure_frequency_weeks"))#week, 
				impacted_agent::string(get("impacted_agent")),
				impacted_attribute::string(get("impacted_attribute"))
			];
			
		// The maintenance_practices.csv file containes lines of maintenance practices and their attributes.
		// Here I am creating as many maintenance practice agent as there are lines in the CSV file. 
//		create maintenance_practice from:csv_file( "../includes/maintenance_practices.csv",';',true) with:
//			[practice_name::string(get("practice_name")), 
//				maintenance_frequency::float(get("practice_frequency_weeks"))#week, 
//				impacted_agent::string(get("impacted_agent")),
//				impacted_attribute::string(get("impacted_attribute")), 
//				linked_failure_event::string(get("linked_failure_event"))
//			];	
		
	}	
	
	reflex stop_simulation when: current_date > end_date {
		do pause;
	}
}

//************************ SPECIES DECLARATION ***************************

/* Declaration of the species NBSS that is made of 4 other species : 
 * blue_components, grey_components, brown_components */
species NBSS {

}

//species parent component
species component {
	NBSS my_NBSS; //to which NBSS this component belongs	
	list<indicator> my_indicators; 
	string my_name;
	rgb my_color;
	list<failure_event> my_failures;
	
	reflex update_color {
		// the color corresponds to the worst level of performance between all the indicators
		my_color<-performance_color[my_indicators min_of(each.value)];	
	}
	
	action respond_to_failure (string name_of_attribute, failure_event failure) {
		ask indicator where (each.my_name=name_of_attribute and each.my_component=self){
			value<-max(1,value-1);		
		}
		add failure to:my_failures;
	}
	
	action respond_to_maintenance (string name_of_attribute, maintenance_practice maintenance) {
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
		
		// improve indicator value 
		ask my_indicators where (each.my_name=name_of_attribute and each.my_component=self){
			value<-min(value+nb_failures,4);			
		}
	}
}


species indicator {
	string my_name;
	string my_status <- "functioning" among: ["functioning","blocked"];
	date date_of_blockage <- end_date;
	component my_component;
	float value;
	
	
	reflex total_blockage when: value=1.0 {
		if my_status = "functioning" {
			my_status<-"blocked";
			date_of_blockage <- current_date; 
			write (my_name + date_of_blockage);
		}
	}	
	
}



/* Declaration of the species inlet */
species inlet parent: component {
	aspect default {
		draw square(10) border:#black color:my_color  at: {10,20};
		draw "Inlet" color:#black at: {7,20};
	}
	
}


/* Declaration of the species outlet */
species outlet parent: component {
	aspect default {
		draw square(10) border:#black color:my_color at: {90,30};
		draw "Outlet" color:#black at: {87,30};
	}

}

/* Declaration of the species temporary_ponding_area */
species temporary_ponding_area parent: component {
		aspect default {
		draw rectangle(30,10) border:#aqua color:my_color  at: {50,25};
		draw "Temporary ponding area" color:#black at: {40,25};
	}
	
	reflex failure_mode when: current_date = any(indicator where(each.my_name="inflow")).date_of_blockage add_days 2 {
		ask indicator where (each.my_name="temporary_water_retention"){
			value<-1.0; 
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

species filter_media parent: component {
	date date_blocked_filter_media <- end_date;
	aspect default {
		draw rectangle(30,5) border:#brown color:my_color  at: {50,35};
		draw "Filter media" color:#black at: {45,35};
	}
	
	reflex chain_reaction when: current_date = date_blocked_filter_media add_days 10 {
		
	}
}

species drainage_pipe parent: component {
	date date_blocked_filter_media <- end_date;
	aspect default {
		draw rectangle(30,5) border:#grey color:my_color  at: {50,42};
		draw "Drainage pipe" color:#black at: {45,42};
	}
	
	reflex chain_reaction when: current_date = date_blocked_filter_media add_days 2 {
		
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
	string impacted_attribute;
	date last_maintenance <- starting_date;	
	
	// the failure event has a fixed frequency but the frequency is reset every time a maintenance practice is carried out
	reflex trigger_failure{
		loop i from:1 to: int(simulation_duration / #days){
			if current_date = last_maintenance + (i*event_frequency) {
				// change the performance level of the impacted attribute of the impacted agent
				ask all_components where(each.my_name=impacted_agent) {
					do respond_to_failure (myself.impacted_attribute, myself);
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
	string impacted_attribute;
	string linked_failure_event;
	
	reflex trigger_maintenance when: every(maintenance_frequency){
				ask all_components where(each.my_name=impacted_agent) {
					do respond_to_maintenance(myself.impacted_attribute, myself);
					write (myself.practice_name);
				}
	}
}	
	

//******************** EXPERIMENT  *****************************************
	
experiment "gooooo" type: gui {
	output {
		display main {
			species inlet;
			species outlet;
			species temporary_ponding_area;
			species filter_media; 
			species drainage_pipe;
		}
	 	display "Hydrological layer performance" type: 2d {
			chart "Hydrological layer performance" type: series {
				data "Inflow performance" value:indicator where(each.my_name="inflow") collect(each.value) color: #blue ;
				data "Temporary water retention performance" value: indicator where (each.my_name="temporary_water_retention") collect(each.value) color: #deepskyblue;
				data "Filter media infiltration performance" value: indicator where (each.my_name="filter_media_infiltration") collect(each.value) color: #darkgoldenrod;
				}
		}
//		display "Outlet performance" type: 2d {	
//			chart "Outlet performance" type: series {
//				data "Outflow performance" value:indicator where(each.my_name="outflow") collect(each.value) color: #blue ;
//				}
//		}
	}
}










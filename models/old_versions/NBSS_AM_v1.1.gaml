/**
* Name: NBSSAM
* Based on the internal empty template. 
* Author: egirot
* 

* V1.1 evolutions:
* - New parent specie called component 
* - New rules to manage failure/maintenance using the new structure of components and my_name attributes
* - Some correction/addition in vizualization
*/



model NBSSAM

//******************** GLOBAL *****************************************
global {
	float step <-1 #week; 
	date starting_date <- date([2022, 1, 2, 14, 0, 0]);  // starting date of simulation;
	float simulation_duration <- 2 #years;
	//float inflow_performance_value;
	list<component> all_components;
	date last_maintenance_date <- starting_date;
	map <string,float> level_of_performance <- ["excellent"::3,"good"::2,"moderate"::1,"poor"::0];
	map <float,rgb> performance_color <- [3::#green,2::#yellow,1::#orange,0::#red];
	//float choose_event_frequency <- 3 #week parameter: true min:0.0 max: 10.0;
	//float choose_maintenance_frequency <- 7 #week parameter: true min:0.0 max: 10.0;
	
	init {
	//	create grey_components;
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
				value<-3.0;
				add self to:myself.my_indicators;
				
			}
			create indicator {
				my_component<-myself;
				my_name<-"macropollutant_filtration";
				value<-3.0;
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
				value<-3.0;
				add self to:myself.my_indicators;
				
			}
			create indicator {
				my_component<-myself;
				my_name<-"pollutant_filtration";
				value<-3.0;
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
		create maintenance_practice from:csv_file( "../includes/maintenance_practices.csv",';',true) with:
			[practice_name::string(get("practice_name")), 
				maintenance_frequency::float(get("practice_frequency_weeks"))#week, 
				impacted_agent::string(get("impacted_agent")),
				impacted_attribute::string(get("impacted_attribute"))
			];	
		
	}	
	
	reflex stop_simulation when: current_date > starting_date + simulation_duration {
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

reflex update_color {
my_color<-performance_color[my_indicators min_of(each.value)];	
}
	action respond_to_failure (string name_of_attribute) {
		ask indicator where (each.my_name=name_of_attribute and each.my_component=self){
			value<-max(0,value-1);		
		}
	}
	
	action respond_to_maintenance (string name_of_attribute) {
		ask indicator where (each.my_name=name_of_attribute and each.my_component=self){
			value<-3.0;			
		}
	}
}


species indicator {
	string my_name;
	component my_component;
	float value;
}



/* Declaration of the species inlet */
species inlet parent: component {
	aspect default {
		draw square(10) border:#aqua color:my_color  at: {20,20,0};
		draw "Inlet" color:#black at: {17,20,0};
	}
}



/* Declaration of the species outlet */
species outlet parent: component {
	aspect default {
		draw square(10) border:#darkblue color:my_color at: {80,10,0};
		draw "outlet" color:#black at: {77,10,0};
	}
}



/* 

/* Declaration of the species blue_components which is a parent to :
 * temporary_ponding_area and permanent_ponding area */
species blue_components{
	map <string,float> TSS_settlement_map <- ["excellent"::3,"good"::2,"moderate"::1,"poor"::0];
	float TSS_settelement_performance;
	
}

/* Declaration of the species temporary_ponding_area */
species temporary_ponding_area parent: blue_components {
	
}

/* Declaration of the species permanent_ponding_area */
species permanent_ponding_area parent: blue_components {
	
}

/* Declaration of the species grey_components which is a parent to : */
species grey_components{
	
}

/* Declaration of the species inlet */
/*species inlet parent: grey_components {
	float inflow;
	float macropollutant_filtration;

	action respond_to_failure (string name_of_attribute) {
		if name_of_attribute = "inflow"{
			inflow <- inflow -1 ;
		}
		if name_of_attribute = "macropollutant_filtration" {
		 macropollutant_filtration <- macropollutant_filtration -1 ;
		}
	}
	action respond_to_maintenance (string name_of_attribute) {
		if name_of_attribute = "inflow"{
			inflow <- level_of_performance["excellent"] ;
		}
		if name_of_attribute = "macropollutant_filtration" {
 			macropollutant_filtration <- level_of_performance["excellent"]  ;
		}
	}
	aspect default {
		draw square(10) color: performance_color[inflow] at: {2,2};
	}
}*/

/* Declaration of the species outlet */
/*
species outlet parent: grey_components {
	float outflow;
	float pollutant_filtration;
	
	action respond_to_failure (string name_of_attribute) {
		if name_of_attribute = "outflow"{
			outflow <- outflow -1 ;
		}
		if name_of_attribute = "pollutant_filtration" {
	 		pollutant_filtration <- pollutant_filtration -1 ;
		}
	}
	
	action respond_to_maintenance (string name_of_attribute) {
		if name_of_attribute = "outflow"{
			outflow <- level_of_performance["excellent"] ;
		}
		if name_of_attribute = "pollutant_filtration" {
 			pollutant_filtration <- level_of_performance["excellent"]  ;
		}
	}
	aspect default {
		draw square(10) color: performance_color[outflow] at: {80,10};
	}
} */


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
	// ia stands for impacted_agent
	
	
	// the failure event has a fixed frequency but the frequency is reset every time a maintenance practice is carried out
	reflex trigger_failure{
		loop i from:1 to: int(simulation_duration / #weeks){
			if current_date = last_maintenance_date + (i*event_frequency) {
				// change the performance level of the impacted agent ia
				
// list of agent that can be impacted (pour commencer): inlet, outlet, temporary_ponding_area, permanent_ponding_area, soil 
				ask all_components where(each.my_name=impacted_agent) {
					do respond_to_failure (myself.impacted_attribute);
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
	//inlet impacted_inlet;
	
	
	reflex update_performance_level when: every(maintenance_frequency){
				ask all_components where(each.my_name=impacted_agent) {
					do respond_to_maintenance(myself.impacted_attribute);
				}
			
		last_maintenance_date <- current_date;
	}
}	
	
	

//******************** EXPERIMENT  *****************************************
	
experiment "gooooo" type: gui {
	output {
		display main {
			species inlet;
			species outlet;
		}
	 	display "Inlet performance" type: 2d {
			chart "Inlet performance" type: series {
				data "Inflow performance" value:indicator where(each.my_name="inflow") collect(each.value) color: #blue ;
			//	data "Macropollutant filtration performance" value: inlet collect(each.macropollutant_filtration) color: #red;
				}
		}		
		display "Outlet performance" type: 2d {	
			chart "Outlet performance" type: series {
				data "Outflow performance" value:indicator where(each.my_name="outflow") collect(each.value) color: #blue ;
		//		data "Outflow performance" value: outlet collect(each.outflow) color: #blue;
		//		data "Pollutant filtration performance" value: outlet collect(each.pollutant_filtration) color: #red;
				}
		}
	}
}











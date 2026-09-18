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
 * maintenance_programmed.csv
 * 	in the climate folder : 
 * climate_spei.csv
 * weather_input_gama.csv
 * weather_input_gama_with_intensity.csv
 * 	in the failures folder : 
 * ext_metric_failures.csv
 * ext_time_failures.csv
*	in the maintenance_practices folder
 * MP_pos_impact.csv
 * MP_neg_impact_seasons.csv

 
 * TODO :
 * - call R from GAMA for spei calculation  
 */

model NBSSAM

//******************** GLOBAL *****************************************
global {
	float step <-1 #day;
	//float step1 <- 1.0;
	

	int sum_val1;
	float av_val1;
	int sum_val2;
	float av_val2;
	
	// Loading csv rainfall and spei file
	file weather_file <- csv_file("../includes/climate/weather_input_gama_with_intensity.csv",",");
	matrix weather_data <- matrix(weather_file);
	// Setting simulation timeline
	date starting_date <- date(string(int(weather_data[0,0])));  // starting date of simulation;
	date end_date <- date(string(int(weather_data[0,length(rows_list(weather_data))-1])));
	float simulation_duration <- float((years_between(starting_date,end_date)));

	
	// TODO : create spei_file according to weather_file by calling R from GAMA
	file spei_file <- csv_file("../includes/climate/climate_spei.csv",",");
	matrix spei_data <- matrix(spei_file);
	
	/// Maintenance practices rules
	//Loading data from MP_pos_impact.csv which states what failures the MP responds to 
	file mapping_mp_failure <- csv_file("../includes/maintenance_practices/MP_associated_failure.csv",";");
	matrix mp_failure_map <- matrix(mapping_mp_failure);
	map<string,string> failure_target_seasons ; 

	
	// Defining seasons
	string current_season;
	//int y <- year(current_date);
	date season_end;
	date season_start;
	// first month of every season
	map<string, int> season_month_start <- ["winter"::12, "spring"::3, "summer"::5, "autumn"::9];
	
	//GIS data for swales
	file shape_file_swales <- file("../includes/GIS_2 Swales/2_swales.shp");
	file shape_file_roads <- file("../includes/GIS_2 Swales/roads_context.shp");
	file shape_file_urban <- file("../includes/GIS_2 Swales/urban_context.shp");

	geometry shape <- envelope(shape_file_roads);
	
	list<NBSS> ordered_nbss;

	// Loading csv files that has the logic table which calculates the output flow depending on input and condition values
	file output_flow_LT_file <- csv_file( "../includes/output_flow_LT.csv",';',int);
	bool end_sim<-false;
	bool is_batch<-false;
		
	// maintenance parameters 
	string maintenance_type <- "scheduled";
	int intervention_delay_days <- 10;// parameter:true  min:2 max: 30;
	
	map results <- [];
	
	//performance parameters
	float maintenance_ressources <- 0.0;
	map<date,float> maintenance_level;
	int accepted_flood_days <- 0;
	int flooding_days <- 0;
	int degraded_vegetation_days <- 0; 
	int poor_well_being_days <-0;
	int rainclass1 <- 0;
	int rainclass2 <- 0;
	int rainclass3 <- 0;
	

	// Flooding indicators by NBSS
	int flooding_days_nbss1 <- 0;
	int flooding_days_nbss2 <- 0;
	
	int accepted_flood_days_nbss1 <- 0;
	int accepted_flood_days_nbss2 <- 0;
	
	// System-wide indicators: each date counted only once
	int flooding_days_system <- 0;
	int accepted_flood_days_system <- 0;
	
	list<date> system_flooding_dates <- [];
	list<date> system_accepted_flood_dates <- [];
	

	//Intensity threshold (mm/h)
	float intensity_threshold <- 2.86;

	// connection type between 2 swales
	int connection_config <- 1;
	// 1 = runoff + managed pipe + overflow
	// 2 = managed pipe + overflow
	// 3 = runoff + overflow
	
    matrix<int> flow_combination_matrix <- matrix([
        [0, 1, 2, 3],
        [1, 1, 2, 3],
        [2, 2, 3, 3],
        [3, 3, 3, 3]
    ]);

	
	init {
		
		current_date<-starting_date;


//write current_date;


		// Initialization of Rain agent : 
		create rain {
			create managed_flow{
				my_component<- myself;
				myself.runoff <- self;
			}
		}
		// Initialization of NBSS and all its components :
		/* 	create swale from: shape_file_swales with: [
			swale_id::string(read("id")),
			type_sfn::string(read("Type_SFN")),
			adresse::string(read("Adresse")),
			sfn_valide::string(read("SFN_valide"))
		]
		*/
		
		create urban_area from: shape_file_urban;
		create road from: shape_file_roads;

		create NBSS from: shape_file_swales {
			nbss_id <- index + 1;
			my_name <- "Swale_" + string(nbss_id);
			
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
			create grass {
				my_name <- "grass";
				my_NBSS<- myself;
				myself.my_grass <- self;
			}
			create shrubs {
				my_name <- "shrubs";
				my_NBSS<- myself;
				myself.my_shrubs <- self;
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

	//Upstream NBSS
	ask NBSS where (each.nbss_id = 1) {

	use_local_runoff <- true;
	use_upstream_managed_flow <- false;
	use_upstream_overflow <- false;
	add self to:ordered_nbss;
}

	//Downstream NBSS
	ask NBSS where (each.nbss_id = 2) {

	if connection_config = 1 {
		use_local_runoff <- true;
		use_upstream_managed_flow <- true;
		use_upstream_overflow <- true;
	}
	else if connection_config = 2 {
		use_local_runoff <- false;
		use_upstream_managed_flow <- true;
		use_upstream_overflow <- true;
	}
	else if connection_config = 3 {
		use_local_runoff <- true;
		use_upstream_managed_flow <- false;
		use_upstream_overflow <- true;
	}
	
	add self to:ordered_nbss;
}


//write "NBSS from up to downstream : "+ordered_nbss;

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
				my_autumn_factor::int(get("autumn_factor")),
				impacted_agent::string(get("impacted_agent")),
					impacted_attribute::string(get("impacted_attribute"))
			];
		create ext_metric_failure from:csv_file( "../includes/failures/ext_metric_failures.csv",';',true) with:
				[my_name::string(get("failure_name")), 
				impacted_agent::string(get("impacted_agent")),
				impacted_attribute::string(get("impacted_attribute")),
				my_accumulation_rate::float(get("acc_rate")),
					my_threshold::float(get("threshold"))

			];		
		
		create maintenance {} 
		
		// save all target seasons in paramter maintenance_target_seasons
		loop index_row from:1 to: mp_failure_map.rows -1 {
			if !(mp_failure_map[3,index_row]=nil){
				add mp_failure_map[1,index_row]::mp_failure_map[3,index_row] to: failure_target_seasons;	
				}
		}
		
		// The "scheduled" maintenance refers to a blindly scheduled maintenance plan written in the maintenance_scheduled.csv file
		// For this plan, the model will be creating as many maintenance practice agent as there are lines in the CSV file. 
		if "scheduled" in maintenance_type {
			create scheduled_maintenance from:csv_file( "../includes/maintenance_programmed.csv",';',true) with:
				[practice_name::string(get("practice_name")), 
					maintenance_frequency::float(get("practice_frequency_weeks")), 
					prog_season_dep::bool(get("season_dep")),
					prog_target_season::list<string>(get("target_season")),
					department::string(get("department")),
					cost::float(get("cost_euros_m²")),
					seasonal::bool("false")
				];	
		}
		
	
		
		
	// NBSS1 is upstream and NBSS2 is downstream
NBSS upstream_nbss <- first(NBSS where (each.nbss_id = 1));
NBSS downstream_nbss <- first(NBSS where (each.nbss_id = 2));

ask downstream_nbss {
    my_upstream_NBSS <- upstream_nbss;
}

ask upstream_nbss {
    my_downstream_NBSS <- downstream_nbss;
}
	
	// Temporary diagnostic check
ask NBSS where (each.nbss_id = 2) {
    if my_upstream_NBSS != nil {
    //    write "NBSS2 upstream NBSS id: " + my_upstream_NBSS.nbss_id;
    } else {
   //     write "NBSS2 upstream NBSS id: nil";
    }
}

ask NBSS where (each.nbss_id = 1) {
    if my_downstream_NBSS != nil {
  //      write "NBSS1 downstream NBSS id: " + my_downstream_NBSS.nbss_id;
    } else {
  //      write "NBSS1 downstream NBSS id: nil";
    }
}	
		
		
	}	
	
	
	reflex NBSS_functioning{
			
			ask rain { do create_runoff;}
			
			ask ordered_nbss {
				ask my_inlet {
					do update_output_flows(any(rain).runoff.my_flow);
				}
			ask my_ponding_area {
				do flow_downstream;
			}		

		}
	}
	
	
	
	reflex Compute_flooding_days { 							
		bool fd<-false;
		bool afd<-false;
		
		ask NBSS {
			bool umo1<-false;
			list<component> listco;
			add my_inlet to:listco;
			add my_ponding_area to:listco;
			//compute the flooding days
			ask listco{if my_output_unmanaged_flow.my_flow>0 {umo1<-true; fd<-true;} }
	 			if umo1 {
	 				if (nbss_id = 1) {flooding_days_nbss1 <- flooding_days_nbss1 + 1;}
	 				if (nbss_id = 2) {flooding_days_nbss2 <- flooding_days_nbss2 + 1;
   				 }
  		 	 }
  		 	
	 }
	 if fd {flooding_days_system <-flooding_days_system+1;}
	
	 }

	 	

	  

	
	
	

		
/* 	
reflex debug_2swale_transfer {
	write "---- 2-swale test ----";
	
	write "date: "+current_date;
	
	ask NBSS where (each.nbss_id=2) {
		write "managed outflow from the first NBSS (nbss1) to the second (nbss2) : " + upstream_managed_in;
		write "unmanaged outflow from the first NBSS (nbss1) to the second (nbss2) : " + upstream_overflow_in;
		write "inflow from the runoff for the second NBSS (nbss2) : " + runoff_flow;
		write "total inflow for NBSS2 (runoff and from nbss1) : "+ total_inflow;
	}
	write "********************";
}*/

	//reflex save_results when : (current_date=end_date){
		
		//   save [maintenance_type,
//        intensity_threshold,
 //       maintenance_ressources,
 //       accepted_flood_days,
   //     flooding_days,
    //    degraded_vegetation_days,
     //   poor_well_being_days,
      //  rainclass1,
     //   rainclass2,
     //   rainclass3
   // ]
 //   to: "../results/rainfall_results_scheduled.csv" format:"csv" rewrite: false header: true ;
//		
//	}
		
	reflex stop_simulation when: current_date = end_date and !is_batch{
		end_sim<-true;
		do pause;
	}
}

//************************ SPECIES DECLARATION ***************************



species seasons {
	reflex season_update {
		if (month(current_date)=12) { 
			current_season <- "winter";
			season_start <- date(string(year(current_date))+ "-12-01");
			season_end <-date(string(year(current_date)+1)+ "-03-01") minus_days 1;
		}
		if (month(current_date)<=2){
			current_season <- "winter";
			season_start <- date(string(year(current_date)-1)+ "-12-01");
			season_end <-date(string(year(current_date))+ "-03-01") minus_days 1;
		}
		if (month(current_date)>=3 and month(current_date)<=5){
			current_season<- "spring";
			season_start <- date(string(year(current_date))+ "-03-01");
			season_end <-date(string(year(current_date)) + "-05-31");
		}
		if (month(current_date)>=6 and month(current_date)<=8){
			current_season <- "summer";
			season_start <- date(string(year(current_date))+ "-06-01");
			season_end <-date(string(year(current_date)) + "-08-31");
		}
		if (month(current_date)>=9 and month(current_date)<=11){
			current_season <- "autumn";
			season_start <- date(string(year(current_date))+ "-09-01");
			season_end <-date(string(year(current_date)) + "-11-30");
		}
	}
	
	string get_season(int month) {
	    if (month >= 3 and month < 5) {
	        return "spring";
	    } else if (month >= 5 and month < 9) {
	        return "summer";
	    } else if (month >= 9 and month < 12) {
	        return "autumn";
	    } else {
	        return "winter";
	    }
	}
}
/* Declaration of the rain species */
species rain {
	float rainfall;
	managed_flow runoff;
	date last_rain;
	list<int> runoff_history <- [];

	action create_runoff {
		runoff.my_flow <- 0.0;
		loop i from:0 to:weather_data.rows-1 {
			if current_date = date(string(int(weather_data[0,i]))) {
		
				// Emma's original class 1
				//Rainfall event <= 20mm in a day are considered as a runoff flow of 1
           // if (float(weather_data[1,i]) <= 20.0   and float(weather_data[1,i]) > 5.0) {
               // runoff.my_flow <- 1.0;
              //  rainclass1 <- rainclass1 + 1;
           // }
			
				// Rainfall event between 2 and 15 mm/day: runoff class 1
			//if (float(weather_data[1,i]) <= 15.0 and float(weather_data[1,i]) > 2.0) {
			  //  runoff.my_flow <- 1.0;
			    //rainclass1 <- rainclass1 + 1;
			//}
				//The intensity part
				if (float(weather_data[1,i]) <= 15.0 and float(weather_data[1,i]) > 2.0) {
				    if (float(weather_data[2,i]) >= intensity_threshold) {
				        runoff.my_flow <- 2.0;
				        rainclass2 <- rainclass2 + 1;
				   }
				   else {
				        runoff.my_flow <- 1.0;
				        rainclass1 <- rainclass1 + 1;
				   }
					// Swarna for intensity classes
					//if the intensity of a rain class 1 is higher than the selected intensity threshold (mm/h), than rain is considered class 2
					//if (float(weather_data[2,i]) >= intensity_threshold) {
					//runoff.my_flow <- 2.0;
					//rainclass2 <- rainclass2 + 1;
					//}
					//TODO : for very intense rains -> intensity higher than ....mm/h -> class 3 
//					if (float(weather_data[2,i]) >= ) {
//					runoff.my_flow <- 3.0;
//					}
				}
				//Rainfall event between 20mm and 80mm in a day are considered as a runoff flow of 2
				if (float(weather_data[1,i]) > 15.0 and float(weather_data[1,i]) <= 80.0 ) {
					runoff.my_flow <- 2.0;
					rainclass2 <- rainclass2 + 1;
				}
				//Rainfall event > 80mm in a day are considered as a runoff flow of 3
				if (float(weather_data[1,i]) > 80.0 ) {
					runoff.my_flow <- 3.0;
					rainclass3 <- rainclass3 + 1;
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
	int nbss_id;

	inlet my_inlet; 
	ponding_area my_ponding_area;
	filter_media my_filter_media; 
	outlet my_outlet;
	grass my_grass;
	shrubs my_shrubs;
	trees my_trees;
	list<engineered_component> my_engineered_components;
	list<vegetal_component> my_vegetal_components;
	list<component> my_components;
	rgb my_color<-#yellow;

	bool inspected <- false;
	date inspection_date <- starting_date;

	NBSS my_downstream_NBSS;
	NBSS my_upstream_NBSS;

	
	// these are the parameters that help calculate flow between upstream NBSS and downstream NBSS
	float upstream_managed_in <- 0.0;
	float upstream_overflow_in <- 0.0;
	float total_inflow <- 0.0;
	float runoff_flow <- 0.0;
	bool use_local_runoff <- false;
	bool use_upstream_managed_flow <- false;
	bool use_upstream_overflow <- false;
	
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
	
		
	reflex seasonal_repair when:(month(current_date) in (season_month_start.values) and (day(current_date)=15) and maintenance_type="seasonal") {
		if (!inspected){
			ask any(maintenance){
				do visual_inspection(myself);
				}
			}
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
	
	aspect base {
		draw shape color: my_color border: #red;
		draw my_name at: location color: #red font: font("Arial", 14);
	}

}

species road {
	rgb color <- #black;

	aspect base {
		draw shape color: color width: 0.5;
	}
}

species urban_area {
	rgb color <- rgb(220,220,220);

	aspect base {
		draw shape color: color border: rgb(180,180,180);
	}
}

//***************************************************************************
/* Declaration of the parent species component */
species component {
	NBSS my_NBSS; //to which NBSS this component belongs	
	string my_name;
	flow my_output_managed_flow;
	flow my_output_unmanaged_flow;
	rgb my_color;
	list<failure_event> my_failures ;
	map <string,float> function_attributes;
	component my_upstream_comp;
	component my_downstream_comp;
	list<string> my_impacted_agents;
	bool maintenance_state <- false; // to signal if corrective maintenance is being carried out
	string state; // defines the state of the component to help determine maintenance practice weight

	action flow_downstream {
		do update_output_flows(my_upstream_comp.my_output_managed_flow.my_flow);

		ask my_NBSS.my_engineered_components where(each.my_upstream_comp = self) {
			do flow_downstream;
		}
	}

	action update_output_flows (float current_inflow){
		matrix data <- matrix(output_flow_LT_file);
		
			
	//add the integration of connected NBSS
		// the downstream NBSS collects flow from : 
		// (1) managed outflow of upstream NBSS outlets
		// (2) unmanaged outflows of upstream NBSS inlets and ponding areas
		// (3) direct runoff from rain 
		
		
		// if the component is the inlet of the downstream component 
		if my_NBSS.my_upstream_NBSS != nil and my_upstream_comp = nil {

	
			int local_flow <- 0;
			int upstream_managed_flow <- 0;
			int inlet_overflow <- 0;
			int ponding_overflow <- 0;
			int overflow_flow <- 0;
			int combined_flow <- 0;
	
			// 1. Local runoff
			if my_NBSS.use_local_runoff {
				local_flow <- int(current_inflow);
				my_NBSS.runoff_flow <- local_flow;
			}
	
			// 2. Managed flow from the upstream outlet
			if my_NBSS.use_upstream_managed_flow {
	
	    		if my_NBSS.my_upstream_NBSS.my_outlet != nil {
	        	upstream_managed_flow <- int(my_NBSS.my_upstream_NBSS.my_outlet.my_output_managed_flow.my_flow);
	    		}
	    		else {
	        		upstream_managed_flow <- 0;
		    //    write "WARNING: no outlet found for upstream swale "
		       //     + my_NBSS.my_upstream_NBSS;
		    	}
			}
	
			// 3. Unmanaged flow / overflow from upstream
			if my_NBSS.use_upstream_overflow {
	
		   		if my_NBSS.my_upstream_NBSS.my_inlet != nil {
		        inlet_overflow <- int(my_NBSS.my_upstream_NBSS.my_inlet.my_output_unmanaged_flow.my_flow);
		    	}
			    else {
			        inlet_overflow <- 0;
			    }
		
			    if my_NBSS.my_upstream_NBSS.my_ponding_area != nil {
			        ponding_overflow <- int(my_NBSS.my_upstream_NBSS.my_ponding_area.my_output_unmanaged_flow.my_flow);
			    }
			    else {
			        ponding_overflow <- 0;
			    }
		
		
				// Combine the two overflow sources
				if inlet_overflow = 0 {
					overflow_flow <- ponding_overflow;
				}
				else if ponding_overflow = 0 {
					overflow_flow <- inlet_overflow;
				}
				else {
					overflow_flow <- flow_combination_matrix at {
						inlet_overflow,
						ponding_overflow
					};
				}
			}
	
			// Combine local runoff and managed flow
			if local_flow = 0 {
		    combined_flow <- upstream_managed_flow;
			}
			else if upstream_managed_flow = 0 {
			    combined_flow <- local_flow;
			}
			else {
			    combined_flow <- flow_combination_matrix at {
			        local_flow,
			        upstream_managed_flow
			    };
			}
		
			// Add upstream overflow
			if combined_flow = 0 {
				combined_flow <- overflow_flow;
			}
			else if overflow_flow != 0 {
				combined_flow <- flow_combination_matrix at {
					combined_flow,
					overflow_flow
				};
			}
	
			my_NBSS.upstream_managed_in <- upstream_managed_flow;
			my_NBSS.upstream_overflow_in <- overflow_flow;
			my_NBSS.total_inflow <- combined_flow;
			
			// Use the combined value in the lookup table below
			current_inflow <- combined_flow;
	}
		
		
		//loop on the matrix rows (skip the first header line)
	 	loop i from: 0 to: data.rows -1 {
			if (data[0,i] = int(function_attributes["my_qtf"]) and data[1,i] = int(current_inflow)){
				my_output_managed_flow.my_flow <- float(data[2,i]);
				my_output_unmanaged_flow.my_flow <- float(data[3,i]);	
			}
		}
		
		
		
	}
	
		map<failure_event, float>  failures_to_repair (list<string> functions_to_repair){
		list<failure_event> my_failures_to_repair <-  my_failures where (each.impacted_attribute=any(functions_to_repair));
		map<failure_event, float> different_failures <- [];
		// we want to count how many different failure types there are and sum the impact level of similar failures, 
		loop i over: my_failures_to_repair {
		    failure_event rep <- first(my_failures_to_repair where (each.my_name = i.my_name));
		    different_failures[rep] <- (different_failures[rep] = nil ? 0 : different_failures[rep]) + i.level_of_impact;
		}
		return different_failures;
	}
		
	//critical state is triggered whenener one of the functions of the component is equal to zero, this will lead to corrective maintenance
	reflex corrective_repair_state when: (any(function_attributes.values)=0) and (maintenance_state=false) and (maintenance_type = "corrective"){
		maintenance_state <- true;
		list<string> functions_to_repair;
		if (self is vegetal_component and function_attributes["my_health"]=0){
			 functions_to_repair <- ["my_health"];
		}
		else {
			functions_to_repair <- function_attributes.keys where (function_attributes[each]=0);
		}
		map<failure_event, float> different_failures <- failures_to_repair(functions_to_repair);
		// for corrective maintenance, create a maintenance practice whose impact level will be equal to the number of failure types that have impacted the component
		if length(different_failures)!= 0 {
			loop i over: different_failures.keys {
				loop index_row from:1 to: mp_failure_map.rows -1 {
					if mp_failure_map[1,index_row] = i.my_name { // find the row corresponding to the maintenance practice in the mp_failure map 
						create maintenance  {
							practice_name <- mp_failure_map[0,index_row];	 
							impacted_component <- myself;
							my_NBSS<-impacted_component.my_NBSS;
							impacted_attribute <- i.impacted_attribute;
							impact_level <-  different_failures[i];
							maintenance_trigger_date <- current_date + intervention_delay_days #day;	
							linked_failure_name <-i.my_name ;
							veg_disturbance_factor <-  veg_disturbance_map[mp_failure_map[2,index_row]];
							
							my_target_season <- mp_failure_map[3,index_row];
						}
					}
					
				}
			}
		}
	}
	
	
	//preventive repair state is triggered whenener one of the functions of the component is equal to 1 or less, this will lead to preventive maintenance
	reflex preventive_repair_state when: (any(function_attributes.values)<=1) and (maintenance_state=false) and ("preventive" in maintenance_type){
		maintenance_state <- true;
		list<string> functions_to_repair;
		if (self is vegetal_component and function_attributes["my_health"]<=1){
			 functions_to_repair <- ["my_health"];
		}
		else {
			functions_to_repair <- function_attributes.keys where (function_attributes[each]<=1);
		}
		map<failure_event, float> different_failures <- failures_to_repair(functions_to_repair);
		// for preventive maintenance, create a maintenance practice whose impact level will be equal to the number of failure types that have impacted the component
		if length(different_failures)!= 0 {
			loop i over: different_failures.keys {
				loop index_row from:1 to: mp_failure_map.rows -1 {
					if mp_failure_map[1,index_row] = i.my_name { // find the row corresponding to the maintenance practice in the mp_failure map 
						create maintenance  {
							practice_name <- mp_failure_map[0,index_row];	 
							impacted_component <- myself;
							my_NBSS<-impacted_component.my_NBSS;
							impacted_attribute <- i.impacted_attribute;
							impact_level <-  different_failures[i];
							// 1 day is added for the dynamic of the model DO NOT MODIFY 
							maintenance_trigger_date <- current_date + 1#day;	
							linked_failure_name <-i.my_name ;
							veg_disturbance_factor <-  veg_disturbance_map[mp_failure_map[2,index_row]];
							my_target_season <- mp_failure_map[3,index_row];	
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
	
	
	reflex update_state {
		if (function_attributes["my_qtf"] >= 0 and function_attributes["my_qtf"] <1){
			state <- "low"; 
			}
		if (function_attributes["my_qtf"] >=1 and function_attributes["my_qtf"] <2){
			state <- "medium"; 
			}
		if (function_attributes["my_qtf"] >=2 and function_attributes["my_qtf"] <=3){
			state <- "high"; 
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
		ask any(rain) {
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
	//float partpoll_acc <- 0.0;
	//float partpoll_yearly_dynamic <- 0.3; // sediment accumulation dynamic = 0.3 cm/year (Chabert et al., 2025) 
	bool saturation <- false;
	date sediment_practice <- starting_date + 1 #year;	
	
	//when filter_media is getting clogged (because of sediment accumulation), vegetation health is impacted
	reflex clogged_fm when: (function_attributes["my_qtf"] <=1) and ((length(my_failures where (each.my_name="partpoll_acc")))>=1) and every(1 #month) and flip(0.7){
		ask my_NBSS.my_grass {
			do clogged_fm_on_veg;
		}
		ask my_NBSS.my_shrubs {
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
	
	reflex saturation_solved when:  (my_downstream_comp != nil) and (my_downstream_comp.my_output_unmanaged_flow.my_flow<1) and (saturation=true){
		saturation<-false;
		function_attributes["my_qtf"] <- function_attributes["my_qtf"] +1;
	}
	
	
	//when vegetation is unhealthy, infiltration performance of filter media is impacted
	action unhealthy_veg_on_fm {
		create failure_event {
			my_name <- "unhealthy_veg_on_fm";
			impacted_agent <- myself.my_name;
			impacted_attribute <- "my_qtf";
			last_failure <- current_date;
			do failure_impact(0.25);
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
	map <string,float> function_attributes <- ["my_health"::3 ,"my_biodiversity"::3];
	bool climate_stress <- false; // this shows if the vegetation has suffered a climate stress


	reflex update_state {
		if (function_attributes["my_health"] >= 0 and function_attributes["my_health"] <=1){
			state <- "low"; 
			}
		if (function_attributes["my_health"] >1 and function_attributes["my_health"] <=2){
			state <- "medium"; 
			}
		if (function_attributes["my_health"] >2 and function_attributes["my_health"] <=3){
			state <- "high"; 
			}
	}
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
						if (my_name="grass") {
							do failure_impact(1.0);
						}
						if (my_name="shrubs") {
							do failure_impact(0.5);
						}
						if (my_name="trees") {
							do failure_impact(0.25);
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
						if (my_name="grass") {
							do failure_impact(1.0);
						}
						if (my_name="shurbs") {
							do failure_impact(0.5);
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
	
	// if the vegetation underwent a climate stress at the last spei calculation but is not dead and is not undergoing another failure, it can recover if the following spei calculation is between -1.5 and 1.5 
	action recovering {
		if (climate_stress = true) and (function_attributes["my_health"]!= 0) and (length(my_failures)<=1) {
			function_attributes["my_health"] <- min(3,function_attributes["my_health"] +1);	
			climate_stress <- false;
		}
	}
	
	reflex unhealthy_veg when: (function_attributes["my_health"]<=1) and every(1 #month) {
		ask any(filter_media){
			do unhealthy_veg_on_fm;
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



/***************************************************** GRASS *******************************************/
species grass parent:vegetal_component  {

}

/***************************************************** SHRUBS *******************************************/

species shrubs parent:vegetal_component {
	bool invasive <- false;

	// if invasive_plants impacted shrubs than the "excess_veg" failure trigger frequency in ext_failures will go from every year in spring to once a season (expect for winter)
	reflex invasive_taking_over when: (invasive=true) {
		ask agents of_generic_species ext_time_failure where ("excess_veg" in my_name){
				season_dep <- true;
				my_frequency <- 12.0;
				my_winter_factor<- 0;
				my_spring_factor <-1;
				my_summer_factor <- 1;
				my_autumn_factor<- 1;
		}
		invasive <- false;
	}
}


/***************************************************** TREES *******************************************/

species trees parent: vegetal_component {
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

species flow {
	agent my_component;
	float my_flow;
		
}

/***************************************************** MANAGED OUTPUT FLOW *******************************************/
species managed_flow parent: flow {


}


/***************************************************** UNMANAGED OUTPUT FLOW *******************************************/
species unmanaged_flow parent: flow {
	
}


/***************************************************** FAILURE EVENT *******************************************/
species failure_event{
	string my_name;
	string impacted_agent;
	string impacted_attribute;
	float level_of_impact;
	date last_maintenance <- starting_date;	
	date last_failure <- starting_date;
	date next_failure;
	float time_to_recover;
	
	// impact of a failure event on attributes
	action failure_impact (float impact_level) {
		level_of_impact <- impact_level;
		ask agents of_generic_species component where (each.my_name=impacted_agent){
			function_attributes[myself.impacted_attribute] <- max(0,function_attributes[myself.impacted_attribute]-impact_level);
			myself.last_failure <- current_date;
			add myself to:self.my_failures;
		}
	//	write my_name + " on " + impacted_agent + " on " + string(current_date,"dd MM yyyy");
		
	}
	
	//for maintenance-induced failures : summer_mowing and intensive_management, they are recovered thanks to time
	// the recovery period is set to one month for these failures
	reflex recover when: !(time_to_recover=0) and (current_date = last_failure + time_to_recover #month) {
		ask agents of_generic_species component where (each.my_name=impacted_agent) {
			function_attributes[myself.impacted_attribute] <- min(3,function_attributes[myself.impacted_attribute]+myself.level_of_impact);
		}	
	}
	
	//plant_removal's failure frequency is the same as partpoll_acc
	reflex associate_plant_removal_to_partpoll_acc when: (my_name="plant_removal"){
		ask agent of_generic_species failure_event where (each.my_name="partpoll_acc"){
			myself.next_failure <- next_failure;
		}
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
	int my_autumn_factor;
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
		if (current_season = "autumn") {
			seasonal_factor <- my_autumn_factor;
		}
	}
	
	// set the date for the next failure and trigger it
	reflex update_next_time_failure when: (current_date=next_failure)  {
		// for failures independent of seasons
		if (season_dep=false) {
			do ext_time_trigger();
			//The reference date used to compute the next failure is the most recent between last_maintenance and last_failure
			// a random variation of + or - 2 weeks is added around the my_frequency value
				next_failure <- (last_maintenance > last_failure) ? last_maintenance  + (my_frequency + rnd(5) - 2)*7 # day : last_failure + (my_frequency + rnd(5) - 2)*7 # day;
		}
		
		// for failures dependent of seasons
		if (season_dep=true and seasonal_factor!=0) {
			do ext_time_trigger();
			// if there hasn't been any failure in the season yet, the reference date used to compute the next failure is the most recent between last_maintenance and season_start
			if (last_failure <= season_start){
				next_failure <- (last_maintenance <= season_start ) ? season_start + (my_frequency + rnd(5) - 2)*7 # day : last_failure + (my_frequency + rnd(5) - 2)*7 # day ;

			}
			if (last_failure > season_start){
				next_failure <- (last_maintenance > last_failure) ? last_maintenance  + (my_frequency + rnd(5) - 2)*7 # day : last_failure + (my_frequency + rnd(5) - 2)*7 # day;
			}

		}
		
		// if failure should not be triggered at this season, wait for the start of the next season to trigger next failure
		if (season_dep=true and seasonal_factor=0) {
			next_failure <- season_end +  1#day;	
			
		}
		
	}
		
		
	action ext_time_trigger  {
		NBSS impacted_NBSS;
		ask agents of_generic_species component where (each.my_name=impacted_agent) {
			impacted_NBSS <- my_NBSS;
		}
		// Some failures occur under conditions 
		// excess_veg on inlet if grass or shrub health is >= 2  
		if ("excess_veg" in my_name){
			bool shrub_excess <- false;
			bool grass_excess <- false;
			ask agents of_generic_species vegetal_component where ((each.my_NBSS=impacted_NBSS) and (each.my_name!=trees)) {
				if (function_attributes["my_health"] >= 2) {
					shrub_excess <- true;	
				}
			}	
			ask  agents of_generic_species grass where (each.my_NBSS=impacted_NBSS) {
				if (function_attributes["my_health"] >= 2) {
					grass_excess <- true;
				}
			}
			if (grass_excess or shrub_excess){
				do failure_impact(1.0);	
			}

		}
		// invasive_plants only possible if shrub health is <= 1
		if (my_name="invasive_plants"){
			ask agents of_generic_species shrubs where (each.my_NBSS=impacted_NBSS) {
				if (function_attributes["my_health"] <= 1) {
					invasive<-true;
					ask myself {
						do failure_impact(1.0);
					}
				}
				
			}
			
		}
		else if (my_name!= "invasive_plants" and !("excess_veg" in my_name)){
			do failure_impact(1.0);
		}
	}


 }

/**********************  External failures based on metric values : sediment accumulation on filter media *****************************************/

species ext_metric_failure parent: failure_event {
	float my_value<-0.0; // accumulation value
	float my_accumulation_rate; // accumulation rate
	float my_threshold;  // threshold that leads to failure (=-1)
	date last_accumulation <- starting_date;
	//date next_failure ;//<- current_date + ceil((my_threshold - my_value) / my_accumulation_rate) #year;
	
	init {
		next_failure <- current_date + ceil((my_threshold - my_value) / my_accumulation_rate) #year;
	
	}	
	// TODO: add randomness
	reflex accumulation when: (current_date=last_accumulation + 1#year) {//and (current_date > starting_date){
		my_value <- my_value + my_accumulation_rate;
		last_accumulation <- current_date;		
		}
	
	// this resets the value of the accumulation when a maintenance pratice has been done (action called in maintenance agent)
	action update_accumulation_value (float acc_to_remove){
		my_value <-max(0,my_value - acc_to_remove);
		ask agents of_generic_species component where (each.my_name=impacted_agent){
			if (function_attributes["my_qtf"]!=3){
				function_attributes["my_qtf"]<-min(3,function_attributes["my_qtf"]+(acc_to_remove/myself.my_threshold));
			}
		}
		last_accumulation <- current_date;
		next_failure <- current_date + ceil((my_threshold - my_value) / my_accumulation_rate) #year;	
	}
	
	// set the date for the next metric failure and trigger it
	reflex update_next_metric_failure  when:(current_date=next_failure){
		next_failure <- current_date + ceil((my_threshold - my_value) / my_accumulation_rate) #year;
	    do failure_impact(1.0);
	}
	

}

/***************************************************** MAINTENANCE PRACTICE *******************************************/

species maintenance {
	NBSS my_NBSS<-one_of(NBSS);
	string practice_name;
	string linked_failure_name;
	component impacted_component;
	string impacted_attribute;
	float impact_level; //positive impact of the practice (of how much it improves the value of the attribute)
	map<string,float> practice_intensity <- ["low"::3.0,"medium"::1,"high"::0.5];
	string veg_disturbance_level;
	map<string,float> veg_disturbance_map <- ["null"::0.0,"low"::rnd(1.0,3.0),"medium"::rnd(3.0,6.0),"high"::rnd(12.0,36.0)]; // maintenance practices carried out on veg components have a disturbance factors that delays the recovery process of the veg
	float veg_disturbance_factor <- veg_disturbance_map[veg_disturbance_level]; // float of disturbance level
	string my_target_season; // some maintenance practice have to be carried out at a specific season to not impact negatively the vegetation
	bool seasonal;	
	date maintenance_trigger_date <- starting_date;
	// some maintenance practice' execution is delayed so these two parameters are here to trigger delay
	date execution_start<-starting_date;
	float execution_month_delay ;
	bool reported;
	// this boolean is used for impact of vegetation sediment removal on filter media
	bool veg_impact_done <- false;
		

	reflex seasonal_strategy when: ("seasonal" in maintenance_type) {
		seasonal <- true;
	}
	
	reflex trigger_maintenance when: (current_date = maintenance_trigger_date + 1 #day) and (maintenance_trigger_date !=starting_date) {
		if ("preventive" in maintenance_type and !(impacted_component.my_NBSS.inspected)){
			do visual_inspection(impacted_component.my_NBSS);
		}
		if (impacted_component is vegetal_component){
			execution_month_delay <- check_veg_delay();
		}
		else {
			execution_month_delay <-0.0;
		}
		execution_start <- current_date;
 
	}
	
	// this represents the delayed date at which the vegetation will respond to the maintenance practice
	float check_veg_delay {
		if (impacted_component is vegetal_component){
			// plants will take longer to establish themselves if planted during winter season 
			execution_month_delay <- 1.0 * veg_disturbance_factor;	
			if (current_season="winter" and veg_disturbance_factor < 12.0) {
				execution_month_delay <- 2* execution_month_delay;
			}
		}

		else {execution_month_delay <-0.0;}
		return execution_month_delay;
	}

	// 1 day is added for the dynamic of the model DO NOT MODIFY 
	reflex eng_maintenance_practice when: (current_date=execution_start +1 #day) and (impacted_component is engineered_component) {
		ask impacted_component {
			// performance criteria maintenance_ressources is increased by the impact_level of the maintenance practice weighted by the complexity of the practice
			// if the impacted component is in a very bad state before maintenance than the weight of the practice will be greather than if it is still in an acceptable state
			maintenance_ressources <- maintenance_ressources + (myself.practice_intensity[state]*myself.impact_level);
			function_attributes[myself.impacted_attribute] <- min(3,function_attributes[myself.impacted_attribute]+myself.impact_level);
			
		//	write myself.impacted_attribute +" ; "+ function_attributes[myself.impacted_attribute];
			maintenance_state <- false;	
			if (myself.practice_name = "fm_sediment_removal"){
				ask agents of_generic_species ext_metric_failure where (each.my_name="partpoll_acc"){
					do update_accumulation_value(3.0);
				}
				ask my_NBSS.my_filter_media {
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
		do check_veg_negative_impact();
	//	write practice_name + "done on " + impacted_component.my_name + " on " + current_date;
	}

	reflex veg_maintenance_practice when: every(1#month) and (current_date>execution_start) and (current_date <=(execution_start + execution_month_delay #month)) and (impacted_component is vegetal_component) {
		ask impacted_component {
			// performance criteria maintenance_ressources is increased by the impact_level of the maintenance practice weighted by its weight
			maintenance_ressources <- maintenance_ressources + (myself.practice_intensity[state]*(myself.impact_level/myself.execution_month_delay));
			function_attributes[myself.impacted_attribute] <- min(3,function_attributes[myself.impacted_attribute]+(myself.impact_level/myself.execution_month_delay));
			maintenance_state <- false;
			//veg_sediment_removal has a positive impact on filter media as well
			if ((myself.practice_name = "veg_sediment_removal") and (myself.veg_impact_done = false)){
				// sediment removal from the vegetation (i.e., scraping a bit) -> only removes the top layer of sediment_accumulation = what has accumulated over a year
				ask agents of_generic_species ext_metric_failure where (each.my_name="partpoll_acc"){
					do update_accumulation_value(my_accumulation_rate);
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
		do check_veg_negative_impact();
	//	write practice_name + "done on " + impacted_component.my_name + " on " + current_date;

	}


	// some maintenance practices have a negative impact on grass and shrubs
	action check_veg_negative_impact {
		if (impacted_component != nil) {
				ask agents of_generic_species vegetal_component where ((each.my_NBSS=impacted_component.my_NBSS) and (each.my_name!="trees")) {	
					// sediment_removal if done when filter media is completely clogged and needs replacement kills all the vegetation 
					if (myself.practice_name = "fm_sediment_removal") {
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
						//preferred season to remove vegetation is in the winter for it to minimize impact on ecosystem and "biodiversity" on general
						// so if the plant_removal is not in winter it creates a disturbance to the "ecosystem" or "biodiversity" here
						if !(current_season =myself.my_target_season){
							create failure_event {
								my_name <-"plant_disturbance";
								impacted_agent <- myself.my_name;
								impacted_attribute <- "my_biodiversity";	
								last_failure <- current_date;
								do failure_impact(3.0);
								time_to_recover <- 24.0;
							}
						}
					
					}
					// when mowing is done on filter media in summer, biodiversity is impacted
					if (("excess_veg_removal" in myself.practice_name) and (myself.impacted_component.my_name="filter_media")) {
						if !(current_season =myself.my_target_season) {
							create failure_event {
								my_name <- "summer_mowing";
								impacted_agent <- myself.my_name;
								impacted_attribute <- "my_biodiversity";	
								last_failure <- current_date;
								do failure_impact(1.0);
								time_to_recover<- 1.0; //in months
							}
						}
						if (function_attributes["my_health"] = 3) {
							create failure_event {
								my_name <- "intensive_management";
								impacted_agent <- myself.my_name;
								impacted_attribute <- "my_biodiversity";	
								last_failure <- current_date;
								do failure_impact(1.0);
								time_to_recover<- 1.0;
							}
						}
					
					}
				}
				
			
		}
	}
	
	
	//check the failures that have impacted all components and recover them, check accumulation value of partpoll_acc on filter_media and recover if needed 	
	action visual_inspection (NBSS NBSS_to_inspect){
		NBSS_to_inspect.inspected <- true;
		ask agents of_generic_species component where (each.my_NBSS=NBSS_to_inspect) {
			list<string> functions_to_repair;
			if (self is vegetal_component){
				 functions_to_repair <- ["my_health"];
			}
			else {
				functions_to_repair <- ["my_qtf"];
			}
			map<failure_event, float> different_failures <- failures_to_repair(functions_to_repair);
			// create a maintenance practice whose impact level will be equal to the number of failure types that have impacted the component
			if length(different_failures)!= 0 {
				loop i over: different_failures.keys {
					loop index_row from:1 to: mp_failure_map.rows -1 {
						if mp_failure_map[1,index_row] = i.my_name { // find the row corresponding to the maintenance practice in the mp_failure map 
							create maintenance  {
								practice_name <- mp_failure_map[0,index_row];	 
								impacted_component <- myself;
								my_NBSS<-impacted_component.my_NBSS;
								impacted_attribute <- i.impacted_attribute;
								impact_level <-  different_failures[i];
								maintenance_trigger_date <- current_date ;	
								linked_failure_name <-i.my_name ;
								veg_disturbance_factor <-  veg_disturbance_map[mp_failure_map[2,index_row]];
								my_target_season <- mp_failure_map[3,index_row];
							}
						}	
					}
				}
			}
		
		}// if we are currently during a target season of any maintenance practice and that the maintenance has not been done yet
		if ((failure_target_seasons.values contains current_season) and seasonal){
			list<string> target_failures ; 
			loop i over:failure_target_seasons.keys {
				if failure_target_seasons[i]=current_season {
					add i to:target_failures; 
				}
			}
			ask agents of_generic_species failure_event where (each.my_name in target_failures){
				component inspected_component <- one_of(agents of_generic_species component where (each.my_name=self.impacted_agent));
				// if the next_failure is going to come in the next year
				if (!(next_failure=nil) and (next_failure < current_date + 1#year) and !(self in inspected_component.my_failures)) {
					loop index_row from:1 to: mp_failure_map.rows -1 {
						if mp_failure_map[1,index_row] = my_name { // find the row corresponding to the maintenance practice in the mp_failure map 
							create maintenance  {
								practice_name <- mp_failure_map[0,index_row];	 
								impacted_component <- one_of(agents of_generic_species component where (each.my_name=myself.impacted_agent));
								my_NBSS<-impacted_component.my_NBSS;
								impacted_attribute <- myself.impacted_attribute;
								impact_level <- myself.level_of_impact;
								// 1 day is added for the dynamic of the model DO NOT MODIFY 
								maintenance_trigger_date <- current_date ;	
								linked_failure_name <-myself.my_name ;
								veg_disturbance_factor <-  veg_disturbance_map[mp_failure_map[2,index_row]];
								my_target_season <- mp_failure_map[3,index_row];	
							}
						}
						
					}
					
				}
			}
		}
		NBSS_to_inspect.inspection_date <-current_date;
	}
	
	
}


species scheduled_maintenance parent: maintenance {
	// data from maintenance_scheduled.csv
	float maintenance_frequency;
	string department;
	bool prog_season_dep; //some maintenance practices are season-dependent, i.e. they have a positive impact only if carried out during their target season(s)
	list<string> prog_target_season;
	float cost;
	float next_maintenance_interval <- maintenance_frequency + rnd(-8, 9); // 8 to 9 weeks variability around the maintenance frequency that is given in weeks in the maintenance_programmed.csv file
	
	// for each  maintenance practice created, create the list of linked_failures from failure_mp_map
	// TODO: make sure that if a maintenance practice is created it should have a linked failure to it OR create another option..
	reflex link_mp_to_failure  {
		loop index_row from:1 to: mp_failure_map.rows -1{
			if mp_failure_map[0,index_row] = practice_name { // find the row corresponding to the maintenance practice in the mp_failure map 
				linked_failure_name <- mp_failure_map[1,index_row];
				veg_disturbance_factor <-  veg_disturbance_map[mp_failure_map[2,index_row]];
				my_target_season <- mp_failure_map[3,index_row];
			}

		}
	}


	reflex trigger_scheduled_maintenance when: ("scheduled" in maintenance_type)and every(next_maintenance_interval# week) and (current_date>starting_date){ 
		if (practice_name="visual_inspection") {
			do visual_inspection(any(NBSS));
		}
		else {
			ask agents of_generic_species component {	
				list<string> functions_to_repair;
				if (self is vegetal_component){
					 functions_to_repair <- ["my_health"];
				}
				else {
					functions_to_repair <- ["my_qtf"];
				}
				map<failure_event, float> different_failures <- failures_to_repair(functions_to_repair);
				if length(different_failures)=0{
					maintenance_ressources <- maintenance_ressources + 0.1;
				}				
				if length(different_failures)!=0 {
					list<string> failure_names;
					loop j over:different_failures.keys {	
						if j.my_name=myself.linked_failure_name {
							myself.impacted_component <- self;
							myself.impacted_attribute <- self is vegetal_component ? "my_health" : "my_qtf";
							myself.impact_level <- different_failures [j];
							myself.maintenance_trigger_date <- current_date;
						}
						add j.my_name to:failure_names;
					}
				if !(myself.linked_failure_name in failure_names){
						maintenance_ressources <- maintenance_ressources + 0.1;
				}

				}

				//my_failures <-my_failures where (!(each.my_name in myself.processed_failures)); 			
				
//				// go over every failure that has impacted the component and repair specific failure with triggered maintenance practice
//				if length(my_failures)>=1{	
//					loop j over:my_failures {
//						//the maintenance practice will have a positive impact of +1 = it will repair (+1) as many failures as it is linked to that have impacted the component
//						if j.my_name =myself.linked_failure_name{
//							ask j {
//								myself.function_attributes[impacted_attribute] <- min(3,myself.function_attributes[impacted_attribute]+1);
//								//reset failure event frequency with maintenance date
//								 last_maintenance <- current_date; 
//							}
//							add j.my_name to:myself.processed_failures;
//							maintenance_ressources <- maintenance_ressources +(1*myself.practice_intensity[current_state]);							
//							
//						}
//					}
//				}	
//				my_failures <-my_failures where (!(each.my_name in myself.processed_failures)); 			
			} 
				
				
		}
		do check_veg_negative_impact();
		next_maintenance_interval <- maintenance_frequency + rnd(-8, 9); 
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
			
		   save [maintenance_ressources,accepted_flood_days,flooding_days,degraded_vegetation_days,poor_well_being_days] to: "results.csv" format:"csv" rewrite: false header: true ;
		}
	}

}

experiment "rainfall intensity sensitivity" type: batch repeat: 10
parallel: true
until: (current_date = end_date) {

    parameter "Maintenance"
        var: maintenance_type
        among: [//"scheduled",
			    //"corrective",
			    //"preventive",
			    //"preventive_seasonal",
			    //"seasonal",
			    "no_maintenance"]
        init: "no_maintenance";

  parameter "Intensity threshold"
        var: intensity_threshold
        among: [2.08, 2.89, 7.04]
        init: 2.08;
 
	parameter "Batch mode"
        var: is_batch
        init: true;

   reflex save_results {

    ask simulations {
	//	write "maintenance_type " + maintenance_type ;


        save [
            maintenance_type,
            intensity_threshold,
            maintenance_ressources,
           
            flooding_days_nbss1,
            flooding_days_nbss2,
            flooding_days_system,
            
            degraded_vegetation_days,
            poor_well_being_days,
            rainclass1,
            rainclass2,
            rainclass3
        ]
        to: "../results/maintenance_type_no_maintenance.csv"
        format: "csv"
        rewrite: false
        header: true;
    }
}
}

// Simple run of model without interface 
experiment "run" type: gui {
	output {
		monitor "Accepted flood" value: accepted_flood_days;
		monitor "Flooding" value: flooding_days;
		monitor "Degraded vegetation days" value:degraded_vegetation_days;
		monitor "Maintenance days" value:poor_well_being_days;
		
		display swales_display type: 2d {
    species urban_area aspect: base;
    species road aspect: base;
    species NBSS aspect: base;
		}
		
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
		monitor "Maintenance" value:maintenance_ressources;
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
				data "Sediment accumulation" value:ext_metric_failure where (each.my_name="partpoll_acc") collect (each.my_value) color: #red;
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
				data "Tree Health" value:trees collect (each.function_attributes["my_health"]) color: #darkgreen marker_shape: marker_down_triangle;
				data "Grass health" value:grass collect (each.function_attributes["my_health"]) color: #lightgreen marker_shape: marker_down_triangle;
				data "Shrubs health" value:shrubs collect (each.function_attributes["my_health"]) color: #turquoise marker_shape: marker_down_triangle;
				data "Biodiversity" value:shrubs collect (each.function_attributes["my_biodiversity"])color: #thistle style: dot;
				
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
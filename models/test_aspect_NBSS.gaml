/**
* Name: test_aspect
* Based on the internal empty template. 
* Author: egirot
* Tags: 
* 
*/



model test_aspect

//******************** GLOBAL *****************************************
global {
	float step <-1 #day;
	float step1 <- 1.0;
	


	
	// Loading image files for NBSS visualization
	image_file grass_image <- image_file("../images/grass.png");
	image_file shrubs_plants_image <- image_file("../images/shrubs_plants.png");
	image_file tree_image <- image_file("../images/tree.png");	
	
	// Performance map -> to add in NBSS species ?
	map <string,int> performance <- ["Flood protection"::3,"Natural receiving ecosystem preservation"::3, "Biodiversity preservation"::3,"Climate change adaptation"::3]; 
	
	bool end_sim<-false;
	bool static_arrows<-true;
	
	// maintenance parameters 
	string maintenance_type <- "no maintenance";// parameter: maintenance_type among:["no maintenance", "run-to-failure", "programmed"];
	int intervention_delay_days <- 5;// parameter:true  min:2 max: 30;

	
	init {

		create rain {

		}
		create NBSS with: [location::{50, 40}]{
			my_name <- "Bioretention cell";
			create inlet with: [location::{20, 25}]{
				my_name<-"inlet";

			}
			create ponding_area with: [location::{45, 40}] {
				my_name<-"ponding_area";

		
			}	
			create filter_media with: [location::{45, 46}]{
				my_name<-"filter_media";

			}	
		
			create grass with: [location::{45, 33}] {
				my_name <- "grass";

			}
			
			create shrubs_plants with: [location::{62, 31}] {
				my_name <- "shrubs_plants";
 

			}
			
			create trees with: [location::{80, 27}]{
				my_name <- "trees";

			}
			
			create outlet with: [location::{75, 60}]{
				my_name <- "outlet";

			}

			
		}
		create urban_environment with: [location::{50, 37.5}] {
			my_name <- "Urban environment";

			
		}
		
		create sewer_system with: [location::{50,90}]{
			my_name <- "Sewer system";
		}
		
		create natural_environment with: [location::{50,90}]{
			my_name <- "Receiving natural environment";
		}
			

				

	}

}

//************************ SPECIES DECLARATION ***************************
/* Declaration of the rain species */
species rain {

}

/* Declaration of the species NBSS */
species NBSS {
	string my_name;



}

/* Declaration of the parent species component */
species component {
	string my_name;


}

/**************************** PARENT : ENGINEERED COMPONENTS*****************************************/

species engineered_component parent: component {

}


/********************************************** INLET ***************************************/
species inlet parent: engineered_component {
	
	
	aspect default {
		draw circle(4) border:#black ;
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -7, 1} anchor: #top_center;
		//draw line([ponding_area(0).location -0.01,self.location + 3]) color: #dodgerblue begin_arrow: 2 end_arrow: -7 width: 2.0;
	}
	
}

/******************************************** PONDING AREA ********************************************/
species ponding_area parent: engineered_component {
	bool temporary<-true;
	bool ponding <- false;
	

	aspect default {
		draw ellipse(30,5) border:#blue color:#lightblue ;
		draw my_name color:#black  font:font("Helvetica", 12, #bold) at: location anchor: #center;
	
	}
	
}

/************************************************** FILTER MEDIA **********************************************/
species filter_media parent: engineered_component {
	

	aspect default {
		draw rectangle(30,5) border:#sienna ;
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location anchor: #center;
	}
}


/***************************************************** OUTLET *************************************/
species outlet parent: engineered_component {
	aspect default {
		draw circle(4) border:#black ;
		draw my_name color:#black font:font("Helvetica", 12, #bold) at: location + {0, -7, 1} anchor: #center;
	}
}



/**************************************** PARENT : VEGETAL COMPONENTS*************************************************/

species vegetal_component parent: component {
	

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
	

	
	
	
}

/***************************************************** MANAGED OUTPUT FLOW *******************************************/
species managed_flow parent: output_flow {


}


/***************************************************** UNMANAGED OUTPUT FLOW *******************************************/
species unmanaged_flow parent: output_flow {
	
}




//******************** EXPERIMENT  *****************************************
	
	

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

	}
}




/**
* Name: test2swales
* Based on the internal empty template. 
* Author: swroy
* Tags: 
*/

model test2swales

global {
	file shape_file_swales <- file("C:/Users/swroy/Downloads/GQIS_map_+_raindata/GIS_2 Swales/2_swales.shp");
	geometry shape <- envelope(shape_file_swales);
	
	init {
		create swale from: shape_file_swales with: [
			swale_id::string(read("id")),
			type_sfn::string(read("Type_SFN")),
			adresse::string(read("Adresse")),
			sfn_valide::string(read("SFN_valide"))
		] {
			write "Imported swale: " + swale_id + " | " + type_sfn + " | " + adresse + " | " + sfn_valide;
		}
		
		write "Number of swales imported: " + length(swale);
	}
}

species swale {
	string swale_id;
	string type_sfn;
	string adresse;
	string sfn_valide;
	rgb color <- #yellow;
	
	aspect base {
		draw shape color: color border: #black;
	}
}

experiment test_swales type: gui {
	parameter "Shapefile for the swales:" var: shape_file_swales category: "GIS";
	
	output {
		display swales_display type: 2d {
			species swale aspect: base;
		}
	}
}
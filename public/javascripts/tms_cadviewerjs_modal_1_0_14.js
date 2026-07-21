

	var icon_command_active = 0;


	var load_waitflag_files = 0;
	var load_waitflag_overlay = 0;
	var load_waitflag_cluster = 0;
	var load_waitflag_linklist = 0;

	var edit_cancel_flag = false;



	var fArr_Name = new Array();  // CH
	var fArr_Id = new Array();  // CH
	var fArr_PolygonNr = new Array();  // CH
	var fArr_PolygonLayerName = new Array();  // CH
	var fArr_Occupancy = new Array();  // CH
	var fArr_Tags = new Array();  // CH
	var fArr_Type = new Array();  // CH
	var fArr_Layer = new Array();  // CH

	var fArr_Name_fixtures = new Array();  // CH
	var fArr_Id_fixtures = new Array();  // CH
	var fArr_PolygonNr_fixtures = new Array();  // CH
	var fArr_PolygonLayerName_fixtures = new Array();  // CH
	var fArr_Occupancy_fixtures = new Array();  // CH
	var fArr_Tags_fixtures = new Array();  // CH
	var fArr_Type_fixtures = new Array();  // CH
	var fArr_Layer_fixtures = new Array();  // CH

	var save_drawing_flag = 0;
	var selectedLinkUnlinkLayer = "";

	var currentNode_underbar = "";
	var Node_underbar = "NODE_";
	var currentNode_name = "unassigned";
	var currentNode_id = "unassigned_";
	var Node_id = 1000;                                          // need method to determine current max nodeId
	var currentNode_layer = "unassigned";
	var currentNode_group = "unassigned";
	var currentNode_attributes = "unassigned";
	var currentNode_type = "unassigned";
	var currentNode_tags = "unassigned";
	var currentNode_occupancy = "unassigned";
	var currentNode_linked = false;   // internal flag for display in creation mode


	// placeholders - to be filled or design changed
	var fArr_Name = new Array();

	var cvjs_creationMode = false;

	//function generate_new_linkList(){};
	//function generate_new_linkList_fixtures(){};




	function change_link_space(rmid)
	{

		currentLinkId = rmid;
		for (var i=0;i<fArr_Name.length;i++)
		{
			if (fArr_Id[i] == rmid){
				// this is the room id selected
				$("#drop_link_spaces").html(fArr_Name[i]+'<b class="caret"></b>');
			}
		}
	}


	function change_link_fixtures(rmid)
	{

		currentLinkId = rmid;
		for (var i=0;i<fArr_Name_fixtures.length;i++)
		{
			if (fArr_Id_fixtures[i] == rmid){
				// this is the room id selected

				var fixtureName = "";
				if (fArr_Name_fixtures[i] == "")
					fixtureName = fArr_Id_fixtures[i];
				else
					fixtureName = fArr_Name_fixtures[i];

				$("#drop_link_fixtures").html(fixtureName+'<b class="caret"></b>');
			}
		}
	}



	function generate_new_linkList_fixtures(){

//window.alert("generate_new_linkList_fixtures fArr_Name_fixtures.length ="+fArr_Name_fixtures.length);
		var k=0;
		new_linkList_fixtures = "";

		for (var i=0;i<fArr_Name_fixtures.length;i++)
		{

			if (fArr_PolygonNr_fixtures[i] == -1){
				// there is no association between a space and a polygon, therefore the space
				// is selectable and part of the list

				var fixtureName = "";

				if (fArr_Name_fixtures[i] == "")
					fixtureName = fArr_Id_fixtures[i];
				else
					fixtureName = fArr_Name_fixtures[i];

				new_linkList_fixtures = new_linkList_fixtures + "<li><a href=\"javascript:change_link_fixtures('"+fArr_Id_fixtures[i]+"')\">"+fixtureName+"</a></li>";

			}
			else{

			// window.alert("we have something different from -1 "+fArr_PolygonNr_fixtures[i]);

			}

		}

//window.alert(fArr_Name_fixtures.length+" new_linkList_fixtures :"+new_linkList_fixtures);

		$("#fixtures_drawing").html(new_linkList_fixtures);  // CH


	// autocomplete on lists is not done


	}



	function generate_new_linkList()     // list of spaces that are unoccupied and can be linked
	{

	// window.alert("generate_new_linkList ");

		var k=0;
		new_linkList = "";

		//window.alert("generate_new_linkList "+fArr_Name.length);

		for (var i=0;i<fArr_Name.length;i++)
		{

			if (fArr_PolygonNr[i] == -1){
				// there is no association between a space and a polygon, therefore the space
				// is selectable and part of the list
				new_linkList = new_linkList + "<li><a href=\"javascript:change_link_space('"+fArr_Id[i]+"')\">"+fArr_Name[i]+"</a></li>";

			}
			else{
				//window.alert(i+" this space is occupied and is not included in the list");
				// this space is occupied, so we need to use this for the Type, Occupancy and Tags autocomplete lists

				// have to figure out if the item is already in the autocomplete list or not

/*

				var flag = true;
				for (var j=0;j<searchListType.length;j++){
					if (searchListType[j] == fArr_Type[i]){ flag = false;}
				}
				if (flag == true) { searchListType.push(fArr_Type[i]);  }

				flag = true;
				for (var j=0;j<searchListOccupancy.length;j++){
					if (searchListOccupancy[j] == fArr_Occupancy[i]){ flag = false;}
				}
				if (flag == true) { searchListOccupancy.push(fArr_Occupancy[i]);  }


				flag = true;
				for (var j=0;j<searchListTags.length;j++){
					if (searchListTags[j] == fArr_Tags[i]){ flag = false;}
				}
				if (flag == true) { searchListTags.push(fArr_Tags[i]);  }
*/

			}

		}

		$("#spaces_drawing").html(new_linkList);  // CH

//windows.alert("linklist 1");

		load_waitflag_linklist = 1;
		if ( load_waitflag_files == 1 && load_waitflag_cluster == 1 && load_waitflag_overlay == 1 && load_waitflag_linklist == 1)
			$("#loadpane_small").hide();


//window.alert("spaces_drawing is updated!");

	}






	function getOccupancy_location(data, serverConnection) {
		var j=0;

	    // window.alert("We now have a data response from alfa2!");

		if (serverConnection){
			for (i=0; i < data.length; i++)
				{
				if(data[i].name.indexOf("Unassigned")>-1 || data[i].name.indexOf("flashlight")>-1 ){
					// do nothing
				}
				else{

					fArr_Name[j] = data[i].name;  // name of space
					fArr_Id[j] = data[i].id;     // if of space
					fArr_PolygonNr[j] = -1;    // no association with room polygons yet
					fArr_PolygonLayerName[j] = "none"; // no association with room polygons yet
					fArr_Type[j] = -1;
					fArr_Occupancy[j] = -1;
					fArr_Tags[j] = -1;
					j++


				}
			}

		}
		else{   // We do not have a server connection so we make the data from .js and -nodes.js arrays
			for (spc in vqRooms){

					if (isNaN(vqRooms[spc].data("id"))){

					}
					else{
						fArr_Name[j] = vqRooms[spc].data("name");  // name of space
						fArr_Id[j] = vqRooms[spc].data("id");     // if of space
						fArr_PolygonNr[j] = -1;    // no association with room polygons yet
						fArr_PolygonLayerName[j] = "none"; // no association with room polygons yet
						fArr_Type[j] = -1;
						fArr_Occupancy[j] = -1;
						fArr_Tags[j] = -1;
						j++
					}
			}
		}


		// do the sort alphabetically
		var t1 = "";
		var t2 = "";
		for (var k=0; k < fArr_Name.length-1; k++){

			for (var l=k+1; l < fArr_Name.length; l++){

				if ( fArr_Name[k].toLowerCase() > fArr_Name[l].toLowerCase() ){

					t1 = fArr_Name[l];
					t2 = fArr_Id[l];

					fArr_Name[l] = fArr_Name[k];  // name of space
					fArr_Id[l] =  fArr_Id[k];     // if of space

					fArr_Name[k] = t1;   // name of space
					fArr_Id[k] =  t2;    // if of space

					// fArr_PolygonNr[j] = -1;        // no association with room polygons yet
					// fArr_PolygonLayerName[j] = ""; // no association with room polygons yet

				}

			}
		}


		for (var k=0; k < fArr_Name.length; k++){

			fArr_PolygonNr[k] = -1;    // no association with room polygons yet
			fArr_PolygonLayerName[k] = "none"; // no association with room polygons yet
			fArr_Type[k] = -1;
			fArr_Occupancy[k] = -1;
			fArr_Tags[k] = -1;

			var l=0;



// we have changed the loop to be based on vqRooms information, rather than what is in the fArr arrays
			for (spc in vqRooms){

				//if (k==5) window.alert(vqRooms[spc].data("id")+" "+fArr_Id[k]);

				if (vqRooms[spc].data("id") == fArr_Id[k]){

//window.alert(vqRooms[spc].data("node")+"   "+vqRooms[spc].data("id")+" "+fArr_Id[k]);

						fArr_PolygonNr[k] = vqRooms[spc].data("name");
						fArr_PolygonLayerName[k] = vqRooms[spc].data("node");
						fArr_Layer[k] = vqRooms[spc].data("layer");

						if (vqRooms[spc].data("type").indexOf("undefined")>=0){
							// do nothing
						}
						else{

							fArr_Type[k] = vqRooms[spc].data("type");
						}
						if (vqRooms[spc].data("occupancy").indexOf("undefined")>=0){
							// do nothing
						}
						else{

							fArr_Occupancy[k] = vqRooms[spc].data("occupancy");
						}
// we dont know how to read in tags properly at this time....

						fArr_Tags[k] = "";

//								if (vqRooms[spc].data("tags").indexOf("tags")>=0){
//									// do nothing
//								}
//								else{
//									fArr_Tags[k] = vqRooms[spc].data("tags");
//								}


				}


			}



		}

		generate_new_linkList();

		load_waitflag_cluster = 1;

		if ( load_waitflag_files == 1 && load_waitflag_cluster == 1 && load_waitflag_overlay == 1 && load_waitflag_linklist == 1)
			$("#loadpane_small").hide();


		// reset the array that shows which office spaces are available for selection
	    // generate_new_linkList();


	}


/// FIXTURES

	function getOccupancy_fixtures(data, serverConnection) {
		var j=0;

//window.alert("first in fixtures");

	    if (serverConnection){
	//	  window.alert("We now have a data response from alfa2!  data.length="+data.length);
			for (i=0; i < data.length; i++){
					fArr_Id_fixtures[j] = data[i].serialNum;     // fixture serialnum
					if (data[i].name)
						fArr_Name_fixtures[j] = data[i].name;  // name of fixture
					else
						fArr_Name_fixtures[j] = "";  // name of fixture

					fArr_PolygonNr_fixtures[j] = -1;    // no association with room polygons yet
					fArr_PolygonLayerName_fixtures[j] = "none"; // no association with room polygons yet
					fArr_Type_fixtures[j] = -1;
					fArr_Occupancy_fixtures[j] = -1;
					fArr_Tags_fixtures[j] = -1;
					j++

			}

		}
		else{   // We do not have a server connection so we make the data from .js and -nodes.js arrays
			for (spc in vqRooms){

//window.alert(spc + " "+vqRooms[spc].data("id"));
//window.alert(isNan(vqRooms[spc].data("id"))+" "+vqRooms[spc].data("id"));

					if (isNaN(vqRooms[spc].data("id"))){
						fArr_Id_fixtures[j] = vqRooms[spc].data("id");     // fixture serialnum
						fArr_Name_fixtures[j] = vqRooms[spc].data("name");  // name of fixture
						fArr_PolygonNr_fixtures[j] = -1;    // no association with room polygons yet
						fArr_PolygonLayerName_fixtures[j] = "none"; // no association with room polygons yet
						fArr_Type_fixtures[j] = -1;
						fArr_Occupancy_fixtures[j] = -1;
						fArr_Tags_fixtures[j] = -1;
						j++
					}
					else{

					}
			}
		}


		// do the sort alphabetically

		var t1 = "";
		var t2 = "";

//window.alert("before the alphabetic sort");

		for (var k=0; k < fArr_Name_fixtures.length-1; k++){

			for (var l=k+1; l < fArr_Name_fixtures.length; l++){

				if ( fArr_Name_fixtures[k].toLowerCase() > fArr_Name_fixtures[l].toLowerCase() ){  // we sort on names

					t1 = fArr_Name_fixtures[l];
					t2 = fArr_Id_fixtures[l];

					fArr_Name_fixtures[l] = fArr_Name_fixtures[k];  // name of space
					fArr_Id_fixtures[l] =  fArr_Id_fixtures[k];     // serialNum of space

					fArr_Name_fixtures[k] = t1;   // name of space
					fArr_Id_fixtures[k] =  t2;    // if of space

					// fArr_PolygonNr[j] = -1;        // no association with room polygons yet
					// fArr_PolygonLayerName[j] = ""; // no association with room polygons yet

				}

			}
		}


		for (var k=0; k < fArr_Name_fixtures.length; k++){

			fArr_PolygonNr_fixtures[k] = -1;    // no association with room polygons yet
			fArr_PolygonLayerName_fixtures[k] = "none"; // no association with room polygons yet
			fArr_Type_fixtures[k] = -1;
			fArr_Occupancy_fixtures[k] = -1;
			fArr_Tags_fixtures[k] = -1;

			var l=0;

			for (spc in vqRooms){

				//if (k==5) window.alert(vqRooms[spc].data("id")+" "+fArr_Id[k]);

				if (vqRooms[spc].data("id") == fArr_Id_fixtures[k]){

//window.alert(vqRooms[spc].data("node")+"   "+vqRooms[spc].data("id")+" "+fArr_Id[k]);

						fArr_PolygonNr_fixtures[k] = vqRooms[spc].data("name");
						fArr_PolygonLayerName_fixtures[k] = vqRooms[spc].data("node");
						fArr_Layer_fixtures[k] = vqRooms[spc].data("layer");

						if (vqRooms[spc].data("type").indexOf("undefined")>=0){
							// do nothing
						}
						else{

							fArr_Type_fixtures[k] = vqRooms[spc].data("type");
						}
						if (vqRooms[spc].data("occupancy").indexOf("undefined")>=0){
							// do nothing
						}
						else{

							fArr_Occupancy_fixtures[k] = vqRooms[spc].data("occupancy");
						}
// we dont know how to read in tags properly at this time....

						fArr_Tags_fixtures[k] = "";

//								if (vqRooms[spc].data("tags").indexOf("tags")>=0){
//									// do nothing
//								}
//								else{
//									fArr_Tags_fixtures[k] = vqRooms[spc].data("tags");
//								}


				}


			}




		}

		generate_new_linkList_fixtures();

		load_waitflag_cluster = 1;

		if ( load_waitflag_files == 1 && load_waitflag_cluster == 1 && load_waitflag_overlay == 1 && load_waitflag_linklist == 1)
			$("#loadpane_small").hide();


	}


/// FIXTURES







	function cvjs_ObjectSelected(rmid){

		// if (true) return;

		if (!cvjs_creationMode){
			cvjs_creationMode=true;
			cvjs_setCreationMode(cvjs_creationMode);
			getOccupancy_location(null, false);
			getOccupancy_fixtures(null, false);
		}

		// generic callback method when an object has been clicked
		//window.alert("an object has been clicked! "+rmid);
		// this function is often not implemented as the methods defined in cvjsPopUpBody takes precedence

//window.alert("object clicked "+rmid);

		if (icon_command_active == 10){   // layer off
			for (spc in vqRooms)
			{
				if (vqRooms[spc].data("id") == rmid) {
					var layer = vqRooms[spc].data("layer");
					cvjs_LayerOff(layer);
				}
			}
			all_icons_up();
			icon_command_active = 6;
			$('#select_image').attr("src", "../images_modal/tools/Select_Selected_2.png");
			$('#cv_select div').css('color', '#000000');
			$('#cv_select').css('background', '#a4d7f4');

		}
		else
		if (icon_command_active == 3){

			//window.alert("delete object");
			for (spc in vqRooms)
			{
				if (vqRooms[spc].data("id") == rmid) {
					var node = vqRooms[spc].data("node");
					cvjs_setUpVqRooms_deleteNode(node);
					CADViewer_floorplan_methods(node);  // deletes all arrays
				}
			}
		}
		else{   // it is select for highlight

			for (spc in vqRooms)
			{
				if (vqRooms[spc].data("id") == rmid) {
					var node = vqRooms[spc].data("node");
					CADViewer_floorplan_methods(node);
				}
			}
		}

		currentSelectedId = rmid;

	}



    function CADViewer_floorplan_methods(parameter1)
    {

//window.alert("CADViewer_floorplan_methods parameter1="+parameter1+" icon_command_active="+icon_command_active);
	try{


		if (icon_command_active == 1  || icon_command_active == 6 ){

			// A) we have selected a link polygons, which must be assigned with a space
			// B) or we have clicked the select button and the canvas, which means that something has been selected


			 if (selectedLinkUnlinkLayer != parameter1)
			 	reset_color_on_selected_space();

			 	selectedLinkUnlinkLayer = parameter1;

			// index_47:  selection mode is always on
			// if nothing is selected, then we hide the select window

				if (selectedLinkUnlinkLayer == "nolayername"){
					$('#link_tags_table').hide();
					$("#cvjs_IconMenuPanel").height(196);
					}
				else{
					$("#cvjs_IconMenuPanel").height(400);

					$('#link_tags_table').show();
//					$("#cvjs_IconMenuPanel").height(216);

					$("#location_text_static").show();
					$("#location_text_dynamic").hide();

				}


				// check what type of object that has been clicked

					// remove this layer from the space allocation list
				var linkflag = -1;
				for (var i=0;i<fArr_Name.length;i++)
				{
					if (fArr_PolygonLayerName[i] == selectedLinkUnlinkLayer){
						linkflag = i;
					}
				}

// fixtures
				var linkflag_fixture = -1;
				for (var i=0;i<fArr_Name_fixtures.length;i++)
				{
					if (fArr_PolygonLayerName_fixtures[i] == selectedLinkUnlinkLayer){
						linkflag_fixture = i;
					}
				}

//window.alert("linkflag="+linkflag+" linkflag_fixture="+linkflag_fixture);

				if (linkflag > -1 ){
					// this object is linked and therefore unlink buttons must be active
					// link will be active when action in the location field is done
					$('#unlink_location').css('color', '#0096d7');
					$('#done_editing_location').css('color', '#999999');  // #dddddd

					// now we must populate the location and tag fields in the menu correctly

					// dynamic page
					$("#drop_link_spaces").html(fArr_Name[linkflag]+'<b class="caret"></b>');
					$("#drop_link_fixtures").html("None Selected"+'<b class="caret"></b>');

					$("#type_tag").val(fArr_Type[linkflag]);

					var nval = fArr_Name[linkflag];

					$("#layer_tag").val("");
					$("#layer_s").html("");


//v3XXX
					var currId =  fArr_Id[linkflag];

//window.alert("  currId "+currId);

					for (spc in vqRooms)
					{
						if (vqRooms[spc].data("id") == currId ){


							$("#layer_tag").val(vqRooms[spc].data("layer"));
							$("#layer_s").html(vqRooms[spc].data("layer"));
						}
					}

					$("#occupancy_tag").val(fArr_Occupancy[linkflag]);
					$("#other_tags").val(fArr_Tags[linkflag]);

					// static page
					$("#location_s").html(fArr_Name[linkflag]);
					$("#type_s").html(fArr_Type[linkflag]);
					$("#occupancy_s").html(fArr_Occupancy[linkflag]);
					$("#tags_s").html(fArr_Tags[linkflag]);

					currentLinkId = fArr_Id[linkflag];
				}

				if (linkflag_fixture > -1 ){
					// this object is linked and therefore unlink buttons must be active
					// link will be active when action in the location field is done
					$('#unlink_location').css('color', '#0096d7');
					$('#done_editing_location').css('color', '#999999');  // #dddddd

					// now we must populate the location and tag fields in the menu correctly

					// dynamic page
					$("#drop_link_spaces").html("None Selected"+'<b class="caret"></b>');
					$("#drop_link_fixtures").html(fArr_Name_fixtures[linkflag_fixture]+'<b class="caret"></b>');

					$("#type_tag").val(fArr_Type_fixtures[linkflag_fixture]);


					var nval = fArr_Name_fixtures[linkflag_fixture];
					$("#layer_tag").val("");
					$("#layer_s").html("");

					var currId =  fArr_Id_fixtures[linkflag_fixture];

//window.alert("  currId fixtures "+currId);

					for (spc in vqRooms)
					{
						if (vqRooms[spc].data("id") == currId ){
							$("#layer_tag").val(vqRooms[spc].data("layer"));
							$("#layer_s").html(vqRooms[spc].data("layer"));
						}
					}

					$("#occupancy_tag").val(fArr_Occupancy_fixtures[linkflag_fixture]);
					$("#other_tags").val(fArr_Tags_fixtures[linkflag_fixture]);

					// static page
					$("#location_s").html(fArr_Name_fixtures[linkflag_fixture]);
					$("#type_s").html(fArr_Type_fixtures[linkflag_fixture]);
					$("#occupancy_s").html(fArr_Occupancy_fixtures[linkflag_fixture]);
					$("#tags_s").html(fArr_Tags_fixtures[linkflag_fixture]);

					currentLinkId = fArr_Id_fixtures[linkflag_fixture];
				}


//window.alert("currentLinkId="+currentLinkId);

				if (linkflag_fixture == -1  && linkflag == -1 ){
					// this object is an unlinked new object and therefore no is active
					// link will be active when action in the location field is done
					$('#unlink_location').css('color', '#999999');
					$('#done_editing_location').css('color', '#999999');

					// dynamic page
					$("#drop_link_spaces").html('None Selected'+'<b class="caret"></b>');
					$("#drop_link_fixtures").html("None Selected"+'<b class="caret"></b>');

					$("#type_tag").val("");
					$("#layer_tag").val("");
					$("#occupancy_tag").val("");
					$("#other_tags").val("");

					// static page
					$("#location_s").html("None Selected");
					$("#type_s").html("-");
					$("#occupancy_s").html("-");
					$("#tags_s").html("-");
					$("#layer_s").html("-");
					currentLinkId = -1;


				}



		}
		else{   // all other commands release icons

			if (icon_command_active == 2){
				if (selectedLinkUnlinkLayer == "nolayername"){

					// do nothing
				}
				else{

					// remove this layer from the space allocation list
					for (var i=0;i<fArr_Name.length;i++)
					{
						if (fArr_PolygonLayerName[i] == selectedLinkUnlinkLayer){
							fArr_PolygonNr[i] = -1;
							fArr_PolygonLayerName[i] = "none";
							fArr_Type[i] = -1;
							fArr_Layer[i] = -1;
							fArr_Occupancy[i] = -1;
							fArr_Tags[i] = -1;
						}
					}


					for (var i=0;i<fArr_Name_fixtures.length;i++)
					{
						if (fArr_PolygonLayerName_fixtures[i] == selectedLinkUnlinkLayer){
							fArr_PolygonNr_fixtures[i] = -1;
							fArr_PolygonLayerName_fixtures[i] = "none";
							fArr_Type_fixtures[i] = -1;
							fArr_Layer_fixtures[i] = -1;
							fArr_Occupancy_fixtures[i] = -1;
							fArr_Tags_fixtures[i] = -1;
						}
					}



					// update the space list table
					generate_new_linkList();

					generate_new_linkList_fixtures();


					// update the hyperlink information on the polygon on the drawing

					var tempstr = selectedLinkUnlinkLayer.substring(5);

					var scriptCode = "officeclick('"+tempstr+"')";
					var userFriendlyName = "Object "+tempstr;

//					document.applets[0].LinkShape(selectedLinkUnlinkLayer, scriptCode, userFriendlyName, 153, 153, 153, alpha_value, polygon_order, clean_polygon_space);


//window.alert("before calling LinkShape selectedLinkUnlinkLayer "+selectedLinkUnlinkLayer);


//					document.applets[0].LinkShape(selectedLinkUnlinkLayer, scriptCode, userFriendlyName, unselect_no_link_r, unselect_no_link_g, unselect_no_link_b, alpha_value, polygon_order, clean_polygon_space);


					// we set the text field of the space selector to "none selected"
					$("#drop_link_spaces").html('None Selected'+'<b class="caret"></b>');

				}
			}

			icon_command_active = 0;

			// reset all icon images
			all_icons_up();

//v3
			icon_command_active = 6;
			$('#select_image').attr("src", "../images_modal/tools/Select_Selected_2.png");
			$('#cv_select div').css('color', '#000000');
			$('#cv_select').css('background', '#a4d7f4');




    	}

    	}
    	catch(err) {  window.alert(err); }



    }



	function reset_color_on_selected_space()
	{
		var j = -1;
		if (selectedLinkUnlinkLayer.indexOf("NODE_")>=0){

			for (var i=0;i<fArr_Name.length;i++)		{
				if (fArr_PolygonLayerName[i].indexOf(selectedLinkUnlinkLayer)>=0){
					j = i;  // bingo, the layer is actually linked
				}
			}

			for (var i=0;i<fArr_Name_fixtures.length;i++)		{
				if (fArr_PolygonLayerName_fixtures[i].indexOf(selectedLinkUnlinkLayer)>=0){
					j = i;  // bingo, the layer is actually linked
				}
			}

		}

		if (j>-1){
			// the layer is linked therefore it must be colored in blue

		}
		else{
			// the layer is unlinked therefore it must be colored in gray
			if (selectedLinkUnlinkLayer.indexOf("NODE_")>=0){
			}
		}
	}


	function all_icons_up()
	{

			icon_command_active = 0;

			$('#select_image').attr("src", "../images_modal/tools/Select_Up_1.png");
			$('#cv_select').css('background', '#ffffff');
			$('#cv_select div').css('color', '#005299');

			$('#erase_image').attr("src", "../images_modal/tools/Erase_Up_1.png");
			$('#cv_erase').css('background', '#ffffff');
			$('#cv_erase div').css('color', '#005299');

			$('#rect_image').attr("src", "../images_modal/tools/DrawRect_Up_1.png");
			$('#cv_rect').css('background', '#ffffff');
			$('#cv_rect div').css('color', '#005299');

			$('#poly_image').attr("src", "../images_modal/tools/DrawPoly_Up_1.png");
			$('#cv_poly').css('background', '#ffffff');
			$('#cv_poly div').css('color', '#005299');

			$('#make_circle_image').attr("src", "../images_modal/tools/DC_Up_1.png");
			$('#cv_make_circle').css('background', '#ffffff');
			$('#cv_make_circle div').css('color', '#005299');

			$('#repeat_circle_image').attr("src", "../images_modal/tools/CC_Up_1.png");
			$('#cv_repeat_circle').css('background', '#ffffff');
			$('#cv_repeat_circle div').css('color', '#005299');

			$('#layer_off_image').attr("src", "../images_modal/tools/Layer_Off_Up_1.png");
			$('#cv_layer_off').css('background', '#ffffff');
			$('#cv_layer_off div').css('color', '#005299');

			$('#layer_on_all_image').attr("src", "../images_modal/tools/Layer_On_All_Up_1.png");
			$('#cv_layer_on_all').css('background', '#ffffff');
			$('#cv_layer_on_all div').css('color', '#005299');

			$("#location_text_static").hide();
			$("#location_text_dynamic").hide();

			$('#link_tags_table').hide();
			$("#cvjs_IconMenuPanel").height(196);
	}


// READY implementation

	$(document).ready(function()
	{

		$("#location_text_static").hide();
		$("#location_text_dynamic").hide();

		$('#link_tags_table').hide();
		$("#cvjs_IconMenuPanel").height(196);



		$("#fixtures_drawing").click(function() {
			$('#done_editing_location').css('color', '#0096d7');
		});

		$("#spaces_drawing").click(function() {
			$('#done_editing_location').css('color', '#0096d7');
		});
		$("#type_tag").click(function() {
			$('#done_editing_location').css('color', '#0096d7');
		});
		$("#layer_tag").click(function() {
			$('#done_editing_location').css('color', '#0096d7');
		});
		$("#occupancy_tag").click(function() {
			$('#done_editing_location').css('color', '#0096d7');
		});
		$("#other_tags").click(function() {
			$('#done_editing_location').css('color', '#0096d7');
		});







		$('#cv_select').mouseover(function()
			{
				if (icon_command_active != 6){
					$('#select_image').attr("src", "../images_modal/tools/Select_Over_3.png");
					$('#cv_select').siblings().children().css('color', '#a4d7f4');
					$('#cv_select').css('background', '#a4d7f4');

				}
			});


		$('#cv_erase').mouseover(function()
			{
				if (icon_command_active != 3){
					$('#erase_image').attr("src", "../images_modal/tools/Erase_Over_3.png");
					$('#cv_erase').siblings().children().css('color', '#FFF');
					$('#cv_erase').css('background', '#a4d7f4');
				}
			});

		$('#cv_rect').mouseover(function()
			{

				if (icon_command_active != 4){
					$('#rect_image').attr("src", "../images_modal/tools/DrawRect_Over_3.png");
					$('#cv_rect').siblings().children().css('color', '#FFF');
					$('#cv_rect').css('background', '#a4d7f4');
				}
			});

		$('#cv_poly').mouseover(function()
			{

				if (icon_command_active != 5){
					$('#poly_image').attr("src", "../images_modal/tools/DrawPoly_Over_3.png");
					$('#cv_poly').siblings().children().css('color', '#FFF');
					$('#cv_poly').css('background', '#a4d7f4');
				}

			});

		$('#cv_make_circle').mouseover(function()
			{

				if (icon_command_active != 7){
					$('#make_circle_image').attr("src", "../images_modal/tools/DC_Over_3.png");
					$('#cv_make_circle').siblings().children().css('color', '#FFF');
					$('#cv_make_circle').css('background', '#a4d7f4');
				}

			});


		$('#cv_repeat_circle').mouseover(function()
			{
				if (icon_command_active != 8){
					$('#repeat_circle_image').attr("src", "../images_modal/tools/CC_Over_3.png");
					$('#cv_repeat_circle').siblings().children().css('color', '#FFF');
					$('#cv_repeat_circle').css('background', '#a4d7f4');
				}

			});





		$('#cv_make_circle').mousedown(function()
			{

				if (icon_command_active == 7){

					icon_command_active = 0;
					all_icons_up();

				}
				else{
					reset_color_on_selected_space();
					all_icons_up();

					icon_command_active = 7;
					$('#make_circle_image').attr("src", "../images_modal/tools/DC_Down_4.png");

					$('#cv_make_circle div').css('color', '#000000');
					$('#cv_make_circle').css('background', '#a4d7f4');

					cvjs_hidePop();

					Node_id = cvjs_currentMaxNodeId();

					Node_id++;
					currentNode_underbar = Node_underbar+Node_id;
					currentNode_id = "NODE_"+Node_id;


					currentNode_name = "unassigned";
					currentNode_layer = "unassigned";
					currentNode_group = "unassigned";
					currentNode_attributes = "unassigned";
					currentNode_type = "unassigned";
					currentNode_tags = "unassigned";
					currentNode_tags = "unassigned";
					currentNode_linked = false;
					cvjs_setCurrentNodeValues(currentNode_underbar, currentNode_name, currentNode_id, currentNode_layer, currentNode_group, currentNode_attributes, currentNode_type, currentNode_tags, currentNode_tags, currentNode_linked);
					cvjs_addHandleFunc_Circle();
				}

				$('#link_tags_table').hide();
				$("#location_text_static").hide();
				$("#location_text_dynamic").hide();
				$("#cvjs_IconMenuPanel").height(196);

			});

		$('#cv_repeat_circle').mousedown(function()
			{

				if (icon_command_active == 8){
					icon_command_active = 0;
					all_icons_up();

				}
				else{
					reset_color_on_selected_space();
					all_icons_up();

					icon_command_active = 8;
					$('#repeat_circle_image').attr("src", "../images_modal/tools/CC_Down_4.png");

					$('#cv_repeat_circle div').css('color', '#000000');
					$('#cv_repeat_circle').css('background', '#a4d7f4');


					cvjs_hidePop();

					Node_id = cvjs_currentMaxNodeId();
					//window.alert("xurrent Node_id="+Node_id);

					Node_id++;
					currentNode_underbar = Node_underbar+Node_id;
					currentNode_id = "NODE_"+Node_id;

					currentNode_name = "unassigned";
					currentNode_layer = "unassigned";
					currentNode_group = "unassigned";
					currentNode_attributes = "unassigned";
					currentNode_type = "unassigned";
					currentNode_tags = "unassigned";
					currentNode_tags = "unassigned";
					currentNode_linked = false;
					cvjs_setCurrentNodeValues(currentNode_underbar, currentNode_name, currentNode_id, currentNode_layer, currentNode_group, currentNode_attributes, currentNode_type, currentNode_tags, currentNode_tags, currentNode_linked);
					cvjs_addHandleFunc_CopyCircle();

				}


				$('#link_tags_table').hide();
				$("#location_text_static").hide();
				$("#location_text_dynamic").hide();
				$("#cvjs_IconMenuPanel").height(196);



			});




		$('#cv_select').mousedown(function()
			{

				if (icon_command_active == 6){

					icon_command_active = 0;
					// color the selected layer in the color it had before selection
					reset_color_on_selected_space();
					all_icons_up();

					currentLinkId = -1;

				}
				else{

					// a different command has focus and we need to turn off the handlers for those
					all_icons_up();

					icon_command_active = 6;
					$('#select_image').attr("src", "../images_modal/tools/Select_Down_4.png");
					$('#cv_select div').css('color', '#000000');
					$('#cv_select').css('background', '#a4d7f4');


					$('#link_tags_table').hide();    // $('#link_tags_table').show();


					$('#unlink_location').html("Unlink Location");
					$('#done_editing_location').html("");
					$('#edit_cancel_location').html("Edit Fields");
					edit_cancel_flag = false;

					// make buttons gray

					$('#link_location').css('color', '#999999');
					$('#unlink_location').css('color', '#999999');

					// dynamic page
					$("#drop_link_spaces").html('None Selected'+'<b class="caret"></b>');
					$("#type_tag").val("");
					$("#layer_tag").val("");
					$("#occupancy_tag").val("");
					$("#other_tags").val("");

					// static page
					$("#location_s").html("None Selected");
					$("#type_s").html("-");
					$("#occupancy_s").html("-");
					$("#tags_s").html("-");
					$("#layer_s").html("-");

					generate_new_linkList();
					generate_new_linkList_fixtures();


				}


				$('#link_tags_table').hide();
				$("#location_text_static").hide();
				$("#location_text_dynamic").hide();
				$("#cvjs_IconMenuPanel").height(196);

			});


		$('#cv_erase').mousedown(function()
			{

				if (icon_command_active == 3){

					icon_command_active = 0;
					all_icons_up();

				}
				else{  // command different from 3

					reset_color_on_selected_space();
					all_icons_up();

					icon_command_active = 3;
					$('#erase_image').attr("src", "../images_modal/tools/Erase_Down_4.png");
					$('#cv_erase div').css('color', '#000000');
					$('#cv_erase').css('background', '#a4d7f4');


				}

				$('#link_tags_table').hide();
				$("#location_text_static").hide();
				$("#location_text_dynamic").hide();
				$("#cvjs_IconMenuPanel").height(196);


			});

		$('#cv_rect').mousedown(function()
			{

				if (icon_command_active == 4){

					icon_command_active = 0;
					all_icons_up();

				}
				else{
					reset_color_on_selected_space();
					all_icons_up();

					icon_command_active = 4;
					$('#rect_image').attr("src", "../images_modal/tools/DrawRect_Down_4.png");

					$('#cv_rect div').css('color', '#000000');
					$('#cv_rect').css('background', '#a4d7f4');

					cvjs_hidePop();
					Node_id = cvjs_currentMaxNodeId();
					//window.alert("xurrent Node_id="+Node_id);


					Node_id++;
					currentNode_underbar = Node_underbar+Node_id;
					currentNode_id = "NODE_"+Node_id;
					currentNode_name = "unassigned";
					currentNode_layer = "unassigned";
					currentNode_group = "unassigned";
					currentNode_attributes = "unassigned";
					currentNode_type = "unassigned";
					currentNode_tags = "unassigned";
					currentNode_tags = "unassigned";
					currentNode_linked = false;
					cvjs_setCurrentNodeValues(currentNode_underbar, currentNode_name, currentNode_id, currentNode_layer, currentNode_group, currentNode_attributes, currentNode_type, currentNode_tags, currentNode_tags, currentNode_linked);
					cvjs_addHandleFunc_Rectangle();

				}


				$('#link_tags_table').hide();
				$("#location_text_static").hide();
				$("#location_text_dynamic").hide();
				$("#cvjs_IconMenuPanel").height(196);



			});

		$('#cv_poly').mousedown(function()
			{

				if (icon_command_active == 5){
					icon_command_active = 0;
					all_icons_up();

				}
				else{
					reset_color_on_selected_space();
					all_icons_up();

					icon_command_active = 5;
					$('#poly_image').attr("src", "../images_modal/tools/DrawPoly_Down_4.png");

					$('#cv_poly div').css('color', '#000000');
					$('#cv_poly').css('background', '#a4d7f4');


					cvjs_hidePop();

					Node_id = cvjs_currentMaxNodeId();
					//window.alert("xurrent Node_id="+Node_id);

					Node_id++;
					currentNode_underbar = Node_underbar+Node_id;
					currentNode_id = "NODE_"+Node_id;
					currentNode_name = "unassigned";
					currentNode_layer = "unassigned";
					currentNode_group = "unassigned";
					currentNode_attributes = "unassigned";
					currentNode_type = "unassigned";
					currentNode_tags = "unassigned";
					currentNode_tags = "unassigned";
					currentNode_linked = false;
					cvjs_setCurrentNodeValues(currentNode_underbar, currentNode_name, currentNode_id, currentNode_layer, currentNode_group, currentNode_attributes, currentNode_type, currentNode_tags, currentNode_tags, currentNode_linked);
					cvjs_addHandleFunc_Polygon();
				}


				$('#link_tags_table').hide();
				$("#location_text_static").hide();
				$("#location_text_dynamic").hide();
				$("#cvjs_IconMenuPanel").height(196);


			});
// CH icon menu - mousedown



// icon menu - mouseout
		// we make a mouse down flag to tell which method is active

		$('#cv_select').mouseout(function()
			{
				if ( icon_command_active != 6 ){
			    	$('#select_image').attr("src", "../images_modal/tools/Select_Up_1.png");
					$('#cv_select div').css('color', '#005299');
					$('#cv_select').css('background', '#ffffff');
				}
				else{
			    	$('#select_image').attr("src", "../images_modal/tools/Select_Selected_2.png");
					$('#cv_select div').css('color', '#ffffff');
					$('#cv_select').css('background', '#0096d7');

				}

			});



		$('#cv_erase').mouseout(function()
			{
				if ( icon_command_active != 3 ){
				    $('#erase_image').attr("src", "../images_modal/tools/Erase_Up_1.png");
					$('#cv_erase div').css('color', '#005299');
					$('#cv_erase').css('background', '#ffffff');
				}
				else{
			    	$('#erase_image').attr("src", "../images_modal/tools/Erase_Selected_2.png");
					$('#cv_erase div').css('color', '#ffffff');
					$('#cv_erase').css('background', '#0096d7');
					$('#link_tags_table').hide();
				}

			});

// QQ
		$('#cv_make_circle').mouseout(function()
			{
				if ( icon_command_active != 7 ){
				    $('#make_circle_image').attr("src", "../images_modal/tools/DC_Up_1.png");
					$('#cv_make_circle div').css('color', '#005299');
					$('#cv_make_circle').css('background', '#ffffff');
				}
				else{
			    	$('#make_circle_image').attr("src", "../images_modal/tools/DC_Selected_2.png");
					$('#cv_make_circle div').css('color', '#ffffff');
					$('#cv_make_circle').css('background', '#0096d7');
					$('#link_tags_table').hide();
				}

			});

		$('#cv_repeat_circle').mouseout(function()
			{
				if ( icon_command_active != 8 ){
				    $('#repeat_circle_image').attr("src", "../images_modal/tools/CC_Up_1.png");
					$('#cv_repeat_circle div').css('color', '#005299');
					$('#cv_repeat_circle').css('background', '#ffffff');
				}
				else{
			    	$('#repeat_circle_image').attr("src", "../images_modal/tools/CC_Selected_2.png");
					$('#cv_repeat_circle div').css('color', '#ffffff');
					$('#cv_repeat_circle').css('background', '#0096d7');
					$('#link_tags_table').hide();
				}

			});




		$('#cv_rect').mouseout(function()
			{
				if ( icon_command_active != 4 ){
				    $('#rect_image').attr("src", "../images_modal/tools/DrawRect_Up_1.png");
					$('#cv_rect div').css('color', '#005299');
					$('#cv_rect').css('background', '#ffffff');
				}
				else{
			    	$('#rect_image').attr("src", "../images_modal/tools/DrawRect_Selected_2.png");
					$('#cv_rect div').css('color', '#ffffff');
					$('#cv_rect').css('background', '#0096d7');
					$('#link_tags_table').hide();
				}

			});

		$('#cv_poly').mouseout(function()
			{
				if ( icon_command_active != 5 ){
				    $('#poly_image').attr("src", "../images_modal/tools/DrawPoly_Up_1.png");
					$('#cv_poly div').css('color', '#005299');
					$('#cv_poly').css('background', '#ffffff');
				}
				else{
			    	$('#poly_image').attr("src", "../images_modal/tools/DrawPoly_Selected_2.png");
					$('#cv_poly div').css('color', '#ffffff');
					$('#cv_poly').css('background', '#0096d7');
					$('#link_tags_table').hide();
				}

			});



		$('#cv_layer_off').mouseout(function()
			{
				if ( icon_command_active != 10 ){
				    $('#layer_off_image').attr("src", "../images_modal/tools/Layer_Off_Up_1.png");
					$('#cv_layer_off div').css('color', '#005299');
					$('#cv_layer_off').css('background', '#ffffff');
				}
				else{
			    	$('#layer_off_image').attr("src", "../images_modal/tools/Layer_Off_Selected_2.png");
					$('#cv_layer_off div').css('color', '#ffffff');
					$('#cv_layer_off').css('background', '#0096d7');
					$('#link_tags_table').hide();
				}

			});


		$('#cv_layer_on_all').mouseout(function()
			{
				if ( icon_command_active != 11 ){
				    $('#layer_on_all_image').attr("src", "../images_modal/tools/Layer_On_All_Up_1.png");
					$('#cv_layer_on_all div').css('color', '#005299');
					$('#cv_layer_on_all').css('background', '#ffffff');
				}
				else{
			    	$('#layer_on_all_image').attr("src", "../images_modal/tools/Layer_On_All_Selected_2.png");
					$('#cv_layer_on_all div').css('color', '#ffffff');
					$('#cv_layer_on_all').css('background', '#0096d7');
					$('#link_tags_table').hide();
				}

			});

		$('#cv_layer_off').mousedown(function()
			{
				if (icon_command_active == 10){
					icon_command_active = 0;
					all_icons_up();
				}
				else{
					reset_color_on_selected_space();
					all_icons_up();
					icon_command_active = 10;
					$('#layer_off_image').attr("src", "../images_modal/tools/Layer_Off_Down_4.png");
					$('#cv_layer_off div').css('color', '#000000');
					$('#cv_layer_off').css('background', '#a4d7f4');
				}


				$('#link_tags_table').hide();
				$("#location_text_static").hide();
				$("#location_text_dynamic").hide();
				$("#cvjs_IconMenuPanel").height(196);


			});


		$('#cv_layer_on_all').mousedown(function()
			{
				if (icon_command_active == 11){
					icon_command_active = 0;
					all_icons_up();
				}
				else{
					reset_color_on_selected_space();
					all_icons_up();
					icon_command_active = 11;
					$('#layer_on_all_image').attr("src", "../images_modal/tools/Layer_On_All_Selected_2.png");
					$('#cv_layer_on_all div').css('color', '#000000');
					$('#cv_layer_on_all').css('background', '#a4d7f4');

// set all layers on and go back into selection mode

//window.alert("before all layers on");

					cvjs_AllLayersOn();
					icon_command_active = 0;
					all_icons_up();

					icon_command_active = 6;
					$('#select_image').attr("src", "../images_modal/tools/Select_Selected_2.png");
					$('#cv_select div').css('color', '#000000');
					$('#cv_select').css('background', '#a4d7f4');


				}


			$('#link_tags_table').hide();
			$("#location_text_static").hide();
			$("#location_text_dynamic").hide();
			$("#cvjs_IconMenuPanel").height(196);



		});

		$('#cv_layer_off').mouseover(function()
			{
				if (icon_command_active != 10){
					$('#layer_off_image').attr("src", "../images_modal/tools/Layer_Off_Over_3.png");
					$('#cv_layer_off').siblings().children().css('color', '#FFF');
					$('#cv_layer_off').css('background', '#a4d7f4');
				}
			});

		$('#cv_layer_on_all').mouseover(function()
			{
				if (icon_command_active != 11){
//					$('#layer_on_all_image').attr("src", "../images_modal/tools/Layer_On_All_Over_3.png");
					$('#layer_on_all_image').attr("src", "../images_modal/tools/Layer_On_All_Selected_2.png");
					$('#cv_layer_on_all').siblings().children().css('color', '#FFF');
					$('#cv_layer_on_all').css('background', '#a4d7f4');
				}
			});

// end icon menu


// SAVE DRAWING  - BEGIN

		$('#save_drawing').mouseover(function()
			{
				if (save_drawing_flag == 1)
			    	$('#save_drawing_image').attr("src", "../images_modal/tools/SaveChanges_240x22_Over.png");

			});

		$('#save_drawing').mouseout(function()
			{
			    if (save_drawing_flag == 1)
			    	$('#save_drawing_image').attr("src", "../images_modal/tools/SaveChanges_240x22_Up.png");

			});



		$('#save_drawing').mousedown(function()  //ZZZ
			{

				if (save_drawing_flag == 1) {

					// Set opacity of IconMenuPanel and block interaction
					$('#IconMenuPanel').css("filter", "alpha(opacity=20)");
					// filter:alpha(opacity=25);
					$('#IconMenuPanel').css("opacity", "0.20");
					// 	opacity:0.2;

					//$("#wait_looper").fadeIn(500);
					//$("#wait_looper_text_id").html("Saving");

// add XX
					$("#savepane_small").fadeIn(500);
					$("#savepane_small").show();

//v3WWW
					// block interaction!!!
					wait_looper_on = 1;

					var loc_x = $(window).width()/2;  // - ( $('#IconMenuPanel').width()+200)/2;   // image is 86x14    //infopane_small is 200
					var loc_y = ($(window).height() - 14) / 2;

					//$("#wait_looper").css({
					//	left:loc_x,
					//	top: loc_y,
					//	position:'absolute'
					//});



					$("#savepane_small").css({
						left:loc_x,
						top: loc_y,
						position:'absolute'
					});



					$('#save_drawing_image').attr("src", "../images_modal/tools/SaveChanges_240x22_Down.png");

						save_drawing_flag = 0;

					// clear colors if in select mode
					reset_color_on_selected_space();



						var tempstr = current_selected_filename.substring(0,current_selected_filename.lastIndexOf("."));


						var n_str = "";

						//  save .rw file with data arrays to server

						/*
							var fArr_Name = new Array();  // CH
							var fArr_Id = new Array();  // CH
							var fArr_PolygonNr = new Array();  // CH
							var fArr_PolygonLayerName = new Array();  // CH
							var fArr_Occupancy = new Array();  // CH
							var fArr_Tags = new Array();  // CH
							var fArr_Type = new Array();  // CH
						*/

						var dataUrl = "";

						var dataLength = fArr_Name.length;

						dataUrl = "(RW-3)|"+dataLength+"|";                               // we are changing to RW-3
						for (var i=0; i<dataLength; i++){
							dataUrl = dataUrl + fArr_Name[i]+";";
						}
						dataUrl = dataUrl + "|";

						dataUrl = dataUrl + dataLength+"|";
						for (var i=0; i<dataLength; i++){
							dataUrl = dataUrl + fArr_Id[i]+";";
						}
						dataUrl = dataUrl + "|";

						dataUrl = dataUrl + dataLength+"|";
						for (var i=0; i<dataLength; i++){
							dataUrl = dataUrl + fArr_PolygonNr[i]+";";
						}
						dataUrl = dataUrl + "|";

						dataUrl = dataUrl + dataLength+"|";
						for (var i=0; i<dataLength; i++){
							dataUrl = dataUrl + fArr_PolygonLayerName[i]+";";
						}
						dataUrl = dataUrl + "|";


						dataUrl = dataUrl + dataLength+"|";
						for (var i=0; i<dataLength; i++){
							dataUrl = dataUrl + fArr_Occupancy[i]+";";
						}
						dataUrl = dataUrl + "|";


						dataUrl = dataUrl + dataLength+"|";
						for (var i=0; i<dataLength; i++){
							dataUrl = dataUrl + fArr_Tags[i]+";";
						}
						dataUrl = dataUrl + "|";


						dataUrl = dataUrl + dataLength+"|";
						for (var i=0; i<dataLength; i++){
							dataUrl = dataUrl + fArr_Type[i]+";";
						}

						dataUrl = dataUrl + "|";

						var dataLength_fixtures = fArr_Name_fixtures.length;

						dataUrl = dataUrl + dataLength_fixtures+"|";                               // we are changing to RW-3
						for (var i=0; i<dataLength_fixtures; i++){
							dataUrl = dataUrl + fArr_Name_fixtures[i]+";";
						}
						dataUrl = dataUrl + "|";

						dataUrl = dataUrl + dataLength_fixtures+"|";
						for (var i=0; i<dataLength_fixtures; i++){
							dataUrl = dataUrl + fArr_Id_fixtures[i]+";";
						}
						dataUrl = dataUrl + "|";

						dataUrl = dataUrl + dataLength_fixtures+"|";
						for (var i=0; i<dataLength_fixtures; i++){
							dataUrl = dataUrl + fArr_PolygonNr_fixtures[i]+";";
						}
						dataUrl = dataUrl + "|";

						dataUrl = dataUrl + dataLength_fixtures+"|";
						for (var i=0; i<dataLength_fixtures; i++){
							dataUrl = dataUrl + fArr_PolygonLayerName_fixtures[i]+";";
						}
						dataUrl = dataUrl + "|";


						dataUrl = dataUrl + dataLength_fixtures+"|";
						for (var i=0; i<dataLength_fixtures; i++){
							dataUrl = dataUrl + fArr_Occupancy_fixtures[i]+";";
						}
						dataUrl = dataUrl + "|";


						dataUrl = dataUrl + dataLength_fixtures+"|";
						for (var i=0; i<dataLength_fixtures; i++){
							dataUrl = dataUrl + fArr_Tags_fixtures[i]+";";
						}
						dataUrl = dataUrl + "|";


						dataUrl = dataUrl + dataLength_fixtures+"|";
						for (var i=0; i<dataLength_fixtures; i++){
							dataUrl = dataUrl + fArr_Type_fixtures[i]+";";
						}

						dataUrl = dataUrl + "|";

//window.alert("RW-1 dataUrl="+dataUrl);

						//var finalUrl = overlay_data_url+'save-file-p2.php?file='+encodeURIComponent(tempstr + ".rw")+'&file_content='+encodeURIComponent(dataUrl);

						var finalUrl = overlay_data_url+'save-file-p2.php';

						var rw_data = {};
						rw_data['file'] = encodeURIComponent(tempstr + ".rw");
						rw_data['file_content'] = dataUrl;


						$.ajax({
						  url:finalUrl,
						  type: 'post',
						  data: rw_data,
						  success: function(html){
						  }  // end success

						});



						//  create a .js script file containing all edited objects and their reference data, save that back to server

						/*
						var buildings = {
							SPINNAKER_OFFICE_BUILDING: {
								name: "Spinnaker Office Building",
								company: "Redwood Systems",
								address: "181 Spinnaker Court",
								city: "Fremont",
								state: "CA",
								FacMgr: "admin@redwoodsys.com",
								floors: {
									ground : {
										name: "undefined",
										file: "spinnaker-1.dwf",
										rooms: {
											NODE_4: {
												name: "Westinghouse",
												id: 123,
												type: "Conference Room",
												},
											NODE_3: {
												name: "Westinghouse",
												id: 123,
												type: "Conference Room",
												},
											}
										},
									b1 : {
										name: "undefined",
										rooms: {}
										}
									}
							}

						}

						*/


						//window.alert("building header");

						// create the header         - see top of file for variable names

						dataUrl="";
						dataUrl = dataUrl +" var buildings = {\n";
						dataUrl = dataUrl +" 	 "+building_data_identifier+": {\n";
						dataUrl = dataUrl +"		name: \""+ building_name + "\",\n";
						dataUrl = dataUrl +"		company: \""+ company+"\",\n";
						dataUrl = dataUrl +"		address: \""+ address+"\",\n";
						dataUrl = dataUrl +"		city: \""+ city +"\",\n";
						dataUrl = dataUrl +"		state: \""+ state +"\",\n";
						dataUrl = dataUrl +"		zipcode: \""+ zipcode +"\",\n";
						dataUrl = dataUrl +"		country: \""+ country +"\",\n";
						dataUrl = dataUrl +"		FacMgr: \""+FacMgr_name+"\",\n";
						dataUrl = dataUrl +"		FacMgr_title: \""+FacMgr_title+"\",\n";
						dataUrl = dataUrl +"		FacMgr_email: \""+FacMgr_email+"\",\n";
						dataUrl = dataUrl +"		FacMgr_phone: \""+FacMgr_phone+"\",\n";
						dataUrl = dataUrl +"		floors: {\n";

						var str_x = current_selected_shortname;

						n_str = "space_"+str_x;    // 2013-04-08, prepend  "space_"

						n_str = n_str.replace(/[\|&;\$%@"<>\(\)\+?#,.]/g, "_");
// "
						n_str = n_str.replace(/ /g,"_");
						n_str = n_str.replace(/-/g,"_");

						vqfloor_name = n_str;

window.alert("vqfloor_name "+vqfloor_name);

						dataUrl = dataUrl +"			"+ vqfloor_name +" : {\n";
						dataUrl = dataUrl +"				name: \""+current_selected_shortname+"\",\n";
						dataUrl = dataUrl +"				file: \""+current_selected_filename+"\",\n";
						dataUrl = dataUrl +"				rooms: {\n";

						// make a loop over all spaces
								// write out the layers what are assocated with spaces
								// write the redwood id, space name

						var comma_flag =0;
//v3ZZZ
						for (spc in vqRooms)
						{
							if (vqRooms[spc].data("deleted") == true ){
								window.alert("file.js deleted node "+vqRooms[spc].data("node"));
							}
							else{  // node exists

								if (comma_flag == 0){
									comma_flag = 1
								}
								else{
									dataUrl = dataUrl +"						,\n";
								}

								dataUrl = dataUrl +"					"+vqRooms[spc].data("node")+": {\n";
								dataUrl = dataUrl +"						name: \""+vqRooms[spc].data("name")+"\",\n";

								if (isNaN(vqRooms[spc].data("id")))
									dataUrl = dataUrl +"						id: \""+vqRooms[spc].data("id")+"\",\n";
								else
									dataUrl = dataUrl +"						id: "+vqRooms[spc].data("id")+",\n";

								dataUrl = dataUrl +"						layer: \""+vqRooms[spc].data("layer")+"\",\n";
								dataUrl = dataUrl +"						group: \""+vqRooms[spc].data("group")+"\",\n";
								dataUrl = dataUrl +"						occupancy: \""+vqRooms[spc].data("occupancy")+"\",\n";
								dataUrl = dataUrl +"						type: \""+vqRooms[spc].data("type")+"\",\n";

								var str_2 = "{ ";
								var ii = 1;
								var c_flag = true;

								while (ii<10) {
									var tag_i = "tag"+ii;
//									if (vqRooms[spc].data(tag_i)!="undefined"){
									if ( typeof vqRooms[spc].data(tag_i)==='undefined'){
										// do nothing
									}
									else{
										// if the content is "undefined" then get rid of it also
										if (  vqRooms[spc].data(tag_i).toString().indexOf("undefined")==-1){
											if (c_flag){
												str_2 = str_2 +" "+ii+": \""+vqRooms[spc].data(tag_i)+"\"";
												c_flag=false;
											}
											else
												str_2 = str_2 +" ,"+ii+": \""+vqRooms[spc].data(tag_i)+"\"";

										}
									}
									ii++;
								}

								str_2 = str_2 +" }";
								dataUrl = dataUrl +"						tags:  "+str_2+", \n";
								dataUrl = dataUrl +"						attributes: [],\n";

								if (vqRooms[spc].data("linked") == true || vqRooms[spc].data("linked") == false )
									dataUrl = dataUrl +"						linked: "+vqRooms[spc].data("linked")+"\n";
								else
									dataUrl = dataUrl +"						linked: false \n";
								dataUrl = dataUrl +"					}\n";

							} // case node exists
						}

						// finish up the file

						dataUrl = dataUrl +"					}\n";
						dataUrl = dataUrl +"				}\n";
						dataUrl = dataUrl +"			}\n";
						dataUrl = dataUrl +"		}\n";
						dataUrl = dataUrl +"	}\n";


//  NOTE:  $j -> $
						dataUrl = dataUrl +"$(document).ready(function() {\n";
						dataUrl = dataUrl +"	floor_loaded = true;\n";
						dataUrl = dataUrl +"});\n";
						dataUrl = dataUrl +"floor_loaded = true;\n";



//window.alert(dataUrl);

						var finalUrl = overlay_data_url+'save-file-p3.php';

						var js_data = {};
						js_data['file'] = encodeURIComponent(tempstr + ".js");
						js_data['file_content'] = dataUrl;


						$.ajax({
						  url:finalUrl,
						  type: 'post',
						  data: js_data,
						  success: function(html){

// v3  - save -nodes.js file to server, then call process to copy all files over to /drawings ,  note that -thumb and -full are unchanged!

								dataUrl="";
								dataUrl = dataUrl +"var vqBuilding = \""+building_data_identifier+"\";\n";

//window.alert("2 vqfloor_name "+vqfloor_name);

								dataUrl = dataUrl +"var vqFloor = \""+ vqfloor_name +"\";\n";   // n_str -> vqFloor
								dataUrl = dataUrl +"var vqRooms = new Array(); \n";
								dataUrl = dataUrl +"var vqStickyNotes = new Array(); \n";
								dataUrl = dataUrl +"var vqRedlines = new Array(); \n";
								dataUrl = dataUrl +"var vqTBorder = new Array(); \n";
								dataUrl = dataUrl +"var vqText = new Array(); \n";
								dataUrl = dataUrl +"var vqURLs = new Array(); \n";
								dataUrl = dataUrl +"function drawPaths (paper){ \n";
								dataUrl = dataUrl +"\n";
								dataUrl = dataUrl +"vqRooms.length = 0;\n";
								dataUrl = dataUrl +"vqStickyNotes.length = 0;\n";
								dataUrl = dataUrl +"vqRedlines.length = 0;\n";
								dataUrl = dataUrl +"vqTBorder.length = 0;\n";
								dataUrl = dataUrl +"vqText.length = 0;\n";
								dataUrl = dataUrl +"vqURLs.length = 0;\n";
								dataUrl = dataUrl +"\n";

								var citem = "cItem";
								spc_counter = 0;
								for (spc in vqRooms)
								{
									if (vqRooms[spc].data("deleted") == true ){
										window.alert(" -nodes.js deleted node "+vqRooms[spc].data("node"));
									}
									else{  // node exists

										spc_counter++;
										var item = "cItem"+spc_counter;
										var str_object = vqRooms[spc].toString();

										if (str_object.indexOf("path")>-1){
											str_object = str_object.substring(str_object.indexOf("d=")+3);
											str_object = str_object.substring(0, str_object.indexOf('\"'));
											//window.alert(str_object);
											dataUrl = dataUrl +"var "+item+"= paper.path(\"";
											dataUrl = dataUrl +str_object+" \")\n.data(\"node\",\""+vqRooms[spc].data("node")+"\");\n";
											dataUrl = dataUrl +"vqRooms.push("+item+");\n\n";
										}
										else{//v3www
											if (str_object.indexOf("circle")>-1){

												var p_cx = str_object.indexOf(" cx=");
												var s1_cx = str_object.substring(p_cx+5);
												var p2_cx = s1_cx.indexOf("\"");
												cx = s1_cx.substring(0, p2_cx)

												var p_cy = str_object.indexOf(" cy=");
												var s1_cy = str_object.substring(p_cy+5);
												var p2_cy = s1_cy.indexOf("\"");
												cy = s1_cy.substring(0, p2_cy)

												var p_r = str_object.indexOf(" r=");
												var s1_r = str_object.substring(p_r+4);
												var p2_r = s1_r.indexOf("\"");
												r = s1_r.substring(0, p2_r)

												dataUrl = dataUrl +"var "+item+"= paper.circle("+cx+","+cy+","+r+","+r+")";
												dataUrl = dataUrl +"\n.data(\"node\",\""+vqRooms[spc].data("node")+"\");\n";
												dataUrl = dataUrl +"vqRooms.push("+item+");\n\n";
											}
											else
												window.alert("note: not path, not circle, ..save not implemented! "+str_object);

										}

									}
								}

								dataUrl = dataUrl +"}\n";
								dataUrl = dataUrl +"$(document).ready(function() {\n";
								dataUrl = dataUrl +"	nodes_loaded = true;\n";
								dataUrl = dataUrl +"});\n";
								dataUrl = dataUrl +"nodes_loaded = true;\n";


								var saveDwfUrl = overlay_dwf_data_url+'save-file-p1.php';

								js_data = {};
								js_data['file'] = encodeURIComponent(tempstr + "-nodes.js");
								js_data['file_content'] = dataUrl;

								$.ajax({
								  url:saveDwfUrl,
								  type: 'post',
								  data: js_data,
								  success: function(html){

								  // v3 here we call the process file

										var exec_data = {};

										exec_data['file_name'] = encodeURIComponent(tempstr);
										exec_data['dest_file_name'] = tempstr;

										var saveDwfUrl_runprocess3 = overlay_dwf_data_url+'run-process-p5.php';

										$.ajax({
										  url:saveDwfUrl_runprocess3,
										  type: 'post',
										  data: exec_data,
										  success: function(html2){

window.alert("copying .js files over to /drawings "+html2);

											$('#IconMenuPanel').css("filter", "alpha(opacity=100)");
											// filter:alpha(opacity=50);
											$('#IconMenuPanel').css("opacity", "1.0");
											// 	opacity:0.5;

											// $("#wait_looper").fadeOut(500);


											//$("#loadpane_small").hide();

											$("#savepane_small").hide();

											// unblock interaction!!!
											wait_looper_on = 0;


										  }  // end success

										});


						// end DWF loop
								  }  // end success

								});


//v3
//v3
//v3



//window.alert("C1: make save button gray");


						// make the save button gray
						//$('#save_drawing').css('background', '	#DDDDDD'); //	#CCCCFF   #EEEEEE
						//$('#save_drawing').css('color', 'black');
						$('#save_drawing_image').attr("src", "../images_modal/tools/SaveChanges_240x22_Inactive.png");


						save_drawing_flag = 0;


						// if the Select button is active, then we need to color the select polygon correctly again

						if (  icon_command_active == 6){

							var j = -1;

		//window.alert("selectedLinkUnlinkLayer="+selectedLinkUnlinkLayer);

							if (selectedLinkUnlinkLayer.indexOf("NODE_")>=0){

								for (var i=0;i<fArr_Name.length;i++)
								{
									if (fArr_PolygonLayerName[i].indexOf(selectedLinkUnlinkLayer)>=0){
										j = i;  // bingo, the layer is actually linked
									}
								}

								for (var i=0;i<fArr_Name_fixtures.length;i++)
								{
									if (fArr_PolygonLayerName_fixtures[i].indexOf(selectedLinkUnlinkLayer)>=0){
										j = i;  // bingo, the layer is actually linked
									}
								}


							}
		//window.alert("j="+j);

							if (j>-1){
								// the layer is linked therefore it must be colored in select green
								// color the space back to the selection tool color
//								document.applets[0].FillPolylineOnLayer(selectedLinkUnlinkLayer, 0, 65, 164, 88, alpha_value, polygon_order, clean_polygon_space);
								document.applets[0].FillPolylineOnLayer(selectedLinkUnlinkLayer, 0, select_link_r, select_link_g, select_link_b, alpha_value, polygon_order, clean_polygon_space);

								document.applets[0].Redraw();
							}
							else{
								// color the space back to the selection tool color - unselect green
//								document.applets[0].FillPolylineOnLayer(selectedLinkUnlinkLayer, 0, 141, 192, 47,alpha_value, polygon_order, clean_polygon_space);
								document.applets[0].FillPolylineOnLayer(selectedLinkUnlinkLayer, 0, select_no_link_r, select_no_link_g, select_no_link_b, alpha_value, polygon_order, clean_polygon_space);

								document.applets[0].Redraw();
							}

						}







// the two .js files are now copied over to /drawings, so we can now make the save button gray




//window.alert("after save overlay is done!");






						// TEST  - Save DWF with all entities  - done with CV's GetSaveDwfFormat() method







						  }  // end success save <file>.js

						});







					//window.alert("after the polygon has been colored");




					// bookkeeping

					// call   AX with the .js file above as parameter, then input file as parameter, and output a .js file to the
					//  /drawings directory containg the merged information to be used for the display mechanism


					// AX

					// <?php
					// outputs the username that owns the running php/httpd process
					// (on a system with the "whoami" executable in the path)
					// x echo exec('path/whoami  all parameters ',$trace);
					// print trace
					// ?>
					//




				}   // end of save_drawing_flag conditional statement


			});
// SAVE DRAWING - END




// UNLINK LOCATION - BEGIN

		$('#unlink_location').mousedown(function()
			{


				// remove this layer from the space allocation list
				for (var i=0;i<fArr_Name.length;i++)
				{
					if (fArr_PolygonLayerName[i] == selectedLinkUnlinkLayer){
						fArr_PolygonNr[i] = -1;
						fArr_PolygonLayerName[i] = "none";
						fArr_Type[i] = -1;
						fArr_Occupancy[i] = -1;
						fArr_Tags[i] = -1;
					}
				}

				for (var i=0;i<fArr_Name_fixtures.length;i++)
				{
					if (fArr_PolygonLayerName_fixtures[i] == selectedLinkUnlinkLayer){
						fArr_PolygonNr_fixtures[i] = -1;
						fArr_PolygonLayerName_fixtures[i] = "none";
						fArr_Type_fixtures[i] = -1;
						fArr_Occupancy_fixtures[i] = -1;
						fArr_Tags_fixtures[i] = -1;
					}
				}


				// update the space list table
				generate_new_linkList();
				generate_new_linkList_fixtures();


				// update the hyperlink information on the polygon on the drawing

				var tempstr = selectedLinkUnlinkLayer.substring(5);
				// window.alert(tempstr);
				var scriptCode = "officeclick('"+tempstr+"')";
				var userFriendlyName = "Object "+tempstr;

				// use the selection space colors for this shape
				// color the space back to the selection tool color

				for (spc in vqRooms)
				{
					if (vqRooms[spc].data("id") == currentSelectedId) {
						var node = vqRooms[spc].data("node");
						//window.alert("node="+node);
						var linkId = node.substring(node.lastIndexOf("NODE_")+5);
						cvjs_overwriteNodeValues( node, node, "unassigned_"+linkId, "unassigned", "unassigned", "unassigned", "unassigned", "unassigned", "unassigned", false);
						cvjs_redrawPop();
					}
				}

				// now we have to update the select tool with the new information


				//   call linkmethod to select any type of shape

//window.alert("done unlink!");


				// we set the text field of the space selector to "none selected"
				//$("#drop_link_spaces").html('None Selected'+'<b class="caret"></b>');
				// all_icons_up();

				// make it gray, since the space is now unlinked
				$('#unlink_location').css('color', '#999999');

				// clear the fields since the space is now unlinked
				// dynamic page
				$("#drop_link_spaces").html('None Selected'+'<b class="caret"></b>');
				$("#drop_link_fixtures").html('None Selected'+'<b class="caret"></b>');
				$("#type_tag").val(" ");
				$("#layer_tag").val(" ");
				$("#occupancy_tag").val(" ");
				$("#other_tags").val(" ");

				// static page
				$("#location_s").html("None Selected");
				$("#type_s").html("-");
				$("#occupancy_s").html("-");
				$("#tags_s").html("-");
				$("#layer_s").html("-");


				// make the save field green
				// make the save drawing button green
			    //$('#save_drawing').css('background', '#45AC5C');
			    //$('#save_drawing').css('color', 'white');
			    $('#save_drawing_image').attr("src", "../images_modal/tools/SaveChanges_240x22_Up.png");

			    save_drawing_flag = 1;

				$("#cvjs_IconMenuPanel").height(216);

				$("#location_text_static").hide();
				$("#location_text_dynamic").hide();


			});

// UNLINK LOCATION - END





// DONE EDITING LOCATION - BEGIN

		$('#done_editing_location').mousedown(function()
			{
				var polygonNumberFromDrawing = currentLinkId;    // we must find the polygon number from drawing

				var userFriendlyName = "";
				var scriptName = "";

				// loop over i, find the index where the currentLinkId match, that index is being updated
				for (var i=0;i<fArr_Name.length;i++)
				{
					if (fArr_Id[i] == currentLinkId){
//						window.alert("index in array:"+i);
						fArr_PolygonNr[i] = polygonNumberFromDrawing;
						fArr_PolygonLayerName[i] = selectedLinkUnlinkLayer;

						userFriendlyName = fArr_Name[i];

						fArr_Type[i] = $('#type_tag').val();
						fArr_Layer[i] = $('#layer_tag').val();

						for (spc in vqRooms)
						{
							if (vqRooms[spc].data("id") == fArr_Id[i] ){
								vqRooms[spc].removeData("layer");
								vqRooms[spc].data("layer", $('#layer_tag').val())
								$("#layer_s").html(vqRooms[spc].data("layer"));
							}
						}

						fArr_Occupancy[i] = $('#occupancy_tag').val();
						fArr_Tags[i] = $('#other_tags').val();

						// static page
						$("#location_s").html(fArr_Name[i]);
						$("#type_s").html(fArr_Type[i]);
						$("#occupancy_s").html(fArr_Occupancy[i]);
						$("#tags_s").html(fArr_Tags[i]);


					}
				}



				for (var i=0;i<fArr_Name_fixtures.length;i++)
				{
					if (fArr_Id_fixtures[i] == currentLinkId){
						//window.alert("fArr_PolygonNr_fixtures updated index in array:"+i+"  polygonNumberFromDrawing="+polygonNumberFromDrawing);
						fArr_PolygonNr_fixtures[i] = polygonNumberFromDrawing;
						fArr_PolygonLayerName_fixtures[i] = selectedLinkUnlinkLayer;


						if (fArr_Name_fixtures[i] == "")
							userFriendlyName = fArr_Id_fixtures[i];
						else
							userFriendlyName = fArr_Name_fixtures[i];

						//userFriendlyName = fArr_Name_fixtures[i];


						fArr_Type_fixtures[i] = $('#type_tag').val();
						fArr_Layer_fixtures[i] = $('#layer_tag').val();

						for (spc in vqRooms)
						{
							if (vqRooms[spc].data("id") == fArr_Id_fixtures[i]){
								vqRooms[spc].removeData("layer");
								vqRooms[spc].data("layer", $('#layer_tag').val())
								$("#layer_s").html(vqRooms[spc].data("layer"));
							}
						}

						fArr_Occupancy_fixtures[i] = $('#occupancy_tag').val();
						fArr_Tags_fixtures[i] = $('#other_tags').val();;

//window.alert("XX"+fArr_Occupancy[i]+"  "+fArr_Tags[i]+"XX");


						// static page

						if (fArr_Name_fixtures[i] == "")
							$("#location_s").html(fArr_Id_fixtures[i]);
						else
							$("#location_s").html(fArr_Name_fixtures[i]);

						$("#type_s").html(fArr_Type_fixtures[i]);
						$("#occupancy_s").html(fArr_Occupancy_fixtures[i]);
						$("#tags_s").html(fArr_Tags_fixtures[i]);


					}
				}


				// we update the list with available spaces,
				generate_new_linkList();
				generate_new_linkList_fixtures();


				// we color the corresponding space on the drawing "polygonNumberFromDrawing" with a different color
				//window.alert("before LinkShape layer="+selectedLinkUnlinkLayer+" currentLinkId="+currentLinkId);
				scriptCode =  "officeclick('"+currentLinkId+"')";
				// color the space back to the selection tool color


				for (spc in vqRooms)
				{
					if (vqRooms[spc].data("id") == currentSelectedId) {
						var node = vqRooms[spc].data("node")
//window.alert("node "+node+"   "+$('#layer_tag').val());
						cvjs_setCurrentNodeValuesFromExistingNode(node);
						cvjs_overwriteNodeValues( node, currentLinkId, userFriendlyName, $('#layer_tag').val(), cvjs_currentNode_group, cvjs_currentNode_attributes, $('#type_tag').val(), cvjs_currentNode_tags, $('#occupancy_tag').val(), true);
						//cvjs_clearDrawing();
						//cvjs_redrawViewBox();
						cvjs_redrawPop();
					}
				}

				// and reset set the variable
				// currentLinkId = -1;    // no only changed with new selection

				// we drop this... set the text field of the space selector to "none selected"
				// $("#drop_link_spaces").html('None Selected'+'<b class="caret"></b>');

				// we clear the icon menu and reset the selected command
				// This is changed, since select is permanently on
				// icon_command_active = 0;
				// all_icons_up();

				$('#unlink_location').html("Unlink Location");
				// make it blue, since the space is linked
				$('#unlink_location').css('color', '#0096d7');


				$('#done_editing_location').html("");
				$('#edit_cancel_location').html("Edit Fields");
				edit_cancel_flag = false;


				//  switch to static page
				$("#location_text_static").show();
				$("#location_text_dynamic").hide();


				$("#cvjs_IconMenuPanel").height(400);


				// make the save field green
				save_drawing_flag = 1;

				// make the save drawing button green
			    //$('#save_drawing').css('background', '#45AC5C');
			    //$('#save_drawing').css('color', 'white');
				$('#save_drawing_image').attr("src", "../images_modal/tools/SaveChanges_240x22_Up.png");



				// now we have to update the select tool with the new information

				// v3 document.applets[0].TurnOffLinkShapes();
				//cvjs_hidePop();


				//   call linkmethod to select any type of shape

//window.alert("done editing!");

			});



// DONE EDITING LOCATION - END





// EDIT CANCEL LOCATION - BEGIN

		$('#edit_cancel_location').mousedown(function()
			{

			 if (edit_cancel_flag == false){

				//ZZZZ $('body').css('overflow', 'scroll');  // make scroll mode to be able to select from location list

			 	// we are pressing the edit cancel button to enter edit mode
			 	$('#edit_cancel_location').html("Cancel");
			 	$('#done_editing_location').html("Done Editing");
			 	$('#unlink_location').html("");


				//  switch to dynamic page
				$("#location_text_static").hide();
				$("#location_text_dynamic").show();

				$("#cvjs_IconMenuPanel").height(426);


				//cvjs_hidePop();


			 	edit_cancel_flag = true;

			 }else{

			 	// we are in cancel mode and want to revert to init mode
			 	$('#edit_cancel_location').html("Edit Fields");
			 	$('#done_editing_location').html("");
			 	$('#unlink_location').html("Unlink Location");



				//  switch to static page
				$("#location_text_static").show();
				$("#location_text_dynamic").hide();

				$("#cvjs_IconMenuPanel").height(400);

				// turn on LinkShapes



				//   call linkmethod to select any type of shape


//window.alert("edit_cancel_location");

			 	edit_cancel_flag = false;

			 }

				// old stuff
				// color the selected layer in the color it had before selection
				// reset_color_on_selected_space();
				// all_icons_up();
				// do nothing with the save field


			});



// EDIT CANCEL LOCATION  - END



	});

// END - READY


  $(function() {
    $("#cvjs_IconMenuPanel").draggable();
//    $("#savelinksHeaderTable").draggable();
  });



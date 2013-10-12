	var viewportWidth;
	var viewportHeight;
	var departure_time1 = "00:00";
	var departure_time2 = "00:00";
	
	var show=new Object(); // if we are showing a specific tab when opened
	
	if (typeof window.innerWidth != 'undefined') {viewportWidth=window.innerWidth;viewportHeight=window.innerHeight;}
	else if (typeof document.documentElement != 'undefined' && typeof document.documentElement.clientWidth != 'undefined' && typeof document.documentElement.clientWidth != 0)
	{viewportWidth=document.documentElement.clientWidth;viewportHeight=document.documentElement.clientHeight;}
	else {viewportWidth=document.getElementsByTagName('body')[0].clientWidth;viewportHeight=document.getElementsByTagName('body')[0].clientHeight}
	
	function numProperties(object) {
		var count=0;
		for (var i in object) {
			count++;
		}
		return count;
	}
	function showHide(id) {
		if (document.getElementById(id).style.display == "none") {
			document.getElementById(id).style.display="";
		} else {
			document.getElementById(id).style.display="none";
		}
	}
	
	function makeInfoboxHTML(type, i) {
		var text;
		if (type == "driver") {
			var address=drivers[i]['address1'];
			address+=(drivers[i]['address2'] != '')?"<br />"+drivers[i]['address2']:'';
			address+="<br />"+drivers[i]['city']+", "+drivers[i]['state']+" "+drivers[i]['zip'];
			text="<h4>"+drivers[i]['name']+" (Driver) ("+numProperties(drivers[i]['riders'])+"/"+drivers[i]['number_passengers']+")</h4>"+address+"<br />";
			text+="<b>Departure Time:</b> "+drivers[i]['depart_time_nice']+"<br />";
			text+=(drivers[i]['special_info'] != '')?"<b>Special Info:</b> "+drivers[i]['special_info']+"<br />":'';
			text+="<a href='/carpool/register/"+i+"'>Update Information</a> | ";
			text+=(i == current_driver)?"<a href='javascript:unsetCurrentDriver();'>Unselect Driver</a>":"<a href='javascript:setCurrentDriver("+i+");'>Select Driver</a>";
			drivers[i]['infobox']=text;
		} else {
			var address=riders[i]['address1'];
			address+=(riders[i]['address2'] != '')?riders[i]['address2']:'';
			address+="<br />"+riders[i]['city']+", "+riders[i]['state']+" "+riders[i]['zip'];
			text="<h4>"+riders[i]['name']+" (Rider)</h4>"+address+"<br />";
			text+="<b>Departure Time:</b> "+riders[i]['depart_time_nice']+"<br />";
			text+=(riders[i]['special_info'] != '')?"<b>Special Info:</b> "+riders[i]['special_info']+"<br />":'';
			text+="<a href='/carpool/register/"+i+"'>Update Information</a>";
			text+=(riders[i]['driverID'] == 0 && current_driver != -1 && numProperties(drivers[current_driver]['riders']) < drivers[current_driver]['number_passengers'])?" | <a href='javascript:addRider("+i+");'>Add to Car</a>":'';
			text+=(riders[i]['driverID'] != 0)?" | <a href='javascript:removeRider("+i+");'>Remove from Car</a> | <a href='javascript:findDriver("+i+");'>Find Driver</a>":'';
			riders[i]['infobox']=text;
		}
		return text;
	}
	
	function getIcon(type, i) {
		if (type == "driver") {
			if (current_driver == i) {
				return "/images/S_AD.png";
			} else if (numProperties(drivers[i]['riders']) < drivers[i]['number_passengers']) {
				return "/images/AD.png";
			} else {
				return "/images/UD.png";
			}
		} else {
			if (current_driver == riders[i]['driverID']) {
				return "/images/S_AR.png";
			} else if (riders[i]['driverID'] == 0) {
				return "/images/AR.png";
			} else {
				return "/images/UR.png";
			}
		}
	}
	
	function updateMarkers() {
		var AR;
		var AD;
		var UR;
		var UD;
		var selected;
		var id;
		var type;
		for (var i in locations) {
			AR=AD=UR=UD=selected=false;
			tabs=new Array();
			for (var j=0;j<locations[i]['rides'].length;j++) {
				id=locations[i]['rides'][j]['id'];
				type=locations[i]['rides'][j]['type'];
				if ((type == "driver" && drivers[id]['show']) || (type == "rider" && riders[id]['show'])) {
					if (type == "driver" && numProperties(drivers[id]['riders']) < drivers[id]['number_passengers']) {
						if (id == current_driver) {
							selected=true;
						}
						AD=true;
					} else if (type == "driver") {
						if (id == current_driver) {
							AD=true;
							selected=true;
						} else {
							UD=true;
						}
					} else if (type == "rider" && riders[id]['driverID'] == 0) {
						AR=true;
					} else if (type == "rider") {
						if (riders[id]['driverID'] == current_driver) {
							AR=true;
							selected=true;
						} else {
							UR=true;
						}
					}
				}
			}
			var image='';
			if (selected) {
				image+='S_';
			}
			if (AD) {
				image+='AD_';
			}
			if (AR) {
				image+='AR_';
			}
			if (UD) {
				image+='UD_';
			}
			if (UR) {
				image+='UR_';
			}
			
			if (image != '') {
				locations[i]['marker'].setImage("/images/"+image.substring(0, image.length-1)+".png");
			}
			locations[i]['marker'].bindInfoWindowHtml(getMarkerHTML(i), {'maxWidth': 400, 'maxHeight':300, 'autoScroll':true});
			var k;
			for (var j=0;j<locations[i]['rides'].length;j++) {
				id=locations[i]['rides'][j]['id'];
				if (locations[i]['rides'][j]['type'] == "driver") {
					if (drivers[id]['show']) {
						k=id;
						break;
					}
				} else {
					if (riders[id]['show']) {
						k=id;
						break;
					}
				}
			}
			show[i]=k;
		}
	}
	
	function updateRidersDone() {
		var count=0;
		for (var i in riders) {
			if (riders[i]['driverID'] != 0) {
				count++;
			}
		}
		document.getElementById("spaces_remaining").innerHTML=spaces-count;
		document.getElementById("riders_remaining").innerHTML=riders_size-count;
	}
	
	function getMarkerHTML(i) {
		var longestHTML='';
		var longestHTMLSize=0;
		var tabs=Array();
		var html;
		var name;
		var tabsHTML;
		var id;
		var show=true;
		for (var j=0,k=0;j<locations[i]['rides'].length;j++) {
			id=locations[i]['rides'][j]['id'];
			if (locations[i]['rides'][j]['type'] == "driver") {
				if (drivers[id]['show']) {
					name=drivers[id]['name'];
					html=makeInfoboxHTML('driver', id);
					show=true;
				} else {
					show=false;
				}
			} else {
				if (riders[id]['show']) {
					name=riders[id]['name'];
					html=makeInfoboxHTML('rider', id);
					show=true;
				} else {
					show=false;
				}
			}
			if (show) {
				tabs[k]={type:locations[i]['rides'][j]['type'], id:id, name:name, html:html};
				k++;
				document.getElementById("size_box").innerHTML=html;
				if (document.getElementById("size_box").offsetHeight > longestHTMLSize) {
					longestHTML=html;
					longestHTMLSize=document.getElementById("size_box").offsetHeight;
				}
			}
		}
		html='';
		tabsHTML='<h4>People at this address:</h4>';
		for (var j=0;j<tabs.length;j++) {
			if (tabs.length > 1) {
				tabsHTML+=(tabsHTML.length != 0)?' | ':'';
				if (tabs[j]['type'] == "driver") {
					id=tabs[j]['id'];
					tabsHTML+="<img src='"+getIcon(tabs[j]['type'], tabs[j]['id'])+"' style='width:16px;height:16px;' /><a href='javascript:markerShow(\""+i+"\","+tabs[j]['id']+");' ondblclick=\"double_click_driver("+id+");return false;\">"+tabs[j]['name']+" ("+numProperties(drivers[id]['riders'])+"/"+drivers[id]['number_passengers']+")</a>";
				} else {
					id=tabs[j]['id'];
					tabsHTML+="<img src='"+getIcon(tabs[j]['type'], tabs[j]['id'])+"' style='width:16px;height:16px;' /><a href='javascript:markerShow(\""+i+"\","+tabs[j]['id']+");' ondblclick=\"double_click_rider("+id+");return false;\">"+tabs[j]['name']+"</a>";
				}
			}
			html+="<div id='marker"+tabs[j]['id']+"' class='marker_main' style='display:none;'>"+tabs[j]['html']+"</div>";
		}
		html+="<div id='marker_longest'>"+longestHTML+"</div>"; // force the box to render for the largest "tab" we have
		return (tabs.length > 1)?"<div class='marker_tabs'>"+tabsHTML+"</div>"+html:html;
	}
	
	function limitHeight(id, max) {
		var element=document.getElementById(id);
		if (element.offsetHeight > max) {
			element.style.height=max+"px";
			element.style.overflow="auto";
		}
	}
	
	function onMarkerOpen(i) {
		document.getElementById("marker_longest").style.display="none";
		document.getElementById("marker"+show[i]).style.display="block";
		//limitHeight("marker"+show[i], 300);
	}
	
	function showMarker(i, id) {
		show[i]=id;
		locations[i]['marker'].openInfoWindowHtml(getMarkerHTML(i), {'maxWidth': 400, 'maxHeight':300, 'autoScroll':true});
	}
	
	function markerShow(i, id) {
		var id2;
		for (var j=0;j<locations[i]['rides'].length;j++) {
			id2=locations[i]['rides'][j]['id'];
			if ((locations[i]['rides'][j]['type'] == "driver" && drivers[id2]['show']) || (locations[i]['rides'][j]['type'] == "rider" && riders[id2]['show'])) {
				document.getElementById("marker"+id2).style.display="none";
			}
		}
		document.getElementById("marker"+id).style.display="block";
		//limitHeight("marker"+id, 300);
	}
	
	function count_shown(arr) {
		var i=0;
		for (var j=0;j<arr.length;j++) {
			var id = arr[j]['id'];
			if (arr[j]['type'] == "driver") {
				if (drivers[id]['show']) {
					i++;
				}
			} else {
				if (riders[id]['show']) {
					i++;
				}
			}
		}
		return i;
	}
	
	function find_first_shown(arr) {
		var ret = new Array(2);
		for (var j=0;j<arr.length;j++) {
			var id=arr[j]['id'];
			ret[1] = id;
			if (arr[j]['type'] == "driver") {
				if (drivers[id]['show']) {
					ret[0] = "driver";
					return ret;
				}
			} else {
				if (riders[id]['show']) {
					ret[0] = "rider";
					return ret;
				}
			}
		}
	}
	
	function double_click_location(i) {
		if (count_shown(locations[i]['rides']) == 1) {
			ret = find_first_shown(locations[i]['rides']);
			if (ret[0] == "driver") {
				setCurrentDriver(ret[1]);
			} else {
				if (current_driver != -1) {
					addRider(ret[1]);
				}
			}
		} else {
			return false;
		}
	}
	
	function double_click_driver(i) {
		setCurrentDriver(i);
	}
	
	function double_click_rider(i) {
		if (current_driver != -1) {
			addRider(i);
		}
	}
	
	function findDriver(i) {
		var id=riders[i]['driverID'];
		map.setCenter(drivers[id]['marker'].getLatLng(), 14);
		showMarker(drivers[id]['location'], id);
	}
	
	function doZIndex(marker) {
		return marker.zIndex;
	}
	
	function displayMessage(name) {
		map.disableScrollWheelZoom();
		document.getElementById("message_block").style.display="block";
		var msg=document.getElementById(name+"_message");
		msg.style.display="block";
		msg.style.position="absolute";
		if (typeof msg.style.height == 'undefined' || typeof msg.style.width == 'undefined') {
			var start=30;
			msg.style.left=msg.style.right="30%";
			while (msg.offsetHeight > msg.offsetWidth*.6) {
				start--;
				if (start <= 4) {
					msg.style.left=msg.style.right="25px";
					break;
				}
				msg.style.left=msg.style.right=start+"%";
			}
			msg.style.top=msg.style.bottom=(viewportHeight-msg.offsetHeight > 0)?(viewportHeight-msg.offsetHeight)/2+"px":"25px";
		} else {
			msg.style.left=msg.style.right=(viewportWidth-msg.offsetWidth > 0)?(viewportWidth-msg.offsetWidth)/2+"px":"25px";
			msg.style.top=msg.style.bottom=(viewportHeight-msg.offsetHeight > 0)?(viewportHeight-msg.offsetHeight)/2+"px":"25px";
		}
	}
	
	function hideMessage(name) {
		map.enableScrollWheelZoom();
		document.getElementById(name+"_message").style.display="none";
		document.getElementById("message_block").style.display="none";
	}
	
	function empty(id) {
		var element=document.getElementById(id);
		if (element.hasChildNodes()) {
			while (element.childNodes.length >= 1) {
				element.removeChild(element.firstChild);       
			} 
		}
		element.style.display="none";
	}
	
	function prependChild(parent, node) {
		parent.insertBefore(node, parent.firstChild);
	}
	
	/*var update_address_storage_type;
	var update_address_storage_i;
	function updateAddress(type, i) {
		var info;
		if (type == "driver") {
			info=drivers[i];
		} else {
			info=riders[i];
		}
		document.getElementById("update_address_name").innerHTML=info['name']
		document.getElementById("update_address_address1").value=info['address1'];
		document.getElementById("update_address_address2").value=info['address2'];
		document.getElementById("update_address_city").value=info['city'];
		document.getElementById("update_address_state").value=info['state'];
		document.getElementById("update_address_zip").value=info['zip'];
		document.getElementById("update_address_rideID").value=info['id'];
		update_address_storage_type=type;
		update_address_storage_i=i;
		displayMessage("update_address");
	}
	
	function updateAddressCallback(request) {
		i=update_address_storage_i;
		latlng=request.responseText.split(',');
		var location=latlng[0]+" "+latlng[1];
		var next;
		if (location in locations) {
			locations[location]['rides'].push({'type':update_address_storage_type, 'id':update_address_storage_i});
			next=locations[location];
		} else {
			locations[location]['latitude']=latlng[0];
			locations[location]['longitude']=latlng[1];
			locations[location]['rides'][0]={'type':update_address_storage_type, 'id':update_address_storage_i};
			locations[location]['marker']=new GMarker(new GLatLng(latlng[0], latlng[1]), {title: (update_Address_storage_type == "driver")?drivers[i]['name']:riders[i]['name'], zIndexProcess: doZIndex, icon: icon});
			next=locations[location];
		}
		if (update_address_storage_type == "driver") {
			drivers[i]['address1']=document.getElementById("update_address_address1").value;
			drivers[i]['address2']=document.getElementById("update_address_address2").value;
			drivers[i]['city']=document.getElementById("update_address_city").value;
			drivers[i]['state']=document.getElementById("update_address_state").value;
			drivers[i]['zip']=document.getElementById("update_address_zip").value;
			drivers[i]['marker'].closeInfoWindow();
			drivers[i]['marker']=next['marker'];
			drivers[i]['location']=location;
		} else {
			riders[i]['address1']=document.getElementById("update_address_address1").value;
			riders[i]['address2']=document.getElementById("update_address_address2").value;
			riders[i]['city']=document.getElementById("update_address_city").value;
			riders[i]['state']=document.getElementById("update_address_state").value;
			riders[i]['zip']=document.getElementById("update_address_zip").value;
			riders[i]['marker'].closeInfoWindow();
			riders[i]['marker']=next['marker'];
			riders[i]['location']=location;
		}
		updateMarkers();
		hideMessage("update_address");
	}*/
	
	var lastOption="";
	function showOption(name) {
		// close all others
		document.getElementById("options_box_departure_time").style.display="none";
		//document.getElementById("options_box_special_cases").style.display="none";
		document.getElementById("options_box_availability").style.display="none";
		// reset borders
		if (document.getElementById("options_box_departure_time_use1").checked == 1 || document.getElementById("options_box_departure_time_use2").checked == 1) {
			document.getElementById("options_departure_time").style.backgroundColor="#bbffbb";
		} else {
			document.getElementById("options_departure_time").style.backgroundColor="#ffffff";
		}
		/*if (document.getElementById("options_box_special_cases_show_special").checked != 1 || document.getElementById("options_box_special_cases_show_standard").checked != 1) {
			document.getElementById("options_special_cases").style.backgroundColor="#bbffbb";
		} else {
			document.getElementById("options_special_cases").style.backgroundColor="#ffffff";
		}*/
		if (document.getElementById("options_box_availability_available").checked != 1 || document.getElementById("options_box_availability_assigned").checked != 1) {
			document.getElementById("options_availability").style.backgroundColor="#bbffbb";
		} else {
			document.getElementById("options_availability").style.backgroundColor="#ffffff";
		}
		if (lastOption != name) {
			// open the one we want
			document.getElementById("options_box_"+name).style.display="block";
			// no top border on the one we want
			document.getElementById("options_"+name).style.backgroundColor="#eeeeee";
			// keep track of last one
			lastOption=name;
		} else {
			lastOption=""; // so toggling works right
		}
	}
	
	// Helper functions for options boxes
	function closeDepartureTime() {
		document.getElementById("options_box_departure_time").style.display="none";
		if (document.getElementById("options_box_departure_time_use1").checked == 1 || document.getElementById("options_box_departure_time_use2").checked == 1) {
			document.getElementById("options_departure_time").style.backgroundColor="#bbffbb";
		} else {
			document.getElementById("options_departure_time").style.backgroundColor="#ffffff";
		}
		lastOption="";
	}
	/*function closeSpecialCases() {
		document.getElementById("options_box_special_cases").style.display="none";
		if (document.getElementById("options_box_special_cases_show_special").checked != 1 || document.getElementById("options_box_special_cases_show_standard").checked != 1) {
			document.getElementById("options_special_cases").style.backgroundColor="#bbffbb";
		} else {
			document.getElementById("options_special_cases").style.backgroundColor="#ffffff";
		}
		lastOption="";
	}*/
	function closeAvailability() {
		document.getElementById("options_box_availability").style.display="none";
		if (document.getElementById("options_box_availability_available").checked != 1 || document.getElementById("options_box_availability_assigned").checked != 1) {
			document.getElementById("options_availability").style.backgroundColor="#bbffbb";
		} else {
			document.getElementById("options_availability").style.backgroundColor="#ffffff";
		}
		lastOption="";
	}
	function updateList() {
		var time1=departure_time1;
		var time2=departure_time2;
		var use1=document.getElementById("options_box_departure_time_use1").checked;
		var use2=document.getElementById("options_box_departure_time_use2").checked;
		if (use1 == 1 || use2 == 1) {
			document.getElementById("options_departure_time").style.backgroundColor=(lastOption == "departure_time")?"#eeeeee":"#bbffbb";
		} else {
			document.getElementById("options_departure_time").style.backgroundColor=(lastOption == "departure_time")?"#eeeeee":"#ffffff";
		}
		if (document.getElementById("options_box_availability_available").checked != 1 || document.getElementById("options_box_availability_assigned").checked != 1) {
			document.getElementById("options_availability").style.backgroundColor=(lastOption == "availability")?"#eeeeee":"#bbffbb";
		} else {
			document.getElementById("options_availability").style.backgroundColor=(lastOption == "availability")?"#eeeeee":"#ffffff";
		}
		/*if (document.getElementById("options_box_special_cases_show_special").checked != 1 || document.getElementById("options_box_special_cases_show_standard").checked != 1) {
			document.getElementById("options_special_cases").style.backgroundColor=(lastOption == "special_cases")?"#eeeeee":"#bbffbb";
		} else {
			document.getElementById("options_special_cases").style.backgroundColor=(lastOption == "special_cases")?"#eeeeee":"#ffffff";
		}*/
		for (var i in riders) {
			document.getElementById("rider"+i).style.display="block";
			riders[i]['show']=true;
		}
		for (var i in drivers) {
			document.getElementById("driver"+i).style.display="block";
			drivers[i]['show']=true;
		}
		if (use1 == 1 || use2 == 1) {
			if ((!time1.match(/^\d{2}:\d{2}$/) && use1 == 1) || (!time2.match(/^\d{2}:\d{2}$/) && use2 == 1)) {
				//alert("Incorrect time format, use hh:mm (24 hour time).");
			} else {
				for (var i in riders) {
					if ((riders[i]['depart_time'] < time1 && use1 == 1)  || (riders[i]['depart_time'] > time2 && use2 == 1)) {
						document.getElementById("rider"+i).style.display="none";
						riders[i]['show']=false;
					}
				}
				for (var i in drivers) {
					if ((drivers[i]['depart_time'] < time1 && use1 == 1) || (drivers[i]['depart_time'] > time2 && use2 == 1)) {
						document.getElementById("driver"+i).style.display="none";
						drivers[i]['show']=false;
					}
				}
			}
		}
		if (document.getElementById("options_box_availability_available").checked != 1) {
			for (var i in riders) {
				if (riders[i]['driverID'] == '0') {
					document.getElementById("rider"+i).style.display="none";
					riders[i]['show']=false;
				}
			}
			for (var i in drivers) {
				if (numProperties(drivers[i]['riders']) < drivers[i]['number_passengers']) {
					document.getElementById("driver"+i).style.display="none";
					drivers[i]['show']=false;
				}
			}
		}
		if (document.getElementById("options_box_availability_assigned").checked != 1) {
			for (var i in riders) {
				if (riders[i]['driverID'] != '0') {
					document.getElementById("rider"+i).style.display="none";
					riders[i]['show']=false;
				}
			}
			for (var i in drivers) {
				if (numProperties(drivers[i]['riders']) >= drivers[i]['number_passengers']) {
					document.getElementById("driver"+i).style.display="none";
					drivers[i]['show']=false;
				}
			}
		}
		/*if (document.getElementById("options_box_special_cases_show_special").checked != 1) {
			for (var i in riders) {
				if (riders[i]['special_info'] != "") {
					document.getElementById("rider"+i).style.display="none";
					riders[i]['show']=false;
				}
			}
			for (var i in drivers) {
				if (drivers[i]['special_info'] != "") {
					document.getElementById("driver"+i).style.display="none";
					drivers[i]['show']=false;
				}
			}
		}*/
		/*if (document.getElementById("options_box_special_cases_show_standard").checked != 1) {
			for (var i in riders) {
				if (riders[i]['special_info'] == "") {
					document.getElementById("rider"+i).style.display="none";
					riders[i]['show']=false;
				}
			}
			for (var i in drivers) {
				if (drivers[i]['special_info'] == "") {
					document.getElementById("driver"+i).style.display="none";
					drivers[i]['show']=false;
				}
			}
		}*/
		if (current_driver != -1) {
			drivers[current_driver]['show']=true;
			for (var i in drivers[current_driver]['riders']) {
				riders[i]['show']=true;
			}
		}
		for (var i in locations) {
			var show=false;
			for (var j=0;j<locations[i]['rides'].length;j++) {
				id=locations[i]['rides'][j]['id'];
				if (locations[i]['rides'][j]['type'] == "driver") {
					if (drivers[id]['show'] == true) {
						show=true;
						break;
					}
				} else {
					if (riders[id]['show'] == true) {
						show=true;
						break;
					}
				}
			}
			if (!show) {
				locations[i]['marker'].closeInfoWindow();
				locations[i]['marker'].hide();
			} else {
				locations[i]['marker'].show();
			}
		}
		updateMarkers();
	}
	
	function updateDepartureTime1(check) {
		if (check) {
			document.getElementById("options_box_departure_time_use1").checked=1;
		}
		var hour;
		hour = parseInt(document.getElementById("options_box_departure_time_time1_hour").value)+parseInt(document.getElementById("options_box_departure_time_time1_ampm").value);
		if (hour < 10) {
			hour = "0"+hour;
		}
		departure_time1 = hour+":"+document.getElementById("options_box_departure_time_time1_minute").value;
		//alert(departure_time1);
		updateList();
	}
	function updateDepartureTime2(check) {
		if (check) {
			document.getElementById("options_box_departure_time_use2").checked=1;
		}
		var hour;
		hour = parseInt(document.getElementById("options_box_departure_time_time2_hour").value)+parseInt(document.getElementById("options_box_departure_time_time2_ampm").value);
		if (hour < 10) {
			hour = "0"+hour;
		}
		departure_time2 = hour+":"+document.getElementById("options_box_departure_time_time2_minute").value;
		//alert(departure_time2);
		updateList();
	}
	function updateSpecialCases() {
		
	}
	
	function setCurrentDriver(i) {
		var li;
		var a;
		if (current_driver != -1) {
			unsetCurrentDriver();
		}
		drivers[i]['marker'].closeInfoWindow();
		for (var j in drivers[i]['riders']) {
			li=document.createElement("li");
			li.innerHTML="<a href=\"javascript:map.setCenter(riders["+j+"]['marker'].getLatLng(), 15);showMarker(riders["+j+"]['location'], "+j+");\">"+riders[j]['name']+"</a> ("+riders[j]['city']+")";
			document.getElementById("selected_riders").appendChild(li);
			document.getElementById("rider"+j).style.display="none";
			document.getElementById("selected_riders").style.display="block";
		}
		li=document.createElement("li");
		li.id="driver_selected"+i;
		li.innerHTML="<a href=\"javascript:map.setCenter(drivers["+i+"]['marker'].getLatLng(), 15);showMarker(drivers["+i+"]['location'], "+i+");\">"+drivers[i]['name']+"</a> ("+numProperties(drivers[i]['riders'])+"/"+drivers[i]['number_passengers']+")";
		document.getElementById("selected_driver").appendChild(li);
		document.getElementById("driver"+i).style.display="none";
		document.getElementById("selected_driver").style.display="block";
		document.getElementById("drivers_none").style.display="none";
		document.getElementById("drivers").style.top="129px";
		current_driver=i;
		updateList();
	}
	
	function unsetCurrentDriver() {
		document.getElementById("driver"+current_driver).style.display="block";
		for (var j in drivers[current_driver]['riders']) {
			document.getElementById("rider"+j).style.display="block";
		}
		empty("selected_driver");
		empty("selected_riders");
		drivers[current_driver]['marker'].closeInfoWindow();
		document.getElementById("drivers_none").style.display="block";
		document.getElementById("drivers").style.top="175px";
		current_driver=-1;
		updateList();
	}
	
	function addRider(i) {
		if (current_driver == -1) {
			alert("You have no driver selected. Rrider could not be added.");
		} else if (numProperties(drivers[current_driver]['riders']) >= drivers[current_driver]['number_passengers']) {
			alert("That car has no more space. Rider could not be added.");
		} else {
			if (!(i in drivers[current_driver]['riders'])) {
				var j=current_driver;
				new Ajax.Request('/carpool/add_rider?driver='+current_driver+'&rider='+i, {method:'get', onSuccess:function(transport){
					if (!(i in drivers[j]['riders'])) {
						drivers[j]['riders'][i]=i;
						document.getElementById("driver"+j).innerHTML="<a href=\"javascript:map.setCenter(drivers["+j+"]['marker'].getLatLng(), 15);showMarker(drivers["+j+"]['location'], "+j+");\" ondblclick=\"double_click_driver("+j+");return false;\">"+drivers[j]['name']+"</a> ("+numProperties(drivers[j]['riders'])+"/"+drivers[j]['number_passengers']+")";
						document.getElementById("driver_selected"+j).innerHTML="<a href=\"javascript:map.setCenter(drivers["+j+"]['marker'].getLatLng(), 15);showMarker(drivers["+j+"]['location'], "+j+");\">"+drivers[j]['name']+"</a> ("+numProperties(drivers[j]['riders'])+"/"+drivers[j]['number_passengers']+")";
						riders[i]['driverID']=j;
						riders[i]['marker'].closeInfoWindow();
						var img=document.createElement("img");
						img.src="images/check.png";
						img.alt="Done";
						img.title="This person has already been assigned."
						prependChild(document.getElementById("rider"+i), img);
						var li=document.createElement("li");
						li.innerHTML="<a href=\"javascript:map.setCenter(riders["+i+"]['marker'].getLatLng(), 15);showMarker(riders["+i+"]['location'], "+i+");\">"+riders[i]['name']+"</a> ("+riders[i]['city']+")";
						document.getElementById("selected_riders").appendChild(li);
						document.getElementById("selected_riders").style.display="block";
						document.getElementById("rider"+i).style.display="none";
						updateRidersDone();
						updateList();
					}
				}, onFailure: function() {alert("Could not connect to server. Rider could not be added.")}});
			}
		}
	}
	
	function removeRider(i) {
		if (riders[i]['driverID'] == 0) {
			alert("This rider is not assigned to any car and thus cannot be removed from a car.");
		} else {
			new Ajax.Request('/carpool/remove_rider?rider='+i, {method:'get', onSuccess:function(transport){
				var old_driver=riders[i]['driverID'];
				delete drivers[old_driver]['riders'][i];
				document.getElementById("driver"+old_driver).innerHTML="<a href=\"javascript:map.setCenter(drivers["+old_driver+"]['marker'].getLatLng(), 15);showMarker(drivers["+old_driver+"]['location'], "+old_driver+");\" ondblclick=\"double_click_driver("+old_driver+");return false;\">"+drivers[old_driver]['name']+"</a> ("+numProperties(drivers[old_driver]['riders'])+"/"+drivers[old_driver]['number_passengers']+")";
				riders[i]['driverID']=0;
				riders[i]['marker'].closeInfoWindow();
				document.getElementById("rider"+i).innerHTML="<a href=\"javascript:map.setCenter(riders["+i+"]['marker'].getLatLng(), 15);showMarker(riders["+i+"]['location'], "+i+");\" ondblclick=\"double_click_rider("+i+");return false;\">"+riders[i]['name']+"</a> ("+riders[i]['city']+")";
				if (old_driver == current_driver) {
					setCurrentDriver(current_driver); // regenerate the list of selected riders
					if (numProperties(drivers[current_driver]['riders']) == 0) {
						document.getElementById("selected_riders").style.display="none";
					}
				}
				updateRidersDone();
				updateList();
			}, onFailure: function() {alert("Could not connect to server. Rider could not be removed.")}});
		}
	}

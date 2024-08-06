extends Node

var attack_dict={}
var defend_dict={}
var timeline_dict={}
var opforprof_dict={}
var d3fendprof_dict={}
var red_objective=""
var blue_objective=""
var time_limit = 300
var downloadpath
var preloadedmission=false 
var default = true
var readtime=false

func _ready():
	get_downloads_path()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func import_resources_data():
	var file= FileAccess.open("res://data/ATT&CK_database.txt", FileAccess.READ)
	while !file.eof_reached():
		var attack_data_set = Array(file.get_csv_line())
		attack_dict[attack_dict.size()] = attack_data_set
	file.close()
	
	var file2= FileAccess.open("res://data/D3fend_database.txt", FileAccess.READ)
	while !file2.eof_reached():
		var defense_data_set = Array(file2.get_csv_line())
		defend_dict[defend_dict.size()] = defense_data_set
	file2.close()
	
	if default:
		var file3 = FileAccess.open("res://data/example_mission_timeline.txt", FileAccess.READ)
		while !file3.eof_reached():
			var timeline_data_set = Array(file3.get_csv_line())
			timeline_dict[timeline_dict.size()] = timeline_data_set
		file3.close()
		
		var file4 = FileAccess.open("res://data/testing_profile_DELETE_LATER.txt", FileAccess.READ)
		while !file4.eof_reached():
			var opfor_data_set = Array(file4.get_csv_line())
			opforprof_dict[opforprof_dict.size()] = opfor_data_set
		file4.close()
		
		var file5 = FileAccess.open("res://data/d3fend_profile_test.txt", FileAccess.READ)
		while !file5.eof_reached():
			var d3fend_data_set=Array(file5.get_csv_line())
			d3fendprof_dict[d3fendprof_dict.size()]=d3fend_data_set
		file5.close()
	else:
		var file3 = FileAccess.open("user://mission_timeline.txt", FileAccess.READ)
		while !file3.eof_reached():
			var timeline_data_set = Array(file3.get_csv_line())
			timeline_dict[timeline_dict.size()] = timeline_data_set
		file3.close()
		
		var file4 = FileAccess.open("user://opfor_profile.txt", FileAccess.READ)
		while !file4.eof_reached():
			var opfor_data_set = Array(file4.get_csv_line())
			opforprof_dict[opforprof_dict.size()] = opfor_data_set
		file4.close()
		
		var file5 = FileAccess.open("user://defend_profile.txt", FileAccess.READ)
		while !file5.eof_reached():
			var d3fend_data_set=Array(file5.get_csv_line())
			d3fendprof_dict[d3fendprof_dict.size()]=d3fend_data_set
		file5.close()

func get_downloads_path():
	match OS.get_name():
		"Windows":
			downloadpath = OS.get_environment("USERPROFILE") + "/Downloads"
		"Linux", "BSD":
			downloadpath = OS.get_environment("HOME") + "/Downloads"
		"MacOS":
			downloadpath = OS.get_environment("HOME") + "/Downloads"
			
func convert_time(time):
	var converted
	if time.length()==3:
		converted=int(time.substr(0,1))*60+int(time.substr(1,2))
		print(converted)
	if time.length()==4:
		converted=int(time.substr(0,2))*60+int(time.substr(2,2))
		print(converted)
	return converted
	
	
func time_convert(time):
	time=int(time)
	var hours=str(time/60)
	var minutes=str(time%60)
	if str(minutes).length()==1:
		minutes="0"+str(minutes)
	return hours+minutes
	

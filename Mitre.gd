extends Node

var attack_dict={}
var defend_dict={}
var timeline_dict={}
var opforprof_dict={}
var d3fendprof_dict={}
var red_objective=""
var blue_objective=""
var time_limit = 300
var downloadpath = ""
var preloadedmission=false 
var readtime=false

func _ready():
	get_downloads_path()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func import_resources_data(user_attack_profile,user_defend_profile,user_timeline_file):
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

# Upload attack profile. If true use user upload file, else use game default settings.
	if user_attack_profile:
		var file4 = FileAccess.open("user://opfor_profile.txt", FileAccess.READ)
		while !file4.eof_reached():
			var opfor_data_set = Array(file4.get_csv_line())
			if opfor_data_set != [""]:
				opforprof_dict[opforprof_dict.size()] = opfor_data_set
		file4.close()
	else:
		var file4 = FileAccess.open("res://default/attack_profile_default.txt", FileAccess.READ)
		while !file4.eof_reached():
			var opfor_data_set = Array(file4.get_csv_line())
			if opfor_data_set != [""]:
				opforprof_dict[opforprof_dict.size()] = opfor_data_set
		file4.close()
# Upload defend profile. If true use user uploaded file, else use game default settings.
	if user_defend_profile:	
		var file5 = FileAccess.open("user://defend_profile.txt", FileAccess.READ)
		while !file5.eof_reached():
			var d3fend_data_set=Array(file5.get_csv_line())
			if d3fend_data_set != [""]:
				d3fendprof_dict[d3fendprof_dict.size()]=d3fend_data_set
		file5.close()
	else:
		var file5 = FileAccess.open("res://default/defend_profile_default.txt", FileAccess.READ)
		while !file5.eof_reached():
			var d3fend_data_set=Array(file5.get_csv_line())
			if d3fend_data_set != [""]:
				d3fendprof_dict[d3fendprof_dict.size()]=d3fend_data_set
		file5.close()
# Upload mission timeline. If true use user defined timeline, else use game default.
	if user_timeline_file:
		var file3 = FileAccess.open("user://mission_timeline.txt", FileAccess.READ)
		while !file3.eof_reached():
			var timeline_data_set = Array(file3.get_csv_line())
			timeline_dict[timeline_dict.size()] = timeline_data_set
		file3.close()
	else:
		var file3 = FileAccess.open("res://default/timeline_default.txt", FileAccess.READ)
		while !file3.eof_reached():
			var timeline_data_set = Array(file3.get_csv_line())
			timeline_dict[timeline_dict.size()] = timeline_data_set
		file3.close()
		

# Get Users Download Path
func get_downloads_path():
	match OS.get_name():
		"Windows":
			downloadpath = OS.get_environment("USERPROFILE") + "/Downloads"
		"Linux", "BSD":
			downloadpath = OS.get_environment("HOME") + "/Downloads"
		"MacOS":
			downloadpath = OS.get_environment("HOME") + "/Downloads"

# Take string timestamp convert to int value of total minutes
func convert_time(time):
	var converted = 0
	if time.length()==3:
		converted=int(time.substr(0,1))*60+int(time.substr(1,2))
		print(converted)
	if time.length()==4:
		converted=int(time.substr(0,2))*60+int(time.substr(2,2))
		print(converted)
	return converted

# Take int and convert to strings of hours and minutes. 
func time_convert(time):
	time=int(time)
	var hours=str(time/60)
	var minutes=str(time%60)
	if str(minutes).length()==1:
		minutes="0"+str(minutes)
	return hours+minutes
	

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

func _ready():
	get_downloads_path()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
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

# Upload attack profile and mission text. If true use user upload file, else use game default settings.
	var file_name4 = "res://default/attack_profile_default.txt"
	if user_attack_profile:
		file_name4 = "user://opfor_profile.txt"
	var file4 = FileAccess.open(file_name4, FileAccess.READ)
	while !file4.eof_reached():
		var opfor_data_set = Array(file4.get_csv_line())
		if opfor_data_set != [""]:
			opforprof_dict[opforprof_dict.size()] = opfor_data_set
	file4.close()
	# Clean dict and set red objective aka opfor mission text
	red_objective = ",".join(opforprof_dict[1])
	opforprof_dict.erase(0)
	opforprof_dict.erase(1)
	# Reset keys to be sequential
	var temp_dict = {}
	var index = 0
	for value in opforprof_dict.values():
		temp_dict[index] = value
		index += 1
	# Replace the old dictionary with the new one
	opforprof_dict = temp_dict

# Upload defend profile. If true use user uploaded file, else use game default settings.
	var file_name5 = "res://default/defend_profile_default.txt"
	if user_defend_profile:	
		file_name5 = "user://defend_profile.txt"
	var file5 = FileAccess.open(file_name5, FileAccess.READ)
	while !file5.eof_reached():
		var d3fend_data_set=Array(file5.get_csv_line())
		if d3fend_data_set != [""]:
			d3fendprof_dict[d3fendprof_dict.size()]=d3fend_data_set
	file5.close()
	# Clean dict and set blue objective aka mission text
	blue_objective = ",".join(d3fendprof_dict[1])
	d3fendprof_dict.erase(0)
	d3fendprof_dict.erase(1)
	# Reset keys to be sequential
	temp_dict = {}
	index = 0
	for value in d3fendprof_dict.values():
		temp_dict[index] = value
		index += 1
	# Replace the old dictionary with the new one
	d3fendprof_dict = temp_dict
	
# Upload mission timeline. If true use user defined timeline, else use game default.
	var file_name3 = "res://default/timeline_default.txt"
	if user_timeline_file:
		file_name3 = "user://mission_timeline.txt"
	var file3 = FileAccess.open(file_name3, FileAccess.READ)
	while !file3.eof_reached():
		var timeline_data_set = Array(file3.get_csv_line())
		if timeline_data_set != [""]:
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
# Keep function for now, plan to remove later if not needed. 
#func convert_time(time):
	#var converted = 0
	#if time.length()==3:
		#converted=int(time.substr(0,1))*60+int(time.substr(1,2))
		#print(converted)
	#if time.length()==4:
		#converted=int(time.substr(0,2))*60+int(time.substr(2,2))
		#print(converted)
	#return converted

# Take int and convert to strings of hours and minutes. 
# Keep function for now, plan to remove later if not needed. 
#func time_convert(time):
	#time=int(time)
	#var hours=str(time/60)
	#var minutes=str(time%60)
	#if str(minutes).length()==1:
		#minutes="0"+str(minutes)
	#return hours+minutes
	

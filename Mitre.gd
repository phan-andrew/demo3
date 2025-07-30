extends Node

var attack_dict = {}
var defend_dict = {}
var timeline_dict = {}
var opforprof_dict = {}
var d3fendprof_dict = {}
var red_objective = ""
var blue_objective = ""
var time_limit = 300
var downloadpath = ""

func _ready():
	get_downloads_path()

func _process(_delta):
	pass

func import_resources_data(user_attack_profile, user_defend_profile, user_timeline_file):
	# Load ATT&CK data
	var file = FileAccess.open("res://data/ATT&CK_database.txt", FileAccess.READ)
	while !file.eof_reached():
		var attack_data_set = Array(file.get_csv_line())
		attack_dict[attack_dict.size()] = attack_data_set
	file.close()

	# Load D3FEND data
	var file2 = FileAccess.open("res://data/D3fend_database.txt", FileAccess.READ)
	while !file2.eof_reached():
		var defense_data_set = Array(file2.get_csv_line())
		defend_dict[defend_dict.size()] = defense_data_set
	file2.close()

	# Load attack profile
	var file_name4 = "res://default/attack_profile_default.txt"
	if user_attack_profile:
		file_name4 = "user://opfor_profile.txt"
	var file4 = FileAccess.open(file_name4, FileAccess.READ)
	while !file4.eof_reached():
		var opfor_data_set = Array(file4.get_csv_line())
		if opfor_data_set != [""]:
			opforprof_dict[opforprof_dict.size()] = opfor_data_set
	file4.close()

	# Extract red objective
	red_objective = ",".join(opforprof_dict[1])
	opforprof_dict.erase(0)
	opforprof_dict.erase(1)
	opforprof_dict = _reindex_dict(opforprof_dict)

	# Load defend profile
	var file_name5 = "res://default/defend_profile_default.txt"
	if user_defend_profile:
		file_name5 = "user://defend_profile.txt"
	var file5 = FileAccess.open(file_name5, FileAccess.READ)
	while !file5.eof_reached():
		var d3fend_data_set = Array(file5.get_csv_line())
		if d3fend_data_set != [""]:
			d3fendprof_dict[d3fendprof_dict.size()] = d3fend_data_set
	file5.close()

	# Extract blue objective
	blue_objective = ",".join(d3fendprof_dict[1])
	d3fendprof_dict.erase(0)
	d3fendprof_dict.erase(1)
	d3fendprof_dict = _reindex_dict(d3fendprof_dict)

	# Load timeline file
	var file_name3 = "res://default/timeline_default.txt"
	if user_timeline_file:
		file_name3 = "user://mission_timeline.txt"
	var file3 = FileAccess.open(file_name3, FileAccess.READ)
	while !file3.eof_reached():
		var timeline_data_set = Array(file3.get_csv_line())
		if timeline_data_set.size() >= 2:
			var time = timeline_data_set[0].strip_edges()
			var header = timeline_data_set[1].strip_edges()
			var description = ""
			var subsystems = ""
			if timeline_data_set.size() > 3:
				subsystems = str(timeline_data_set[3]).strip_edges()


			if timeline_data_set.size() > 2:
				description = timeline_data_set[2].strip_edges()

			timeline_dict[timeline_dict.size()] = [time, header, description, subsystems]
	file3.close()

func _reindex_dict(old_dict):
	var new_dict = {}
	var index = 0
	for value in old_dict.values():
		new_dict[index] = value
		index += 1
	return new_dict

func get_downloads_path():
	match OS.get_name():
		"Windows":
			downloadpath = OS.get_environment("USERPROFILE") + "/Downloads"
		"Linux", "BSD", "MacOS":
			downloadpath = OS.get_environment("HOME") + "/Downloads"

extends Control


var example_dict={}

func _ready():
	import_resources_data()

func import_resources_data():
	var file= FileAccess.open("res://data/ATT&CK.txt", FileAccess.READ)
	while !file.eof_reached():
		var data_set = Array(file.get_csv_line())
		example_dict[example_dict.size()] = data_set
	file.close()
	var a=0
	while a<5:
		print(example_dict[a][0])
		a+=1

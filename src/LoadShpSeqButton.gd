extends Button

@export var file_dialog: FileDialog

func parse_file(filepath:String) -> void:
	var file_extension:String = filepath.get_extension()
	if file_extension.to_lower() == "shp":
		parse_shp(filepath)
	elif file_extension.to_lower() == "seq":
		pass
		parse_seq(filepath);


func parse_shp(filepath:String) -> void:	
	var new_shp:Shp = Shp.new()
	new_shp.set_data_from_shp_file(filepath)
	new_shp.write_cfg()
	#new_shp.write_shp()
	new_shp.write_csvs()


func parse_seq(filepath:String) -> void:
	var new_seq:Seq = Seq.new()
	new_seq.set_data_from_seq_file(filepath)
	new_seq.write_cfg()
	#new_seq.write_wiki_table()
	new_seq.write_csv()


func _on_pressed():
	# print_debug("load file button pressed")
	file_dialog.visible = true


func _on_file_dialog_file_selected(path):
	parse_file(path)

func _on_file_dialog_files_selected(paths):
	for filepath in paths:
		parse_file(filepath)

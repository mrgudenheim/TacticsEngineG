extends Node3D

var rom_reader: RomReader = RomReader.new()
@export var load_rom: LoadRomButton
@export var texture_viewer: Sprite3D


func _ready() -> void:
	load_rom.file_selected.connect(rom_reader.on_load_rom_dialog_file_selected)
	rom_reader.rom_loaded.connect(on_rom_loaded)


func on_rom_loaded() -> void:
	push_warning("on rom loaded")
	
	var map_file_name: String = "MAP056.48"
	var map_texture_file_name: String = "MAP056.47"
	
	var map_mesh_data: PackedByteArray = rom_reader.get_file_data(map_file_name)
	var map_texture_data: PackedByteArray = rom_reader.get_file_data(map_texture_file_name)
	
	var map_data: MapData = MapData.new()	
	map_data.create_map(map_mesh_data, map_texture_data)
	
	texture_viewer.texture = map_data.albedo_texture
	
	# add mesh_node to scene? maybe should be in a different class
	var mesh_node = MeshInstance3D.new()
	mesh_node.mesh = map_data.mesh
	
	add_child(mesh_node)
	
	push_warning("Map_created")

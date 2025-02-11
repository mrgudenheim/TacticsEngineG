extends Node3D

var rom_reader: RomReader = RomReader.new()
@export var load_rom: LoadRomButton
@export var texture_viewer: Sprite3D
@export var map_mesh: MeshInstance3D

func _ready() -> void:
	load_rom.file_selected.connect(rom_reader.on_load_rom_dialog_file_selected)
	rom_reader.rom_loaded.connect(on_rom_loaded)


func on_rom_loaded() -> void:
	push_warning("on rom loaded")
	
	var map_file_name: String = "MAP056.48"
	var map_texture_file_name: String = "MAP056.47"
	
	var start_time: int = Time.get_ticks_msec()
	var map_mesh_data: PackedByteArray = rom_reader.get_file_data(map_file_name)
	var map_texture_data: PackedByteArray = rom_reader.get_file_data(map_texture_file_name)
	
	push_warning("Time to get file data (ms): " + str(Time.get_ticks_msec() - start_time))
	
	var map_data: MapData = MapData.new()	
	map_data.create_map(map_mesh_data, map_texture_data, 0)
	
	texture_viewer.texture = map_data.albedo_texture
	map_mesh.mesh = map_data.mesh
	
	push_warning("Time to create map (ms): " + str(Time.get_ticks_msec() - start_time))
	push_warning("Map_created")

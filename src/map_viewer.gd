extends Node3D

var rom_reader: RomReader = RomReader.new()
@export var load_rom: LoadRomButton
@export var texture_viewer: Sprite3D
@export var map_mesh: MeshInstance3D
@export var camera_controller: CameraController

const PIXELS_PER_TILE: int = 28
const UNITS_PER_HEIGHT: float = 3.0 / 7

func _ready() -> void:
	load_rom.file_selected.connect(rom_reader.on_load_rom_dialog_file_selected)
	rom_reader.rom_loaded.connect(on_rom_loaded)


func on_rom_loaded() -> void:
	push_warning("on rom loaded")
	
	# Orbonne
	var map_file_name: String = "MAP056.48"
	var map_texture_file_name: String = "MAP056.47"
	
	# Gariland
	#map_file_name = "MAP022.9"
	#map_texture_file_name = "MAP022.8"
	
	var start_time: int = Time.get_ticks_msec()
	var map_mesh_data: PackedByteArray = rom_reader.get_file_data(map_file_name)
	var map_texture_data: PackedByteArray = rom_reader.get_file_data(map_texture_file_name)
	
	push_warning("Time to get file data (ms): " + str(Time.get_ticks_msec() - start_time))
	
	var map_data: MapData = MapData.new()
	map_data.create_map(map_mesh_data, map_texture_data, 0)
	
	texture_viewer.texture = map_data.albedo_texture
	map_mesh.mesh = map_data.mesh
	map_mesh.scale = (1.0/PIXELS_PER_TILE) * Vector3.ONE
	#map_mesh.position = Vector3(-map_data.map_width / 2.0, 0, map_data.map_length / 2.0)
	var middle_height: float = map_data.terrain_tiles[map_data.terrain_tiles.size() / 2].height * UNITS_PER_HEIGHT
	middle_height = 11 * UNITS_PER_HEIGHT
	camera_controller.position = Vector3(map_data.map_width / 2.0, middle_height, -map_data.map_length / 2.0)
	
	push_warning("Time to create map (ms): " + str(Time.get_ticks_msec() - start_time))
	push_warning("Map_created")

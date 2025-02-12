extends Node3D

var rom_reader: RomReader = RomReader.new()
@export var load_rom: LoadRomButton
@export var texture_viewer: Sprite3D
@export var map_mesh: MeshInstance3D
@export var camera_controller: CameraController
@export var background_gradient: TextureRect

const SCALE: float = 1.0 / MapData.TILE_SIDE_LENGTH
const SCALED_UNITS_PER_HEIGHT: float = SCALE * MapData.UNITS_PER_HEIGHT

func _ready() -> void:
	load_rom.file_selected.connect(rom_reader.on_load_rom_dialog_file_selected)
	rom_reader.rom_loaded.connect(on_rom_loaded)


func on_rom_loaded() -> void:
	push_warning("on rom loaded")
	
	
	var map_file_name: String = "MAP056.GNS" # Orbonne
	#map_file_name = "MAP022.GNS" # Gariland
	
	var start_time: int = Time.get_ticks_msec()
	var map_gns_data: PackedByteArray = rom_reader.get_file_data(map_file_name)
	
	push_warning("Time to get file data (ms): " + str(Time.get_ticks_msec() - start_time))
	
	var map_data: MapData = MapData.new()
	map_data.file_name = map_file_name
	map_data.init_map(map_gns_data)
	
	background_gradient.texture.gradient.colors[0] = map_data.background_gradient_bottom
	background_gradient.texture.gradient.colors[1] = map_data.background_gradient_top
	
	texture_viewer.texture = map_data.albedo_texture
	map_mesh.mesh = map_data.mesh
	map_mesh.scale = SCALE * Vector3.ONE
	
	var middle_height: float = (map_data.terrain_tiles[map_data.terrain_tiles.size() / 2].height * SCALED_UNITS_PER_HEIGHT) + 2
	camera_controller.position = Vector3(map_data.map_width / 2.0, middle_height, -map_data.map_length / 2.0)
	camera_controller.rotation_degrees = Vector3(-CameraController.LOW_ANGLE, 45, 0)
	
	push_warning("Time to create map (ms): " + str(Time.get_ticks_msec() - start_time))
	push_warning("Map_created")

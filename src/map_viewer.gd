extends Node3D

var rom_reader: RomReader = RomReader.new()
@export var load_rom: LoadRomButton
@export var texture_viewer: Sprite3D
@export var camera_controller: CameraController
@export var background_gradient: TextureRect
@export var map_dropdown: OptionButton

@export var map_mesh: MeshInstance3D
@export var map_mesh2: MeshInstance3D
@export var map_mesh3: MeshInstance3D
@export var map_mesh4: MeshInstance3D

@export var map_collision_shape: CollisionShape3D
@export var map_collision_shape2: CollisionShape3D
@export var map_collision_shape3: CollisionShape3D
@export var map_collision_shape4: CollisionShape3D


@export var unit: RigidBody3D
@export var test_collision_shape: CollisionShape3D

var quad_mirror: bool = true

const SCALE: float = 1.0 / MapData.TILE_SIDE_LENGTH
const SCALED_UNITS_PER_HEIGHT: float = SCALE * MapData.UNITS_PER_HEIGHT

func _ready() -> void:
	load_rom.file_selected.connect(rom_reader.on_load_rom_dialog_file_selected)
	rom_reader.rom_loaded.connect(on_rom_loaded)
	map_dropdown.item_selected.connect(on_map_selected)

func on_rom_loaded() -> void:
	push_warning("on rom loaded")
	
	for file_name in RomReader.file_records.keys():
		if file_name.contains(".GNS"):
			map_dropdown.add_item(file_name)
	
	var default_map_index: int = 56 # Orbonne
	default_map_index = 22 # Gariland
	map_dropdown.select(default_map_index)
	map_dropdown.item_selected.emit(default_map_index)


func on_map_selected(index: int) -> void:
	var map_file_name: String = map_dropdown.get_item_text(index)
	
	var start_time: int = Time.get_ticks_msec()
	var map_gns_data: PackedByteArray = RomReader.get_file_data(map_file_name)
	
	push_warning("Time to get file data (ms): " + str(Time.get_ticks_msec() - start_time))
	
	var map_data: MapData = MapData.new()
	map_data.file_name = map_file_name
	map_data.init_map(map_gns_data)
	
	background_gradient.texture.gradient.colors[0] = map_data.background_gradient_bottom
	background_gradient.texture.gradient.colors[1] = map_data.background_gradient_top
	
	texture_viewer.texture = map_data.albedo_texture
	map_mesh.mesh = map_data.mesh
	map_mesh.scale = SCALE * Vector3.ONE
	
	var shape_mesh: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	var vertices: PackedVector3Array = map_mesh.mesh.get_faces().duplicate()
	for i: int in vertices.size():
		vertices[i] = vertices[i] * SCALE
	shape_mesh.set_faces(vertices)
	map_collision_shape.shape = shape_mesh
	
	if quad_mirror:
		map_mesh2.mesh = map_mesh.mesh
		map_mesh3.mesh = map_mesh.mesh
		map_mesh4.mesh = map_mesh.mesh
		map_mesh2.scale = SCALE * Vector3(1, 1, -1)
		map_mesh3.scale = SCALE * Vector3(-1, 1, 1)
		map_mesh4.scale = SCALE * Vector3(-1, 1, -1)
		map_mesh2.position = Vector3.FORWARD * map_data.map_length * 2
		map_mesh3.position = Vector3.RIGHT * map_data.map_width * 2
		map_mesh4.position = (Vector3.RIGHT * map_data.map_width * 2) + (Vector3.FORWARD * map_data.map_length * 2)
		
		map_collision_shape2.shape.set_faces(map_mesh2.mesh.get_faces())
		map_collision_shape3.shape.set_faces(map_mesh3.mesh.get_faces())
		map_collision_shape4.shape.set_faces(map_mesh4.mesh.get_faces())
	
	var middle_height: float = (map_data.terrain_tiles[map_data.terrain_tiles.size() / 2].height * SCALED_UNITS_PER_HEIGHT) + 2
	var middle_position: Vector3 = Vector3(map_data.map_width / 2.0, middle_height, -map_data.map_length / 2.0)
	camera_controller.position = middle_position
	camera_controller.camera_pivot.rotation_degrees = Vector3(-CameraController.LOW_ANGLE, 45, 0)
	
	push_warning("Time to create map (ms): " + str(Time.get_ticks_msec() - start_time))
	push_warning("Map_created")
	
	push_warning(middle_position)
	unit.global_position = middle_position + Vector3(-0.25, 0, 0)
	unit.linear_velocity = Vector3.ZERO
	
	unit.freeze = false

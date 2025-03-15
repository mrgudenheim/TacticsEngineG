class_name MapViewer
extends Node3D

#var rom_reader: RomReader = RomReader.new()
static var main_camera: Camera3D
@export var phantom_camera: PhantomCamera3D
@export var load_rom_button: LoadRomButton
@export var texture_viewer: Sprite3D
@export var camera_controller: CameraController
@export var background_gradient: TextureRect

@export var menu_list: Control
@export var map_dropdown: OptionButton
@export var orthographic_check: CheckBox
@export var menu_reminder: Label
@export var map_size_label: Label

@export var maps: Node3D
@export var map_tscn: PackedScene

@export var unit_tscn: PackedScene
@export var controller: UnitControllerRT

@export var mirror: bool = true
var walled_maps: PackedInt32Array = [
	3,
	4,
	8,
	10,
	11,
	13,
	14,
	16,
	17,
	18,
	20,
	21,
	24,
	26,
	33,
	39,
	41,
	51,
	52,
	53,
	62,
	65,
	68,
	73,
	92,
	93,
	94,
	95,
	96,
	104,
	]

const SCALE: float = 1.0 / MapData.TILE_SIDE_LENGTH
const SCALED_UNITS_PER_HEIGHT: float = SCALE * MapData.UNITS_PER_HEIGHT


func _ready() -> void:
	main_camera = get_viewport().get_camera_3d()
	
	load_rom_button.file_selected.connect(RomReader.on_load_rom_dialog_file_selected)
	RomReader.rom_loaded.connect(on_rom_loaded)
	map_dropdown.item_selected.connect(on_map_selected)
	orthographic_check.toggled.connect(on_orthographic_check_toggled)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_debug_ui()


func toggle_debug_ui() -> void:
	menu_list.visible = not menu_list.visible
	get_tree().call_group("Units", "toggle_debug_menu")


func hide_debug_ui() -> void:
	menu_list.visible = false
	get_tree().call_group("Units", "hide_debug_menu")


func on_rom_loaded() -> void:
	push_warning("on rom loaded")
	load_rom_button.visible = false
	
	for file_record: FileRecord in RomReader.file_records.values():
		if file_record.name.contains(".GNS"):
			var map_name: String = ""
			if file_record.type_index != 0 and file_record.type_index <= RomReader.fft_text.map_names.size():
				map_name = " " + RomReader.fft_text.map_names[file_record.type_index - 1]
			map_dropdown.add_item(file_record.name + map_name)
	
	var default_map_index: int = 56 # Orbonne
	default_map_index = 22 # Gariland
	map_dropdown.select(default_map_index)
	map_dropdown.item_selected.emit(default_map_index)


func on_map_selected(index: int) -> void:
	var map_file_name: String = map_dropdown.get_item_text(index)
	
	var start_time: int = Time.get_ticks_msec()
	
	var map_data: MapData = RomReader.maps[index]
	if not map_data.is_initialized:
		map_data.init_map()
	map_size_label.text = "Map Size: " + str(map_data.map_width) + " x " + str(map_data.map_length) + " (" + str(map_data.map_width * map_data.map_length) + ")"
	
	background_gradient.texture.gradient.colors[0] = map_data.background_gradient_bottom
	background_gradient.texture.gradient.colors[1] = map_data.background_gradient_top
	
	texture_viewer.texture = map_data.albedo_texture
	
	clear_maps()
	
	maps.add_child(instantiate_map(index, not walled_maps.has(index)))
	
	var middle_height: float = (map_data.terrain_tiles[map_data.terrain_tiles.size() / 2].height * SCALED_UNITS_PER_HEIGHT) + 2
	var middle_position: Vector3 = Vector3(map_data.map_width / 2.0, middle_height, -map_data.map_length / 2.0)
	camera_controller.position = middle_position
	camera_controller.camera_pivot.rotation_degrees = Vector3(-CameraController.LOW_ANGLE, 45, 0)
	
	push_warning("Time to create map (ms): " + str(Time.get_ticks_msec() - start_time))
	push_warning("Map_created")
	
	push_warning(middle_position)
	
	# add player unit
	var new_unit: UnitData = unit_tscn.instantiate()
	add_child(new_unit)
	new_unit.initialize_unit()
	new_unit.char_body.global_position = middle_position + Vector3(-0.5, 0, 0)
	new_unit.char_body.global_position = Vector3(5.5, 15, -5.5)
	#new_unit.set_sprite_file("AGURI.SPR") # Agrias
	new_unit.is_player_controlled = true
	
	controller.unit = new_unit
	controller.velocity_set.connect(controller.unit.update_unit_facing)
	#controller.camera_facing_changed.connect(controller.unit.update_animation_facing) # handled in controller with a call_group command
	phantom_camera.follow_target = new_unit.char_body
	
	# add non-player unit
	var new_unit2: UnitData = unit_tscn.instantiate()
	add_child(new_unit2)
	new_unit2.initialize_unit()
	new_unit2.char_body.global_position = middle_position + Vector3(-0.5, 0, 0)
	new_unit2.char_body.global_position = Vector3(3.5, 15, -5.5)
	new_unit2.set_sprite_file("ARU.SPR") # Algus
	
	new_unit2.knocked_out.connect(load_random_map)
	
	hide_debug_ui()


func get_map(new_map_data: MapData, position: Vector3, scale: Vector3) -> Map:
	var new_map_instance: Map = map_tscn.instantiate()
	new_map_instance.mesh.mesh = new_map_data.mesh
	new_map_instance.mesh.scale = scale
	new_map_instance.position = position
	new_map_instance.rotation_degrees = Vector3(0, 180, 180)
	
	var shape_mesh: ConcavePolygonShape3D = new_map_data.mesh.create_trimesh_shape()
	if scale == Vector3.ONE:
		new_map_instance.collision_shape.shape = new_map_data.mesh.create_trimesh_shape()
	else:
		new_map_instance.collision_shape.shape = get_scaled_collision_shape(new_map_data.mesh, scale)
	
	return new_map_instance


func get_scaled_collision_shape(mesh: Mesh, scale: Vector3) -> ConcavePolygonShape3D:
	var new_collision_shape: ConcavePolygonShape3D = mesh.create_trimesh_shape()
	var faces: PackedVector3Array = new_collision_shape.get_faces()
	for i: int in faces.size():
		faces[i] = faces[i] * scale
	
	#push_warning(faces)
	new_collision_shape.set_faces(faces)
	new_collision_shape.backface_collision = true
	return new_collision_shape


func on_orthographic_check_toggled(toggled_on: bool) -> void:
	if toggled_on:
		main_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		phantom_camera.set_spring_length(200)
		phantom_camera.set_collision_mask(0)
	else:
		main_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		phantom_camera.set_spring_length(7)
		#phantom_camera.set_collision_mask(1)


func instantiate_map(map_idx: int, mirror: bool) -> Node3D:
	var map_holder: Node3D = Node3D.new()
	
	var map_data: MapData = RomReader.maps[map_idx]
	if not map_data.is_initialized:
		map_data.init_map()
	
	map_holder.add_child(get_map(map_data, Vector3.ZERO, Vector3.ONE))
	
	if mirror:
		map_holder.add_child(get_map(map_data, Vector3.ZERO, Vector3(1, 1, -1)))
		map_holder.add_child(get_map(map_data, Vector3.FORWARD * map_data.map_length * 2, Vector3(1, 1, -1)))
		map_holder.add_child(get_map(map_data, Vector3.ZERO, Vector3(-1, 1, 1)))
		map_holder.add_child(get_map(map_data, Vector3.RIGHT * map_data.map_width * 2, Vector3(-1, 1, 1)))
		map_holder.add_child(get_map(map_data, Vector3.ZERO, Vector3(-1, 1, -1)))
		map_holder.add_child(get_map(map_data, Vector3.FORWARD * map_data.map_length * 2, Vector3(-1, 1, -1)))
		map_holder.add_child(get_map(map_data, Vector3.RIGHT * map_data.map_width * 2, Vector3(-1, 1, -1)))
		map_holder.add_child(get_map(map_data, (Vector3.RIGHT * map_data.map_width * 2) + (Vector3.FORWARD * map_data.map_length * 2), Vector3(-1, 1, -1)))
	
	return map_holder


func clear_maps() -> void:
	for child: Node in maps.get_children():
		child.queue_free()


func load_random_map() -> void:
	await get_tree().create_timer(2).timeout
	
	var new_map_idx: int = randi_range(1, map_dropdown.item_count - 1)
	map_dropdown.select(new_map_idx)
	map_dropdown.item_selected.emit(new_map_idx)

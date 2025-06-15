class_name BattleManager
extends Node3D

signal map_input_event(action_instance: ActionInstance, camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int)

# debug vars
@export var texture_viewer: Sprite3D # for debugging
@export var reference_quad: MeshInstance3D # for debugging
@export var highlights_container: Node3D

static var main_camera: Camera3D
@export var phantom_camera: PhantomCamera3D
@export var load_rom_button: LoadRomButton

#@export var camera_controller: CameraController
@export var background_gradient: TextureRect

@export var menu_list: Control
@export var map_dropdown: OptionButton
@export var orthographic_check: CheckBox
@export var menu_reminder: Label
@export var map_size_label: Label

@export var maps: Node3D
var total_map_tiles: Dictionary[Vector2i, Array] = {} # Array[TerrainTile]
@export var map_tscn: PackedScene
@export var map_shader: Shader
var current_tile_hover: TerrainTile
@export var tile_highlights: Dictionary[Color, Material] = {}

@export var action_menu: Control
@export var action_button_list: BoxContainer
@export var units_container: Node3D
@export var units: Array[UnitData]
@export var unit_tscn: PackedScene
@export var controller: UnitControllerRT

var event_num: int = 0 # TODO handle event timeline

@export var icon_counter: GridContainer

@export var allow_mirror: bool = true
var walled_maps: PackedInt32Array = [
	3,
	4,
	7,
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
	default_map_index = 83 # zirekile falls
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
	clear_units()
	
	maps.add_child(instantiate_map(index, not walled_maps.has(index)))
	#maps.add_child(instantiate_map(0x09, not walled_maps.has(index), Vector3(30, 0 * MapData.HEIGHT_SCALE, 0))) # 0x09 = Igros Citadel
	initialize_map_tiles()
	
	var map_width_range: Vector2i = Vector2i(0, map_data.map_width)
	var map_length_range: Vector2i = Vector2i(0, map_data.map_length)
	if not walled_maps.has(index):
		map_width_range = Vector2i(-map_data.map_width + 1, map_data.map_width * 2 - 2)
		map_length_range = Vector2i(-map_data.map_length + 1, map_data.map_length * 2 - 2)
	
	push_warning("Time to create map (ms): " + str(Time.get_ticks_msec() - start_time))
	push_warning("Map_created")
	
	add_units_to_map()


func add_units_to_map() -> void:
	# add player unit
	var random_tile: TerrainTile = get_random_stand_terrain_tile()
	var new_unit: UnitData = spawn_unit(random_tile, 0x05) # 0x05 is Delita holy knight
	new_unit.is_player_controlled = true
	new_unit.set_primary_weapon(0x1d) # ice brand
	
	# set up character controller
	controller.unit = new_unit
	#controller.velocity_set.connect(controller.unit.update_unit_facing)
	phantom_camera.follow_target = new_unit.char_body
	controller.rotate_camera(1) # HACK workaround for bug where controls are off until camera is rotated
	#controller.rotate_phantom_camera(Vector3(-26.54, 45, 0))
	
	# add non-player unit
	var new_unit2: UnitData = spawn_unit(get_random_stand_terrain_tile(), 0x07) # 0x07 is Algus
	new_unit2.set_primary_weapon(0x4e) # crossbow
	
	# set up what to do when target unit is knocked out
	new_unit2.knocked_out.connect(load_random_map)
	new_unit2.knocked_out.connect(increment_counter)
	
	#var new_unit3: UnitData = spawn_unit(random_tile, rand_job)
	var new_unit3: UnitData = spawn_unit(get_random_stand_terrain_tile(), 0x11) # 0x11 is Gafgorian dark knight
	new_unit3.set_primary_weapon(0x17) # blood sword
	
	var specific_jobs = [
		#0x65, # grenade
		#0x67, # panther
		#0x76, # juravis
		0x50, # black mage
		0x4f,# white mage
		]
	
	for specific_job: int in specific_jobs:
		spawn_unit(get_random_stand_terrain_tile(), specific_job)
	
	#for random_unit: int in 15:
		#var rand_job: int = randi_range(0x01, 0x8e)
		#spawn_unit(get_random_stand_terrain_tile(), rand_job)
	
	await update_units_pathfinding()
	
	new_unit.start_turn(self)
	
	hide_debug_ui()


func spawn_unit(tile_position: TerrainTile, job_id: int) -> UnitData:
	var new_unit: UnitData = unit_tscn.instantiate()
	units_container.add_child(new_unit)
	units.append(new_unit)
	new_unit.initialize_unit()
	new_unit.tile_position = tile_position
	new_unit.char_body.global_position = Vector3(tile_position.location.x + 0.5, randi_range(15, 20), tile_position.location.y + 0.5)
	new_unit.set_job_id(job_id)
	controller.camera_rotated.connect(new_unit.char_body.set_rotation_degrees) # have sprite update as camera rotates
	
	new_unit.primary_weapon_assigned.connect(func(weapon_id: int): new_unit.update_actions(self))
	new_unit.turn_ended.connect(process_next_event)
	
	return new_unit


func update_units_pathfinding() -> void:
	for unit: UnitData in units:
		await unit.update_map_paths(total_map_tiles, units)


# TODO handle event timeline
func process_next_event() -> void:
	# TODO implement action timeline
	event_num = (event_num + 1) % units.size()
	var new_unit: UnitData = units[event_num]
	controller.unit = new_unit
	phantom_camera.follow_target = new_unit.char_body
	
	new_unit.start_turn(self)


func get_map(new_map_data: MapData, map_position: Vector3, map_scale: Vector3) -> Map:
	var godot_scale: Vector3 = map_scale * Vector3(1, -1, 1) # vanilla used -y as up
	#var godot_scale: Vector3 = map_scale
	var new_map_instance: Map = map_tscn.instantiate()
	new_map_instance.map_data = new_map_data
	new_map_instance.mesh.mesh = new_map_data.mesh
	new_map_instance.mesh.scale = godot_scale
	new_map_instance.position = map_position
	#new_map_instance.rotation_degrees = Vector3(0, 0, 0)
	
	var new_mesh_material: ShaderMaterial = ShaderMaterial.new()
	new_mesh_material.shader = map_shader
	new_mesh_material.set_shader_parameter("albedo_texture_color_indicies", new_map_data.albedo_texture_indexed)
	new_mesh_material.set_shader_parameter("palettes_colors", new_map_data.texture_palettes)
	new_map_instance.mesh.material_override = new_mesh_material
	
	var shape_mesh: ConcavePolygonShape3D = new_map_data.mesh.create_trimesh_shape()
	if godot_scale == Vector3.ONE:
		new_map_instance.collision_shape.shape = new_map_data.mesh.create_trimesh_shape()
	else:
		new_map_instance.collision_shape.shape = get_scaled_collision_shape(new_map_data.mesh, godot_scale)
	
	new_map_instance.play_animations(new_map_data)
	new_map_instance.input_event.connect(on_map_input_event)
	
	return new_map_instance


func get_scaled_collision_shape(mesh: Mesh, collision_scale: Vector3) -> ConcavePolygonShape3D:
	var new_collision_shape: ConcavePolygonShape3D = mesh.create_trimesh_shape()
	var faces: PackedVector3Array = new_collision_shape.get_faces()
	for i: int in faces.size():
		faces[i] = faces[i] * collision_scale
	
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


func instantiate_map(map_idx: int, mirror_chunks: bool, offset: Vector3 = Vector3.ZERO) -> Node3D:
	var map_holder: Node3D = Node3D.new()
	
	var map_data: MapData = RomReader.maps[map_idx]
	if not map_data.is_initialized:
		map_data.init_map()
	
	map_holder.add_child(get_map(map_data, offset, Vector3(1, 1, 1)))
	
	if mirror_chunks and allow_mirror:
		map_holder.add_child(get_map(map_data, offset, Vector3(1, 1, -1)))
		map_holder.add_child(get_map(map_data, offset + (Vector3.FORWARD * map_data.map_length * -2), Vector3(1, 1, -1)))
		map_holder.add_child(get_map(map_data, offset, Vector3(-1, 1, -1)))
		map_holder.add_child(get_map(map_data, offset + (Vector3.RIGHT * map_data.map_width * 2), Vector3(-1, 1, -1)))
		map_holder.add_child(get_map(map_data, offset, Vector3(-1, 1, 1)))
		map_holder.add_child(get_map(map_data, offset + (Vector3.FORWARD * map_data.map_length * -2), Vector3(-1, 1, -1)))
		map_holder.add_child(get_map(map_data, offset + (Vector3.RIGHT * map_data.map_width * 2), Vector3(-1, 1, 1)))
		map_holder.add_child(get_map(map_data, offset + (Vector3.RIGHT * map_data.map_width * 2) + (Vector3.FORWARD * map_data.map_length * -2), Vector3(-1, 1, -1)))
	
	return map_holder


func initialize_map_tiles() -> void:
	total_map_tiles.clear()
	var map_chunks: Array[Map] = []
	
	for map_holder: Node3D in maps.get_children():
		for map_chunk: Map in map_holder.get_children() as Array[Map]:
			map_chunks.append(map_chunk)
	
	for map_chunk: Map in map_chunks:
		for tile: TerrainTile in map_chunk.map_data.terrain_tiles:
			if tile.no_cursor == 1:
				continue
			
			var total_location: Vector2i = tile.location
			var map_scale: Vector2i = Vector2i(map_chunk.mesh.scale.x, map_chunk.mesh.scale.z)
			total_location = total_location * map_scale
			var mirror_shift: Vector2i = map_scale # ex. (0,0) should be (-1, -1) when mirrored across x and y
			if map_scale.x == 1:
				mirror_shift.x = 0
			if map_scale.y == 1:
				mirror_shift.y = 0
			total_location = total_location + mirror_shift
			total_location = total_location + Vector2i(map_chunk.position.x, map_chunk.position.z)
			if not total_map_tiles.has(total_location):
				total_map_tiles[total_location] = []
			var total_tile: TerrainTile = tile.duplicate()
			total_tile.location = total_location
			total_tile.tile_scale.x = map_chunk.mesh.scale.x
			total_tile.tile_scale.z = map_chunk.mesh.scale.z
			total_tile.height_bottom += map_chunk.position.y / MapData.HEIGHT_SCALE
			total_tile.height_mid = total_tile.height_bottom + total_tile.slope_height
			total_map_tiles[total_location].append(total_tile)


func get_random_terrain_tile() -> TerrainTile:
	if total_map_tiles.size() == 0:
		push_warning("No map tiles")
	
	var random_key: Vector2i = total_map_tiles.keys().pick_random()
	var tiles: Array = total_map_tiles[random_key]
	var tile: TerrainTile = tiles.pick_random()
	
	return tile


func get_random_stand_terrain_tile() -> TerrainTile:
	var tile: TerrainTile
	for tile_idx: int in total_map_tiles.size():
		tile = get_random_terrain_tile()
		if tile.no_stand_select != 0 or tile.no_walk != 0:
			continue
		
		if units.any(func(unit: UnitData): return unit.tile_position == tile):
			continue
		
		break
	
	return tile


func clear_maps() -> void:
	total_map_tiles.clear()
	for child: Node in maps.get_children():
		child.queue_free()
		maps.remove_child(child)


func clear_units() -> void:
	for unit: UnitData in units:
		unit.queue_free()
	
	units.clear()
	#for child: Node in units_container.get_children():
		#child.queue_free()


func load_random_map(_unit: UnitData) -> void:
	await get_tree().create_timer(3).timeout
	
	var new_map_idx: int = randi_range(1, map_dropdown.item_count - 1)
	map_dropdown.select(new_map_idx)
	map_dropdown.item_selected.emit(new_map_idx)


func increment_counter(unit: UnitData) -> void:
	var knocked_out_icon: Image = unit.animation_manager.global_shp.get_assembled_frame(0x17, unit.animation_manager.global_spr.spritesheet, 0, 0, 0, 0)
	knocked_out_icon = knocked_out_icon.get_region(Rect2i(40, 50, 40, 40))
	
	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.texture = ImageTexture.create_from_image(knocked_out_icon)
	icon_counter.add_child(icon_rect)


func on_map_input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	map_input_event.emit(controller.unit.active_action, camera, event, event_position, normal, shape_idx)


func get_tile(input_position: Vector3) -> TerrainTile:
	var tile_location: Vector2i = Vector2i(floor(input_position.x), floor(input_position.z))
	var tile: TerrainTile
	if total_map_tiles.has(tile_location):
		var current_vert_error: float = 999.9
		for new_tile: TerrainTile in total_map_tiles[tile_location]:
			if tile == null:
				tile = new_tile
				current_vert_error = abs(((new_tile.height_mid + new_tile.depth) * MapData.HEIGHT_SCALE) - input_position.y)
			else:
				var new_vert_error: float = abs(((new_tile.height_mid + new_tile.depth) * MapData.HEIGHT_SCALE) - input_position.y)
				if new_vert_error < current_vert_error:
					current_vert_error = new_vert_error
					tile = new_tile
	
	return tile

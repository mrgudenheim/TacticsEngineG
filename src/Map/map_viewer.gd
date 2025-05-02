class_name MapViewer
extends Node3D

#var rom_reader: RomReader = RomReader.new()
static var main_camera: Camera3D
@export var phantom_camera: PhantomCamera3D
@export var load_rom_button: LoadRomButton
@export var texture_viewer: Sprite3D
#@export var camera_controller: CameraController
@export var background_gradient: TextureRect

@export var menu_list: Control
@export var map_dropdown: OptionButton
@export var orthographic_check: CheckBox
@export var menu_reminder: Label
@export var map_size_label: Label

@export var maps: Node3D
@export var map_tscn: PackedScene
@export var map_shader: Shader

@export var units: Node3D
@export var unit_tscn: PackedScene
@export var controller: UnitControllerRT

@export var icon_counter: GridContainer

@export var mirror: bool = true
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
	#for anim_id: int in map_data.texture_animations.size(): # TODO remove test code
		#var texture_anim := map_data.texture_animations[anim_id]
		#if [0x03, 0x04].has(texture_anim.anim_technique): # if palette animation
			#animate_preview_texture(texture_anim, map_data)
	
	clear_maps()
	clear_units()
	
	maps.add_child(instantiate_map(index, not walled_maps.has(index)))
	var map_width_range: Vector2i = Vector2i(0, map_data.map_width)
	var map_length_range: Vector2i = Vector2i(0, map_data.map_length)
	if not walled_maps.has(index):
		map_width_range = Vector2i(-map_data.map_width + 1, map_data.map_width * 2 - 2)
		map_length_range = Vector2i(-map_data.map_length + 1, map_data.map_length * 2 - 2)
	
	var middle_height: float = (map_data.terrain_tiles[map_data.terrain_tiles.size() / 2].height * SCALED_UNITS_PER_HEIGHT) + 2
	var middle_position: Vector3 = Vector3(map_data.map_width / 2.0, middle_height, -map_data.map_length / 2.0)
	var random_position: Vector3 = Vector3(randi_range(map_width_range.x, map_width_range.y) + 0.5, randi_range(10, 15), -randi_range(map_length_range.x, map_length_range.y) - 0.5)
	#camera_controller.position = middle_position
	#camera_controller.camera_pivot.rotation_degrees = Vector3(-CameraController.LOW_ANGLE, 45, 0)
	
	push_warning("Time to create map (ms): " + str(Time.get_ticks_msec() - start_time))
	push_warning("Map_created")
	
	push_warning(middle_position)
	
	# add player unit
	var new_unit: UnitData = unit_tscn.instantiate()
	units.add_child(new_unit)
	new_unit.initialize_unit()
	new_unit.char_body.global_position = middle_position + Vector3(-0.5, 5, 0)
	new_unit.char_body.global_position = random_position
	#new_unit.char_body.global_position = Vector3(5.5, 15, -5.5)
	#new_unit.set_sprite_file("AGURI.SPR") # Agrias
	new_unit.is_player_controlled = true
	
	controller.unit = new_unit
	controller.velocity_set.connect(controller.unit.update_unit_facing)
	#controller.camera_facing_changed.connect(controller.unit.update_animation_facing) # handled in controller with a call_group command
	phantom_camera.follow_target = new_unit.char_body
	controller.rotate_camera(1)
	#controller.rotate_phantom_camera(Vector3(-26.54, 45, 0))
	
	# add non-player unit
	var new_unit2: UnitData = unit_tscn.instantiate()
	units.add_child(new_unit2)
	new_unit2.initialize_unit()
	random_position = Vector3(randi_range(map_width_range.x, map_width_range.y) + 0.5, randi_range(10, 15), -randi_range(map_length_range.x, map_length_range.y) - 0.5)
	new_unit2.char_body.global_position = random_position
	#new_unit2.char_body.global_position = Vector3(3.5, 15, -5.5)
	new_unit2.set_sprite_file("ARU.SPR") # Algus
	
	new_unit2.knocked_out.connect(load_random_map)
	new_unit2.knocked_out.connect(increment_counter)
	
	hide_debug_ui()


func get_map(new_map_data: MapData, position: Vector3, scale: Vector3) -> Map:
	var new_map_instance: Map = map_tscn.instantiate()
	new_map_instance.mesh.mesh = new_map_data.mesh
	new_map_instance.mesh.scale = scale
	new_map_instance.position = position
	new_map_instance.rotation_degrees = Vector3(0, 180, 180)
	
	var new_mesh_material: ShaderMaterial = ShaderMaterial.new()
	new_mesh_material.shader = map_shader
	new_mesh_material.set_shader_parameter("albedo_texture_color_indicies", new_map_data.albedo_texture_indexed)
	#new_mesh_material.set_shader_parameter("albedo_texture_color_indicies", new_map_data.albedo_texture)
	new_mesh_material.set_shader_parameter("palettes_colors", new_map_data.texture_palettes)
	new_map_instance.mesh.material_override = new_mesh_material
	
	var shape_mesh: ConcavePolygonShape3D = new_map_data.mesh.create_trimesh_shape()
	if scale == Vector3.ONE:
		new_map_instance.collision_shape.shape = new_map_data.mesh.create_trimesh_shape()
	else:
		new_map_instance.collision_shape.shape = get_scaled_collision_shape(new_map_data.mesh, scale)
	
	new_map_instance.play_animations(new_map_data) # TODO animate textures
	
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


func clear_units() -> void:
	for child: Node in units.get_children():
		child.queue_free()


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


# TODO remove test code
func animate_preview_texture(texture_anim, map_data) -> void:
	var frame_id: int = 0
	var dir: int = 1
	while frame_id < texture_anim.num_frames:
		var new_palette: PackedColorArray = map_data.texture_animations_palette_frames[frame_id + texture_anim.animation_starting_index]
		var new_pixel_colors: PackedColorArray = map_data.get_texture_pixel_colors_new_palette(new_palette)
		var new_color_image: Image = map_data.get_texture_rgba8_image(0, new_pixel_colors)
		
		var new_texture_image: Image = texture_viewer.texture.get_image()
		new_texture_image.blit_rect(new_color_image, Rect2i(Vector2i.ZERO, new_color_image.get_size()), Vector2i(texture_anim.palette_id_to_animate * map_data.TEXTURE_SIZE.x, 0))
		var new_texture: ImageTexture = ImageTexture.create_from_image(new_texture_image)
		
		texture_viewer.texture = new_texture
		
		await Engine.get_main_loop().create_timer(texture_anim.frame_duration / float(30)).timeout
		if texture_anim.anim_technique == 0x3: # loop forward
			frame_id += dir
			frame_id = frame_id % texture_anim.num_frames
		elif texture_anim.anim_technique == 0x4: # loop back and forth
			if frame_id == texture_anim.num_frames - 1:
				dir = -1
			elif frame_id == 0:
				dir = 1
			frame_id += dir

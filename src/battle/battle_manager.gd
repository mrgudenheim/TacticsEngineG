class_name BattleManager
extends Node3D

signal map_input_event(action_instance: ActionInstance, camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int)

# debug vars
@export var use_test_teams: bool = false
@export var texture_viewer: Sprite3D # for debugging
@export var reference_quad: MeshInstance3D # for debugging
@export var highlights_container: Node3D

#static var main_camera: Camera3D
#@export var phantom_camera: PhantomCamera3D
@export var load_rom_button: LoadRomButton

@export var camera_controller: CameraController
var main_camera: Camera3D
@export var background_gradient: TextureRect

@export var menu_list: Control
@export var map_dropdown: OptionButton
@export var orthographic_check: CheckBox
@export var menu_reminder: Label
@export var map_size_label: Label
@export var expand_map_check: CheckBox

@export var maps: Node3D
var total_map_tiles: Dictionary[Vector2i, Array] = {} # Array[TerrainTile]
@export var map_tscn: PackedScene
var current_tile_hover: TerrainTile
@export var tile_highlights: Dictionary[Color, Material] = {}

@export var action_menu: Control
@export var action_button_list: BoxContainer
@export var units_container: Node3D
@export var units: Array[UnitData] = []
@export var teams: Array[Team] = []
@export var unit_tscn: PackedScene
@export var controller: UnitControllerRT
@export var battle_is_running: bool = false
@export var safe_to_load_map: bool = true
@export var battle_end_panel: Control
@export var post_battle_messages: Control
@export var start_new_battle_button: Button
@export var active_unit: UnitData
@export var game_state_label: Label
@export var units_per_team_spinbox: SpinBox
@export var units_per_team: int = 5:
	get:
		return units_per_team_spinbox.value
	set(value):
		units_per_team_spinbox.value = value
		units_per_team_spinbox.value_changed.emit(value)
@export var units_level_spinbox: SpinBox
@export var units_level: int = 40:
	get:
		return units_level_spinbox.value
	set(value):
		units_level_spinbox.value = value
		units_level_spinbox.value_changed.emit(value)

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
	main_camera = camera_controller.camera
	
	load_rom_button.file_selected.connect(RomReader.on_load_rom_dialog_file_selected)
	RomReader.rom_loaded.connect(on_rom_loaded)
	map_dropdown.item_selected.connect(queue_load_map)
	orthographic_check.toggled.connect(camera_controller.on_orthographic_toggled)
	#camera_controller.zoom_changed.connect(update_phantom_camera_spring)
	expand_map_check.toggled.connect(func(toggled_on: bool): allow_mirror = toggled_on)
	
	start_new_battle_button.pressed.connect(load_random_map)


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
	#default_map_index = 22 # Gariland
	#default_map_index = 83 # zirekile falls
	default_map_index = 85 # mandalia plains
	map_dropdown.select(default_map_index)
	map_dropdown.item_selected.emit(default_map_index)


func queue_load_map(index: int) -> void:
	if battle_is_running:
		while not safe_to_load_map:
			await get_tree().process_frame # TODO loop over safe_to_load_new_map, set false while awaiting processing
	on_map_selected(index)


func on_map_selected(index: int) -> void:
	battle_is_running = false
	battle_end_panel.visible = false
	var message_nodes: Array[Node] = post_battle_messages.get_children()
	for child: Node in message_nodes:
		child.queue_free()
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
	teams.clear()
	
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
	camera_controller.follow_node = units[0].char_body
	controller.unit = units[0]
	#controller.rotate_camera(1) # HACK workaround for bug where controls are off until camera is rotated
	
	battle_is_running = true
	process_battle()


func add_units_to_map() -> void:
	var team1: Team = Team.new()
	teams.append(team1)
	team1.team_name = "Team 1 (Player)"
	
	var team2: Team = Team.new()
	teams.append(team2)
	team2.team_name = "Team 2 (Computer)"
	
	if use_test_teams:
		add_test_teams_to_map()
	else: # use random teams
		var generic_job_ids: Array[int] = []
		generic_job_ids.assign(range(0x4a, 0x5a)) # generics
		var special_characters: Array[int] = [
			0x01, # ramza 1
			0x04, # ramza 4
			0x05, # delita 1
			0x34, # agrias
			0x11, # gafgorian
			]
		
		var monster_jobs: Array[int] = []
		monster_jobs.assign(range(0x5e, 0x8e)) # generic monsters
		var special_monsters: Array[int] = [
			0x41, # holy angel
			0x49, # arch angel
			0x3c, # gigas/warlock (Belias)
			0x3e, # angel of death
			0x40, # regulator (Hashmal)
			0x43, # impure king (quakelin)
			0x45, # ghost of fury (adremelk)
			0x97, # serpentarious
			0x91, # steel giant
			]
		
		var team_1_job_ids: Array[int] = generic_job_ids
		team_1_job_ids.append_array(special_characters)
		
		var team_2_job_ids: Array[int] = monster_jobs
		team_2_job_ids.append_array(special_monsters)
		
		for random_unit: int in units_per_team:
			var rand_job: int = team_1_job_ids.pick_random()
			while [0x2c, 0x31].has(rand_job): # prevent jobs without idle frames - 0x2c (Alma2) and 0x31 (Ajora) do not have walking frames
				rand_job = randi_range(0x01, 0x8d)
			var new_unit: UnitData = spawn_unit(get_random_stand_terrain_tile(), rand_job, team1)
			new_unit.is_ai_controlled = false
		
		for random_unit: int in units_per_team:
			var rand_job: int = team_2_job_ids.pick_random()
			#var rand_job: int = randi_range(0x5e, 0x8d) # monsters
			while [0x2c, 0x31].has(rand_job): # prevent jobs without idle frames - 0x2c (Alma2) and 0x31 (Ajora) do not have walking frames
				rand_job = randi_range(0x01, 0x8d)
			var new_unit: UnitData = spawn_unit(get_random_stand_terrain_tile(), rand_job, team2)
			#new_unit.is_ai_controlled = false
	
	await update_units_pathfinding()
	
	#new_unit.start_turn(self)
	
	units.shuffle()
	
	hide_debug_ui()


func add_test_teams_to_map() -> void:
	# add player unit
	var random_tile: TerrainTile = get_random_stand_terrain_tile()
	var new_unit: UnitData = spawn_unit(random_tile, 0x05, teams[0]) # 0x05 is Delita holy knight
	new_unit.is_ai_controlled = false
	new_unit.set_primary_weapon(0x1d) # ice brand
	
	# add non-player unit
	var new_unit2: UnitData = spawn_unit(get_random_stand_terrain_tile(), 0x07, teams[1]) # 0x07 is Algus
	new_unit2.set_primary_weapon(0x4e) # crossbow
	
	## set up what to do when target unit is knocked out
	#new_unit2.knocked_out.connect(load_random_map_delay)
	#new_unit2.knocked_out.connect(increment_counter)
	
	var new_unit3: UnitData = spawn_unit(get_random_stand_terrain_tile(), 0x11, teams[1]) # 0x11 is Gafgorian dark knight
	new_unit3.set_primary_weapon(0x17) # blood sword
	
	var specific_jobs = [
		#0x65, # grenade
		#0x67, # panther
		#0x76, # juravis
		#0x4a, # squire
		0x50, # black mage
		0x4f, # white mage
		#0x52, # summoner
		#0x51, # time mage
		#0x55, # oracle
		#0x49, # arch angel
		#0x5f, # black chocobo
		0x7b, # wildbow
		0x8D, # tiamat
		]
	
	for specific_job: int in specific_jobs:
		spawn_unit(get_random_stand_terrain_tile(), specific_job, teams[0])
	
	units[3].set_primary_weapon(0x4a) # blaze gun
	

	var test_ability: Ability = Ability.new()
	var test_triggered_action: TriggeredAction = TriggeredAction.new()
	test_ability.triggered_actions.append(test_triggered_action)

	# Move Hp Up
	test_triggered_action.trigger = TriggeredAction.TriggerTiming.MOVED
	test_triggered_action.action_idx = 597 # Regen
	test_triggered_action.trigger_chance_formula.values = [100.0]
	test_triggered_action.trigger_chance_formula.formula = FormulaData.Formulas.V1
	test_triggered_action.targeting = TriggeredAction.TargetingTypes.SELF
	test_triggered_action.name = "Triggered " + RomReader.actions[test_triggered_action.action_idx].action_name

	var json_file = FileAccess.open("user://overrides/move-hp-up.json", FileAccess.WRITE)
	json_file.store_line(test_triggered_action.to_json())
	json_file.close()

	# Counter Attack
	test_triggered_action.trigger = TriggeredAction.TriggerTiming.TARGETTED_POST_ACTION
	test_triggered_action.action_idx = -1 # primary attack special case
	test_triggered_action.trigger_chance_formula.values = [1.0]
	test_triggered_action.trigger_chance_formula.formula = FormulaData.Formulas.BRAVExV1
	test_triggered_action.targeting = TriggeredAction.TargetingTypes.INITIATOR
	test_triggered_action.name = "Triggered Attack"

	json_file = FileAccess.open("user://overrides/counter.json", FileAccess.WRITE)
	json_file.store_line(test_triggered_action.to_json())
	json_file.close()
	
	# Test Trigger
	#test_triggered_action.trigger = TriggeredAction.TriggerTiming.TARGETTED_POST_ACTION
	#test_triggered_action.action_idx = -1 # primary attack special case
	#test_triggered_action.trigger_chance_formula.values = [1.0]
	#test_triggered_action.trigger_chance_formula.formula = FormulaData.Formulas.BRAVExV1
	#test_triggered_action.user_stat_thresholds = { UnitData.StatType.HP : 5 }
	#test_triggered_action.targeting = TriggeredAction.TargetingTypes.INITIATOR
	#test_triggered_action.name = "Test Trigger"
	#
	#json_file = FileAccess.open("user://overrides/test_trigger.json", FileAccess.WRITE)
	#json_file.store_line(test_triggered_action.to_json())
	#json_file.close()
	
	json_file = FileAccess.open("user://overrides/test_trigger.json", FileAccess.READ)
	var json_text: String = json_file.get_as_text()
	test_triggered_action = TriggeredAction.create_from_json(json_text)
	test_ability.triggered_actions = [test_triggered_action]
	
	var csv_row = test_triggered_action.to_csv_row()
	
	json_file = FileAccess.open("user://overrides/triggered_actions_db.txt", FileAccess.WRITE)
	json_file.store_line(test_triggered_action.get_csv_headers())
	json_file.store_line(csv_row)
	json_file.close()

	for unit in units:
		unit.equip_ability(unit.ability_slots[4], test_ability)
		unit.is_ai_controlled = false


func spawn_unit(tile_position: TerrainTile, job_id: int, team: Team) -> UnitData:
	var new_unit: UnitData = unit_tscn.instantiate()
	units_container.add_child(new_unit)
	new_unit.global_battle_manager = self
	units.append(new_unit)
	new_unit.initialize_unit()
	new_unit.tile_position = tile_position
	new_unit.char_body.global_position = Vector3(tile_position.location.x + 0.5, randi_range(15, 20), tile_position.location.y + 0.5)
	new_unit.update_unit_facing([Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT].pick_random())
	if job_id < 0x5e: # non-monster
		new_unit.stat_basis = [UnitData.StatBasis.MALE, UnitData.StatBasis.FEMALE].pick_random()
	else:
		new_unit.stat_basis = UnitData.StatBasis.MONSTER
	new_unit.set_job_id(job_id)
	if range(0x4a, 0x5e).has(job_id):
		new_unit.set_sprite_palette(range(0,5).pick_random())
	new_unit.generate_raw_stats(new_unit.stat_basis)
	var level: int = units_level
	new_unit.stats[UnitData.StatType.LEVEL].set_value(level)
	new_unit.generate_leveled_stats(level, new_unit.job_data)
	new_unit.generate_battle_stats(new_unit.job_data)
	
	camera_controller.rotated.connect(new_unit.char_body.set_rotation_degrees) # have sprite update as camera rotates
	
	new_unit.icon.texture = RomReader.frame_bin_texture # TODO clean up status icon stuff
	new_unit.icon2.texture = RomReader.frame_bin_texture
	
	new_unit.primary_weapon_assigned.connect(func(weapon_id: int): new_unit.update_actions(self))
	new_unit.generate_equipment()
	#var unit_actions: Array[Action] = new_unit.get_skillset_actions()
	#if unit_actions.any(func(action: Action): return not action.required_equipment_type.is_empty()):
		#while not unit_actions.any(func(action: Action): return action.required_equipment_type.has(new_unit.primary_weapon.item_type)):
			#new_unit.set_primary_weapon(randi_range(0, 0x79)) # random weapon
	
	new_unit.name = new_unit.job_nickname + "-" + new_unit.unit_nickname
	
	new_unit.team = team
	team.units.append(new_unit)
	
	new_unit.is_ai_controlled = true
	new_unit.ai_controller.strategy = UnitAi.Strategy.BEST
	
	return new_unit


func update_units_pathfinding() -> void:
	#for unit: UnitData in units:
		#var max_move_cost: int = 9999
		#if unit != active_unit:
			#max_move_cost = unit.move_current # stop pathfinding early for non-active units, only need potential move targets, not path to every possible tile
		#
		#await unit.update_map_paths(total_map_tiles, units, max_move_cost)
	pass


func process_battle() -> void:
	while battle_is_running:
		await process_clock_tick()
		
		# TODO check end conditions, switching map, etc.
	
	for team: Team in teams:
		if team.state == Team.State.WON:
			battle_end_panel.visible = true
			var end_condition_title: Label = Label.new()
			end_condition_title.text = team.team_name + " Won!"
			end_condition_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			post_battle_messages.add_child(end_condition_title)
			for end_condition: EndCondition in team.end_conditions.keys():
				if team.end_conditions[end_condition] == true and end_condition.end_type == EndCondition.EndType.WIN:
					var end_condition_message: Label = Label.new()
					end_condition_message.text = end_condition.post_battle_message
					post_battle_messages.add_child(end_condition_message)


# TODO implement action timeline
func process_clock_tick() -> void:
	game_state_label.text = "processing new clock tick"
	
	# increment status ticks
	for unit: UnitData in units:
		var statuses_to_remove: Array[StatusEffect] = []
		for status: StatusEffect in unit.current_statuses:
			safe_to_load_map = false
			if status.duration_type == StatusEffect.DurationType.TICKS:
				status.duration -= 1
				if status.duration <= 0:
					#unit.current_statuses.erase(status)
					statuses_to_remove.append(status)
					if status.action_on_complete >= 0: # process potential removal if ticks_left == 0
						var status_action_instance: ActionInstance = ActionInstance.new(RomReader.actions[status.action_on_complete], unit, self)
						status_action_instance.submitted_targets.append(unit.tile_position) # TODO get targets for status action
						# RomReader.actions[status.action_on_complete].use(status_action_instance)
						camera_controller.follow_node = unit.char_body
						game_state_label.text = unit.job_nickname + "-" + unit.unit_nickname + " processing " + status.status_effect_name + " ending"
						await status_action_instance.use()
						# await status_action_instance.action_completed
						if check_end_conditions():
							safe_to_load_map = true
							return
					if status.delayed_action != null: # execute stored delayed actions, TODO checks to null (no mp, silenced, etc.)
						#status.delayed_action.show_targets_highlights(status.delayed_action.preview_targets_highlights) # show submitted targets TODO retain preview highlight nodes?
						#await unit.get_tree().create_timer(0.5).timeout
						camera_controller.follow_node = unit.char_body
						game_state_label.text = unit.job_nickname + "-" + unit.unit_nickname + " processing delayed " + status.delayed_action.action.action_name
						await status.delayed_action.use()
						#await status.delayed_action.action_completed
						if check_end_conditions():
							safe_to_load_map = true
							return
			safe_to_load_map = true
			await get_tree().process_frame
		for status: StatusEffect in statuses_to_remove:
			unit.remove_status(status)
	
	for unit: UnitData in units: # increment each units ct by speed
		if not unit.current_statuses.any(func(status: StatusEffect): return status.freezes_ct): # check status that prevent ct gain (stop, sleep, etc.)
			var ct_gain: int = unit.speed_current
			for status: StatusEffect in unit.current_statuses:
				ct_gain = status.passive_effect.ct_gain_modifier.apply(ct_gain)
			unit.stats[UnitData.StatType.CT].add_value(ct_gain) 
	
	# execute unit turns, ties decided by unit index in units[]
	# TODO keep looping until all units ct_current < 100
	for unit: UnitData in units:
		if unit.ct_current >= 100:
			safe_to_load_map = false
			await start_units_turn(unit)
			#if unit.is_defeated: # check status that counts as KO, aka prevents turn (dead, petrify, etc.)
				#unit.end_turn()
			if not unit.is_defeated:
				if not unit.is_ai_controlled:
					safe_to_load_map = true
				while not unit.is_ending_turn:
					await get_tree().process_frame
					if unit == null: # prevent error when loading map
						return
				if check_end_conditions():
					safe_to_load_map = true
					return
			safe_to_load_map = true
			await get_tree().process_frame
	
	# TODO increment status ticks, delayed action ticks, and unit ticks in the same step, then order resolution?


func check_end_conditions() -> bool:
	for team: Team in teams:
		team.check_end_conditions(self)
	
	if teams.any(func(team: Team): return team.state == Team.State.WON):
		battle_is_running = false
		return true
	
	return false


func start_units_turn(unit: UnitData) -> void:
	controller.unit = unit
	active_unit = unit
	
	if not unit.is_defeated:
		camera_controller.follow_node = unit.char_body
	
	await unit.start_turn(self)


# TODO handle event timeline
#func process_next_event() -> void:
	#event_num = (event_num + 1) % units.size()
	#var new_unit: UnitData = units[event_num]
	#controller.unit = new_unit
	#phantom_camera.follow_target = new_unit.char_body
	#
	#new_unit.start_turn(self)


func get_map(new_map_data: MapData, map_position: Vector3, map_scale: Vector3, gltf_map_mesh: MeshInstance3D = null) -> Map:
	map_scale.y = -1 # vanilla used -y as up
	var new_map_instance: Map = map_tscn.instantiate()
	new_map_instance.map_data = new_map_data
	
	if gltf_map_mesh != null:
		new_map_instance.mesh.queue_free()
		var new_gltf_mesh: MeshInstance3D = gltf_map_mesh.duplicate()
		new_map_instance.add_child(new_gltf_mesh)
		new_map_instance.mesh = new_gltf_mesh
		new_map_instance.mesh.rotation_degrees = Vector3.ZERO
	else:
		new_map_instance.mesh.mesh = new_map_data.mesh
	new_map_instance.mesh.scale = map_scale
	new_map_instance.position = map_position
	#new_map_instance.global_rotation_degrees = Vector3(0, 0, 0)
	
	new_map_instance.set_mesh_shader(new_map_data.albedo_texture_indexed, new_map_data.texture_palettes)
	
	#var shape_mesh: ConcavePolygonShape3D = new_map_data.mesh.create_trimesh_shape()
	if map_scale == Vector3.ONE:
		new_map_instance.collision_shape.shape = new_map_instance.mesh.mesh.create_trimesh_shape()
	else:
		new_map_instance.collision_shape.shape = get_scaled_collision_shape(new_map_instance.mesh.mesh, map_scale)
	
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


func instantiate_map(map_idx: int, mirror_chunks: bool, offset: Vector3 = Vector3.ZERO) -> Node3D:
	var map_holder: Node3D = Node3D.new()
	
	var map_data: MapData = RomReader.maps[map_idx]
	if not map_data.is_initialized:
		map_data.init_map()
	
	var new_map: Map = get_map(map_data, offset, Vector3(1, 1, 1))
	var map_name: String = map_data.file_name.trim_suffix(".GNS")
	new_map.name = map_name
	new_map.mesh.name = map_name
	
	
	var imported_mesh = GltfManagerNode.import_gltf(new_map.mesh.name)
	if imported_mesh != null:
		new_map.mesh.queue_free()
		new_map.add_child(imported_mesh)
		new_map.mesh = imported_mesh
		new_map.mesh.name = map_name
		new_map.mesh.scale.y = -1
		#imported_mesh.scale = imported_mesh.scale * 0.001 # only needed if Blender scale is set to non-default
		push_warning("Loaded external map: " + new_map.mesh.name + ".glb")
	else:
		GltfManagerNode.save_node(new_map.mesh)
	
	map_holder.add_child(new_map)
	
	if mirror_chunks and allow_mirror:
		map_holder.add_child(get_map(map_data, offset, Vector3(1, 1, -1), imported_mesh))
		map_holder.add_child(get_map(map_data, offset + (Vector3.FORWARD * map_data.map_length * -2), Vector3(1, 1, -1), imported_mesh))
		map_holder.add_child(get_map(map_data, offset, Vector3(-1, 1, -1), imported_mesh))
		map_holder.add_child(get_map(map_data, offset + (Vector3.RIGHT * map_data.map_width * 2), Vector3(-1, 1, -1), imported_mesh))
		map_holder.add_child(get_map(map_data, offset, Vector3(-1, 1, 1), imported_mesh))
		map_holder.add_child(get_map(map_data, offset + (Vector3.FORWARD * map_data.map_length * -2), Vector3(-1, 1, -1), imported_mesh))
		map_holder.add_child(get_map(map_data, offset + (Vector3.RIGHT * map_data.map_width * 2), Vector3(-1, 1, 1), imported_mesh))
		map_holder.add_child(get_map(map_data, offset + (Vector3.RIGHT * map_data.map_width * 2) + (Vector3.FORWARD * map_data.map_length * -2), Vector3(-1, 1, -1), imported_mesh))
	
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
			total_tile.height_mid = total_tile.height_bottom + (total_tile.slope_height / 2.0)
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


func load_random_map_delay(_unit: UnitData) -> void:
	await get_tree().create_timer(3).timeout
	
	load_random_map()


func load_random_map() -> void:
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
	map_input_event.emit(camera, event, event_position, normal, shape_idx)


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

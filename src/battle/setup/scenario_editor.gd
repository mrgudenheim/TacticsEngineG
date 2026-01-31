class_name ScenarioEditor
extends Control

@export var scenario: Scenario = Scenario.new()

@export var battle_manager: BattleManager
@export var start_button: Button
@export var load_scenario_button: Button
@export var unit_scene: PackedScene

@export var background_gradient_color_pickers: Array[ColorPickerButton]
@export var background_gradient_colors: PackedColorArray = []

@export var battle_setup_container: TabContainer
@export var team_setups: Array[TeamSetup]
@export var team_setup_scene: PackedScene

@export var job_select_control: JobSelectControl
@export var item_select_control: ItemSelectControl
@export var ability_select_control: AbilitySelectControl

@export var unit_dragged: Unit
@export var tile_highlight: Node3D
@export var unit_setup: UnitSetupPanel

@export var add_map_chunk_button: Button
@export var map_chunk_settings_container: GridContainer
@export var show_map_tiles_check: CheckBox
@export var map_tile_highlights: Array[Node3D] = []

func _process(delta: float) -> void:
	if unit_dragged != null:
		unit_dragged.char_body.position = battle_manager.current_cursor_map_position + Vector3(0, 0.25, 0)
		
		var cursor_tile: TerrainTile = battle_manager.current_tile_hover
		if tile_highlight != null:
			if cursor_tile == null:
				return
			
			var tile_highlight_pos = tile_highlight.global_position - Vector3(0, 0.025, 0)
			if tile_highlight_pos == cursor_tile.get_world_position(true): # do nothing if tile has not changed
				return
			tile_highlight.queue_free()
		
		var highlight_color: Color = Color.WHITE
		var can_end_on_tile: bool = (cursor_tile.no_walk == 0 
				and cursor_tile.no_stand_select == 0 
				and cursor_tile.no_cursor == 0
				and not unit_dragged.prohibited_terrain.has(cursor_tile.surface_type_id)) # lava, etc.
		if can_end_on_tile:
			highlight_color = Color.BLUE
			
		var new_tile_highlight: MeshInstance3D = cursor_tile.get_tile_mesh()
		new_tile_highlight.material_override = battle_manager.tile_highlights[highlight_color] # use pre-existing materials
		add_child(new_tile_highlight)
		tile_highlight = new_tile_highlight
		new_tile_highlight.position = cursor_tile.get_world_position(true) + Vector3(0, 0.025, 0)


# Input from the subviewport never reaches here...
# func _unhandled_input(event: InputEvent) -> void:
# 	if event.is_action_released("primary_action"): # snap unit to tile when released
# 			# check if unit can end movement on tile
# 			var cursor_tile: TerrainTile = battle_manager.current_tile_hover
# 			var can_end_on_tile: bool = (cursor_tile.no_walk == 0 
# 				and cursor_tile.no_stand_select == 0 
# 				and cursor_tile.no_cursor == 0
# 				and not unit_dragged.prohibited_terrain.has(cursor_tile.surface_type_id)) # lava, etc.
			
# 			if can_end_on_tile:
# 				unit_dragged.tile_position = cursor_tile
			
# 			unit_dragged.char_body.global_position = unit_dragged.tile_position.get_world_position()
# 			unit_dragged = null
# 			tile_highlight.queue_free()


func initial_setup() -> void:
	visible = true
	add_map_chunk_button.pressed.connect(add_map_chunk_settings)
	for color_picker: ColorPickerButton in background_gradient_color_pickers:
		background_gradient_colors.append(color_picker.color)
		color_picker.color_changed.connect(update_background_gradient)
	update_background_gradient()
	
	populate_option_lists()
	add_map_chunk_settings()
	
	for team_setup: TeamSetup in team_setups:
		team_setup.name += "remove"
		team_setup.queue_free()
	team_setups.clear()

	for team_num: int in 2:
		add_team("Team" + str(team_num))
	
	if tile_highlight != null:
		tile_highlight.queue_free()
	unit_setup.setup(battle_manager.units[0]) # default to first unit
	var unit_tile: TerrainTile = battle_manager.units[0].tile_position
	var new_tile_highlight: MeshInstance3D = unit_tile.get_tile_mesh()
	new_tile_highlight.material_override = battle_manager.tile_highlights[Color.BLUE] # use pre-existing materials
	add_child(new_tile_highlight)
	tile_highlight = new_tile_highlight
	new_tile_highlight.position = unit_tile.get_world_position(true) + Vector3(0, 0.025, 0)
	
	if not start_button.pressed.is_connected(battle_manager.start_battle):
		start_button.pressed.connect(battle_manager.start_battle)
	
	if not show_map_tiles_check.toggled.is_connected(show_all_tiles):
		show_map_tiles_check.toggled.connect(show_all_tiles)
	#battle_setup_container.tab_clicked.connect(adjust_height)


func populate_option_lists() -> void:
	job_select_control.populate_list()
	item_select_control.populate_list()
	ability_select_control.populate_list()


func setup_job_select(unit: Unit) -> void:
	job_select_control.visible = true
	for job_select_button: JobSelectButton in job_select_control.job_select_buttons:
		job_select_button.selected.connect(func(new_job: JobData): update_unit_job(unit, new_job))


func desetup_job_select() -> void:
	job_select_control.visible = false
	for job_select_button: JobSelectButton in job_select_control.job_select_buttons:
		Utilities.disconnect_all_connections(job_select_button.selected)


func setup_item_select(unit: Unit, slot: Unit.EquipmentSlot) -> void:
	item_select_control.visible = true
	for item_select_button: ItemSelectButton in item_select_control.item_select_buttons:
		if slot.slot_types.has(item_select_button.item_data.slot_type) and unit.equipable_item_types.has(item_select_button.item_data.item_type):
			item_select_button.visible = true
			item_select_button.selected.connect(func(new_item: ItemData): update_unit_equipment(unit, slot, new_item))
		else:
			item_select_button.visible = false


func desetup_item_select() -> void:
	item_select_control.visible = false
	for item_select_button: ItemSelectButton in item_select_control.item_select_buttons:
		Utilities.disconnect_all_connections(item_select_button.selected)


func setup_ability_select(unit: Unit, slot: Unit.AbilitySlot) -> void:
	ability_select_control.visible = true
	for ability_select_button: AbilitySelectButton in ability_select_control.ability_select_buttons:
		if slot.slot_types.has(ability_select_button.ability_data.slot_type):
			ability_select_button.visible = true
			ability_select_button.selected.connect(func(new_ability: Ability): update_unit_ability(unit, slot, new_ability))
		else:
			ability_select_button.visible = false


func desetup_ability_select() -> void:
	ability_select_control.visible = false
	for ability_select_button: AbilitySelectButton in ability_select_control.ability_select_buttons:
		Utilities.disconnect_all_connections(ability_select_button.selected)


func update_unit_job(unit: Unit, new_job: JobData) -> void:
	unit.set_job_id(new_job.job_id)
	# TODO update stats (apply multipliers, redo growths, etc.)
	
	desetup_job_select()


func update_unit_equipment(unit: Unit, slot: Unit.EquipmentSlot, new_item: ItemData) -> void:
	unit.set_equipment_slot(slot, new_item)
	
	desetup_item_select()


func update_unit_ability(unit: Unit, slot: Unit.AbilitySlot, new_ability: Ability) -> void:
	unit.equip_ability(slot, new_ability)
	
	desetup_ability_select()


func add_map_chunk_settings() -> void:
	var map_chunk_settings: MapChunkSettingsUi = MapChunkSettingsUi.instantiate()
	map_chunk_settings.map_chunk_nodes_changed.connect(update_map_chunk_nodes)
	map_chunk_settings.map_chunk_settings_changed.connect(update_map)
	map_chunk_settings.add_row_to_table(map_chunk_settings_container)
	scenario.map_chunks.append(map_chunk_settings.map_chunk)
	add_child(map_chunk_settings)


func update_map_chunk_nodes(new_map_chunk_settings: MapChunkSettingsUi) -> void:
	battle_manager.maps.add_child(new_map_chunk_settings.map_chunk_nodes)

	new_map_chunk_settings.map_chunk_nodes.play_animations(new_map_chunk_settings.map_chunk_nodes.map_data)
	new_map_chunk_settings.map_chunk_nodes.input_event.connect(battle_manager.on_map_input_event)
	new_map_chunk_settings.map_chunk_nodes.position = new_map_chunk_settings.map_chunk.corner_position

	update_map(new_map_chunk_settings)


func update_map(new_map_chunk_settings: MapChunkSettingsUi) -> void:
	if new_map_chunk_settings.is_queued_for_deletion():
		scenario.map_chunks.erase(new_map_chunk_settings.map_chunk)
	
	show_all_tiles(false)
	battle_manager.update_total_map_tiles(scenario.map_chunks)
	update_unit_positions(battle_manager.units)
	show_all_tiles(show_map_tiles_check.button_pressed)


func update_unit_positions(units: Array[Unit]) -> void:
	for unit: Unit in units:
		if battle_manager.total_map_tiles.keys().has(unit.tile_position.location):
			unit.tile_position = battle_manager.total_map_tiles[unit.tile_position.location][0]
		else: # find nearest tile
			var shortest_distance2: int = 9999
			var closest_tile: TerrainTile = battle_manager.total_map_tiles.values()[0][0]
			for xy: Vector2i in battle_manager.total_map_tiles.keys():
				var this_distance2: int = xy.distance_squared_to(unit.tile_position.location)
				if this_distance2 < shortest_distance2:
					shortest_distance2 = this_distance2
					closest_tile = battle_manager.total_map_tiles[xy][0]
			unit.tile_position = closest_tile

		unit.set_position_to_tile()


func update_background_gradient(_new_color: Color = Color.BLACK) -> void:
	background_gradient_colors.clear()
	for color_picker: ColorPickerButton in background_gradient_color_pickers:
		background_gradient_colors.append(color_picker.color)
	
	battle_manager.background_gradient.texture.gradient.colors = background_gradient_colors
	scenario.background_gradient_bottom = background_gradient_colors[0]
	scenario.background_gradient_top = background_gradient_colors[1]


func add_team(new_team_name: String) -> Team:
	var new_team: Team = Team.new()
	battle_manager.teams.append(new_team)
	new_team.team_name = new_team_name
	
	var new_team_setup: TeamSetup = team_setup_scene.instantiate()
	battle_setup_container.add_child(new_team_setup)
	team_setups.append(new_team_setup)
	
	new_team_setup.unit_job_select_pressed.connect(setup_job_select)
	new_team_setup.unit_item_select_pressed.connect(setup_item_select)
	new_team_setup.unit_ability_select_pressed.connect(setup_ability_select)
	new_team_setup.need_new_unit.connect(battle_manager.spawn_random_unit)
	battle_manager.unit_created.connect(new_team_setup.add_unit_setup)
	
	new_team_setup.setup(new_team)
	
	return new_team


func show_all_tiles(show_tiles: bool = true, highlight_color: Color = Color.WHITE) -> void:
	for tile_highlight_node: Node3D in map_tile_highlights:
		tile_highlight_node.queue_free()
	
	map_tile_highlights.clear()
	if not show_tiles:
		return
	
	for tile_stack: Array in battle_manager.total_map_tiles.values():
		for tile: TerrainTile in tile_stack:
			var can_end_on_tile: bool = (tile.no_walk == 0 
					and tile.no_stand_select == 0 
					and tile.no_cursor == 0)
			if can_end_on_tile:
				highlight_color = Color.BLUE
				
			var new_tile_highlight: MeshInstance3D = tile.get_tile_mesh()
			new_tile_highlight.material_override = battle_manager.tile_highlights[highlight_color] # use pre-existing materials
			add_child.call_deferred(new_tile_highlight) # defer the call for when this function is called from _on_exit_tree
			tile_highlight = new_tile_highlight
			new_tile_highlight.position = tile.get_world_position(true) + Vector3(0, 0.025, 0)

			map_tile_highlights.append(new_tile_highlight)


func adjust_height(tab_idx: int) -> void:
	push_warning(str(tab_idx))
	if tab_idx == 0:
		battle_setup_container.size.y = 0
		await get_tree().process_frame
		battle_setup_container.position.y = 0
	else:
		battle_setup_container.offset_bottom = 0


func update_unit_dragging(unit: Unit, event: InputEvent) -> void:
	if event.is_action_pressed("primary_action") and unit_dragged == null:
		unit_dragged = unit # TODO only drag one unit at a time
		unit_setup.setup(unit)
		unit_setup.visible = true
		# unit.char_body is moved in _process
	elif event.is_action_released("primary_action") and unit_dragged != null: # snap unit to tile when released
		# check if unit can end movement on tile
		var tile: TerrainTile = battle_manager.current_tile_hover
		var can_end_on_tile: bool = tile.no_walk == 0 and tile.no_stand_select == 0 and tile.no_cursor == 0
		if can_end_on_tile and not unit.prohibited_terrain.has(tile.surface_type_id): # lava, etc.
			unit.tile_position = battle_manager.get_tile(battle_manager.current_cursor_map_position)
		
		unit.char_body.global_position = unit.tile_position.get_world_position()
		unit_dragged = null
		# tile_highlight.queue_free()

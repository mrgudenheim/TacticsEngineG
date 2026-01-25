class_name BattleSetupUi
extends Control

@export var battle_manager: BattleManager
@export var start_button: Button
@export var unit_scene: PackedScene

@export var battle_setup_container: TabContainer
@export var team_setups: Array[TeamSetup]
@export var team_setup_scene: PackedScene

@export var job_select_control: JobSelectControl
@export var item_select_control: ItemSelectControl
@export var ability_select_control: AbilitySelectControl

@export var unit_dragged: UnitData
@export var tile_highlight: Node3D
@export var unit_setup: UnitSetupPanel

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
	
	populate_option_lists()
	
	for team_num: int in 2:
		add_team("Team" + str(team_num))
	
	unit_setup.setup(battle_manager.units[0]) # default to first unit
	
	if not start_button.pressed.is_connected(battle_manager.start_battle):
		start_button.pressed.connect(battle_manager.start_battle)
	#battle_setup_container.tab_clicked.connect(adjust_height)


func populate_option_lists() -> void:
	job_select_control.populate_list()
	item_select_control.populate_list()
	ability_select_control.populate_list()


func setup_job_select(unit: UnitData) -> void:
	job_select_control.visible = true
	for job_select_button: JobSelectButton in job_select_control.job_select_buttons:
		job_select_button.selected.connect(func(new_job: JobData): update_unit_job(unit, new_job))


func desetup_job_select() -> void:
	job_select_control.visible = false
	for job_select_button: JobSelectButton in job_select_control.job_select_buttons:
		Utilities.disconnect_all_connections(job_select_button.selected)


func setup_item_select(unit: UnitData, slot: UnitData.EquipmentSlot) -> void:
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


func setup_ability_select(unit: UnitData, slot: UnitData.AbilitySlot) -> void:
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


func update_unit_job(unit: UnitData, new_job: JobData) -> void:
	unit.set_job_id(new_job.job_id)
	# TODO update stats (apply multipliers, redo growths, etc.)
	
	desetup_job_select()


func update_unit_equipment(unit: UnitData, slot: UnitData.EquipmentSlot, new_item: ItemData) -> void:
	unit.set_equipment_slot(slot, new_item)
	
	desetup_item_select()


func update_unit_ability(unit: UnitData, slot: UnitData.AbilitySlot, new_ability: Ability) -> void:
	unit.equip_ability(slot, new_ability)
	
	desetup_ability_select()


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


func adjust_height(tab_idx: int) -> void:
	push_warning(str(tab_idx))
	if tab_idx == 0:
		battle_setup_container.size.y = 0
		await get_tree().process_frame
		battle_setup_container.position.y = 0
	else:
		battle_setup_container.offset_bottom = 0


func update_unit_dragging(unit: UnitData, event: InputEvent) -> void:
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
		tile_highlight.queue_free()

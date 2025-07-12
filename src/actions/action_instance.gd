class_name ActionInstance
extends RefCounted

signal action_completed(battle_manager: BattleManager)
signal tile_hovered(tile: TerrainTile, action_instance: ActionInstance)

var action: Action
var user: UnitData
var battle_manager: BattleManager

var potential_targets: Array[TerrainTile]
var potential_targets_highlights: Dictionary[TerrainTile, Node3D]
var preview_targets: Array[TerrainTile]
var preview_targets_highlights: Dictionary[TerrainTile, Node3D]
var submitted_targets: Array[TerrainTile]

var current_tile_hovered: TerrainTile
var potential_targets_are_set: bool = false

var action_preview_scene: PackedScene = preload("res://src/actions/action_preview.tscn")
var action_previews: Array[ActionPreview] = []

func _init(new_action: Action, new_user: UnitData, new_battle_manager: BattleManager) -> void:
	action = new_action
	user = new_user
	battle_manager = new_battle_manager


func duplicate() -> ActionInstance:
	var new_action_instance = ActionInstance.new(action, user, battle_manager)
	new_action_instance.potential_targets = potential_targets.duplicate()
	new_action_instance.preview_targets = preview_targets.duplicate()
	new_action_instance.submitted_targets = submitted_targets.duplicate()
	new_action_instance.current_tile_hovered = current_tile_hovered
	
	return new_action_instance


func clear() -> void:
	clear_targets(potential_targets_highlights)
	potential_targets.clear()
	
	clear_targets(preview_targets_highlights)
	preview_targets.clear()
	
	submitted_targets.clear()


func clear_targets(target_highlights: Dictionary[TerrainTile, Node3D]) -> void:
	for highlight: Node3D in target_highlights.values():
		highlight.queue_free()
	
	target_highlights.clear()


func is_usable() -> bool:
	return action.is_usable(self)


func update_potential_targets() -> void:
	clear_targets(potential_targets_highlights)
	potential_targets.clear()
	
	potential_targets = await action.targeting_strategy.get_potential_targets(self)
	update_potential_targets_highlights()
	
	potential_targets_are_set = true


func update_potential_targets_highlights() -> void:
	var highlight_material: Material = battle_manager.tile_highlights[Color.WHITE]
	if is_usable():
		highlight_material = battle_manager.tile_highlights[Color.BLUE]
	
	potential_targets_highlights = get_tile_highlights(potential_targets, highlight_material)


func show_potential_targets() -> void:
	if not potential_targets_are_set:
		update_potential_targets()
	show_targets_highlights(potential_targets_highlights)


func hide_potential_targets() -> void:
	show_targets_highlights(potential_targets_highlights, false)


func show_targets_highlights(targets_highlights: Dictionary[TerrainTile, Node3D], show: bool = true) -> void:
	for highlight: Node3D in targets_highlights.values():
		highlight.visible = show


# TODO implement generic actions that can have tiles as targets, use this to highlight targets
func get_tile_highlights(tiles: Array[TerrainTile], highlight_material: Material) -> Dictionary[TerrainTile, Node3D]:
	var tile_highlights: Dictionary[TerrainTile, Node3D]
	for tile: TerrainTile in tiles:
		var new_tile_highlight: MeshInstance3D = tile.get_tile_mesh()
		new_tile_highlight.material_override = highlight_material # use pre-existing materials
		user.tile_highlights.add_child(new_tile_highlight)
		new_tile_highlight.position = tile.get_world_position(true) + Vector3(0, 0.025, 0)
		new_tile_highlight.visible = false
		tile_highlights[tile] = new_tile_highlight
	
	return tile_highlights


func start_targeting() -> void:
	user.global_battle_manager.game_state_label.text = user.job_nickname + "-" + user.unit_nickname + " targeting " + action.action_name
	
	# cancel any current targeting
	if is_instance_valid(user.active_action):
		user.active_action.stop_targeting()
	user.active_action = self
	action.targeting_strategy.start_targeting(self)


func stop_targeting() -> void:
	show_targets_highlights(potential_targets_highlights, false)
	show_targets_highlights(preview_targets_highlights, false)
	clear_targets(preview_targets_highlights)
	
	for preview: ActionPreview in action_previews:
		preview.queue_free()
	action_previews.clear()
	
	action.targeting_strategy.stop_targeting(self)


func get_target_units(target_tiles: Array[TerrainTile]) -> Array[UnitData]:
	var target_units: Array[UnitData] = []
	for target_tile: TerrainTile in target_tiles:
		var units_on_tile: Array[UnitData] = battle_manager.units.filter(func(unit: UnitData): return unit.tile_position == target_tile)
		target_units.append_array(units_on_tile)
		#if unit_index == -1:
			#continue
		#var target_unit: UnitData = battle_manager.units[unit_index]
		#target_units.append(target_unit)
	
	return target_units


func get_ai_score() -> int:
	var ai_score: int = 0
	var target_units: Array[UnitData] = get_target_units(preview_targets)
	
	for target: UnitData in target_units:
		var target_score: float = 0.0
		for action_effect: ActionEffect in action.target_effects:
			var effect_value: int = action_effect.get_ai_value(user, target, action.element)
			target_score += effect_value
		
		var evade_direction: EvadeData.Directions = action.get_evade_direction(user, target)
		var hit_chance_value: int = action.get_total_hit_chance(user, target, evade_direction)
		hit_chance_value = clamp(hit_chance_value, 0, 100)
		target_score = target_score * (hit_chance_value / 100.0)
		
		# TODO status scores
		RomReader.battle_bin_data.ai_status_priorities
		
		ai_score += roundi(target_score)
		#push_warning(action.action_name + " " + str(preview_targets) + " " + str(ai_score))
	
	return ai_score


func show_result_preview(target: UnitData) -> ActionPreview:
	var hit_chance_text: String = get_hit_chance_text(target)
	var effects_text: String = get_effects_text(target)
	var statuses_text: String = get_statuses_text(target)
	var secondary_actions_text: String = get_secondary_actions_text(target)
	
	var all_text: PackedStringArray = [hit_chance_text, effects_text, statuses_text, secondary_actions_text]
	for text_idx: int in range(all_text.size() - 1, -1, -1):
		if all_text[text_idx] == "":
			all_text.remove_at(text_idx)
	
	var total_preview_text: String = "\n".join(all_text)
	
	var preview: ActionPreview = action_preview_scene.instantiate()
	preview.label.text = total_preview_text
	preview.unit = target
	target.char_body.add_child(preview)
	
	action_previews.append(preview)
	
	return preview


func get_hit_chance_text(target: UnitData) -> String:
	# hit chance preview
	var evade_direction: EvadeData.Directions = action.get_evade_direction(user, target)
	var hit_chance_value: int = action.get_total_hit_chance(user, target, evade_direction)
	var hit_chance_text: String = str(hit_chance_value) + "% Hit"
	
	return hit_chance_text


func get_effects_text(target: UnitData) -> String:
	# effect preview
	var all_effects_text: PackedStringArray = []
	for action_effect: ActionEffect in action.target_effects:
		var effect_value: int = action_effect.get_value(user, target, action.element)
		var effect_text: String = action_effect.get_text(effect_value)
		all_effects_text.append(effect_text)
	
	var total_effect_text: String = "/n".join(all_effects_text)
	return total_effect_text


func get_statuses_text(target: UnitData) -> String:
	# status preview
	if action.taregt_status_list.is_empty():
		return ""
	
	var status_chance: String = str(action.status_chance) + "%"
	var remove_status: String = ""
	if action.will_remove_status:
		remove_status = "Remove "
	var status_group_type: String = Action.StatusListType.keys()[action.target_status_list_type] + " "
	if action.taregt_status_list.size() < 2:
		status_group_type = "" # don't mention group type if 1 or less status
	
	var status_names: PackedStringArray = []
	for status: StatusEffect in action.taregt_status_list:
		if not action.will_remove_status or target.current_statuses2.keys().has(status): # don't show removing status the target does not have TODO don't show remove Always statuses
			status_names.append(status.status_effect_name)
	
	if status_names.is_empty() and action.will_remove_status:
		status_names = ["[No status to remove]"]
	
	var total_status_text: String = status_chance + " " + remove_status + status_group_type + ", ".join(status_names)
	return total_status_text


func get_secondary_actions_text(target: UnitData) -> String:
	# TODO show effects and statuses from secondary actions?
	if action.secondary_actions2.is_empty():
		return ""
	
	var total_secondary_action_text: String = Action.StatusListType.keys()[action.secondary_action_list_type] + "\n"
	if action.secondary_actions2.size() < 2:
		total_secondary_action_text = "" # don't show list type if only 1 entry in list
	
	var all_secondary_action_text: PackedStringArray = []
	for secondary_action: Action.SecondaryAction in action.secondary_actions2:
		var secondary_action_chance: String = str(secondary_action.chance) + "%"
		#var secondary_action_effect_text: String = secondary_action.ac # TODO get effect text of secondary action?
		var secondary_action_text: String = secondary_action_chance + " " + secondary_action.action.action_name
		all_secondary_action_text.append(secondary_action_text)
	
	total_secondary_action_text += "\n".join(all_secondary_action_text)
	return total_secondary_action_text


func on_map_input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	#push_warning(event_position)
	var tile: TerrainTile = battle_manager.get_tile(event_position)
	if tile == null:
		return
	
	tile_hovered.emit(tile, self, event)


func on_unit_hovered(unit: UnitData, event: InputEvent):
	var tile: TerrainTile = unit.tile_position
	if tile == null:
		return
	
	tile_hovered.emit(tile, self, event)


func queue_use() -> void:
	battle_manager.game_state_label.text = user.job_nickname + "-" + user.unit_nickname + " using " + action.action_name
	user.clear_action_buttons(battle_manager)
	pay_action_point_costs()
	face_target()
	if action.ticks_charge_time > 0:
		var charging_status: StatusEffect = RomReader.status_effects[4].duplicate() # charging
		charging_status.delayed_action = self.duplicate()
		charging_status.duration = action.ticks_charge_time
		if charging_status.delayed_action.action_completed.is_connected(charging_status.delayed_action.user.update_actions):
			charging_status.delayed_action.action_completed.disconnect(charging_status.delayed_action.user.update_actions)
		user.add_status(charging_status)
		
		stop_targeting()
		action_completed.emit(battle_manager)
	else:
		use()


func use() -> void:
	stop_targeting()
	
	await action.use(self)


func pay_action_point_costs() -> void:
	user.move_points_remaining -= action.move_points_cost
	user.action_points_remaining -= action.action_points_cost


func face_target() -> void:
	if submitted_targets.is_empty():
		push_warning(action.action_name + ": no submitted targets")
		return
	
	if submitted_targets[0] != user.tile_position:
		var direction_to_target: Vector2i = submitted_targets[0].location - user.tile_position.location
		user.update_unit_facing(Vector3(direction_to_target.x, 0, direction_to_target.y))

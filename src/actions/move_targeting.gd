class_name MoveTargeting
extends TargetingStrategy


func get_potential_targets(action_instance: ActionInstance) -> Array[TerrainTile]:
	var potential_targets: Array[TerrainTile] = []
	#action_instance.user.get_map_paths(action_instance.battle_manager.total_map_tiles, action_instance.battle_manager.units)
	
	for tile: TerrainTile in action_instance.user.path_costs.keys():
		if tile == action_instance.user.tile_position:
			continue
		if action_instance.user.path_costs[tile] > action_instance.user.move_current:
			continue # don't highlight tiles beyond move range
		potential_targets.append(tile)
	
	return potential_targets


func start_targeting(action_instance: ActionInstance) -> void:
	super.start_targeting(action_instance)
	
	action_instance.battle_manager.map_input_event.connect(on_map_input_event)


func stop_targeting(action_instance: ActionInstance) -> void:
	if action_instance.battle_manager.map_input_event.is_connected(on_map_input_event):
		action_instance.battle_manager.map_input_event.disconnect(on_map_input_event)


func clear_path(path_highlight_containers: Array[Node3D]) -> void:
	for container: Node3D in path_highlight_containers:
		if is_instance_valid(container):
			container.queue_free()


func on_map_input_event(action_instance: ActionInstance, camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	#push_warning(event_position)
	var tile: TerrainTile = action_instance.battle_manager.get_tile(event_position)
	
	# don't update path if hovered tile has not changed or is not valid for moving
	if tile == null or action_instance.user.map_paths.is_empty():
		return
	
	# handle hovering over new tile
	if tile != action_instance.current_tile_hovered:
		action_instance.current_tile_hovered = tile
		
		# show preview path
		var path: Array[TerrainTile] = action_instance.user.get_map_path(action_instance.user.tile_position, tile, action_instance.user.map_paths)
		var path_in_range: Array[TerrainTile] = path.filter(func(tile: TerrainTile): return action_instance.user.path_costs[tile] <= action_instance.user.move_current)
		var path_out_of_range: Array[TerrainTile] = path.filter(func(tile: TerrainTile): return action_instance.user.path_costs[tile] > action_instance.user.move_current)
		
		action_instance.clear_targets(action_instance.preview_targets_highlights)
		action_instance.preview_targets.clear()
		
		action_instance.preview_targets.append(tile)
		
		action_instance.preview_targets_highlights.merge(action_instance.get_tile_highlights(path_in_range, action_instance.battle_manager.tile_highlights[Color.BLUE]))
		action_instance.preview_targets_highlights.merge(action_instance.get_tile_highlights(path_out_of_range, action_instance.battle_manager.tile_highlights[Color.WHITE]))
		action_instance.show_targets_highlights(action_instance.preview_targets_highlights)
	
	# handle clicking tile
	if event.is_action_pressed("primary_action"):
		if action_instance.user.path_costs.has(tile):
			if action_instance.user.path_costs[tile] <= action_instance.user.move_current:
				action_instance.submitted_targets.append(tile)
				action_instance.use()
				return

# TODO move get_map_paths and related function from UnitData, allow cost based on Unit Move value or action range value

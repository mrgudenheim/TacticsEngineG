class_name MoveTargeting
extends TargetingStrategy


func _get_potential_targets(action_instance: ActionInstance) -> Array:
	var valid_targets: Array[TerrainTile] = []
	
	for tile: TerrainTile in action_instance.user.path_costs.keys():
		if tile == action_instance.user.tile_position:
			continue
		if action_instance.user.path_costs[tile] > action_instance.user.move_current:
			continue # don't highlight tiles beyond move range
		valid_targets.append(tile)
	
	var potential_target_highlights: Node3D = highlight_tiles(valid_targets, action_instance.battle_manager.tile_highlights[Color.BLUE])
	action_instance.potential_targets.append(potential_target_highlights)
	action_instance.add_child(potential_target_highlights)
	
	return valid_targets


func _start_targeting(action_instance: ActionInstance) -> void:
	_get_potential_targets(action_instance)
	
	action_instance.battle_manager.map_input_event.connect(on_map_input_event)


#func _stop_targeting(action_instance: ActionInstance) -> void:	
	##push_error("Using base TargetingStrategy instead of specific targeting strategy")
	#pass


#func _submit_target(target) -> void:
	##push_error("Using base TargetingStrategy instead of specific targeting strategy")
	#pass


func clear_path(path_highlight_containers: Array[Node3D]) -> void:
	for container: Node3D in path_highlight_containers:
		container.queue_free()


func on_map_input_event(action_instance: ActionInstance, camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	#push_warning(event_position)
	var tile: TerrainTile = action_instance.battle_manager.get_tile(event_position)
	
	if action_instance.user.is_traveling_path: # TODO handle allowable inputs somewhere else
		return
	
	# handle clicking tile
	if event.is_action_pressed("primary_action"):
		if action_instance.user.path_costs.has(tile):
			if action_instance.user.path_costs[tile] <= action_instance.user.move_current:
				var map_path: Array[TerrainTile] = action_instance.user.get_map_path(action_instance.user.tile_position, tile, action_instance.user.map_paths)
				action_instance.user.clear_tile_highlights(action_instance.user.tile_highlights)
				await action_instance.user.travel_path(map_path)
				clear_path(action_instance.preview_targets)
				#controller.unit.map_paths = controller.unit.get_map_paths(total_map_tiles)
				return
	
	# handle hovering over tile
	# don't update path if hovered tile has not changed or is not valid for moving
	if tile == null or tile == action_instance.current_tile_hovered:
		return
	action_instance.current_tile_hovered = tile
	
	# show path
	clear_path(action_instance.preview_targets)
	
	#controller.unit.map_paths = controller.unit.get_map_paths(total_map_tiles) # DONT for every tile hover, do once and cache
	if action_instance.user.map_paths.is_empty():
		return
	
	var path: Array[TerrainTile] = action_instance.user.get_map_path(action_instance.user.tile_position, tile, action_instance.user.map_paths)
	var path_in_range: Array[TerrainTile] = path.filter(func(tile: TerrainTile): return action_instance.user.path_costs[tile] <= action_instance.user.move_current)
	var path_out_of_range: Array[TerrainTile] = path.filter(func(tile: TerrainTile): return action_instance.user.path_costs[tile] > action_instance.user.move_current)
	
	var path_in_range_highlights: Node3D = highlight_tiles(path_in_range, action_instance.battle_manager.tile_highlights[Color.BLUE])
	var path_out_of_range_highlights: Node3D = highlight_tiles(path_out_of_range, action_instance.battle_manager.tile_highlights[Color.WHITE])
	action_instance.preview_targets.append(path_in_range_highlights)
	action_instance.preview_targets.append(path_out_of_range_highlights)
	
	action_instance.battle_manager.add_child(action_instance)
	
	#for path_tile: TerrainTile in path:
		#var new_tile_selector: MeshInstance3D = path_tile.get_tile_mesh()
		#new_tile_selector.material_override = tile_highlights[Color.BLUE] # use pre-existing materials
		#if action_instance.user.path_costs[path_tile] > action_instance.user.move_current:
			#new_tile_selector.material_override = tile_highlights[Color.WHITE] # use pre-existing materials
		#path_container.add_child(new_tile_selector)
		#new_tile_selector.global_position = path_tile.get_world_position(true) + Vector3(0, 0.05, 0)
	
	#push_warning()

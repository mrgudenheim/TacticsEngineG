class_name RangeTargeting
extends TargetingStrategy


func get_potential_targets(action_instance: ActionInstance) -> Array[TerrainTile]:
	var potential_targets: Array[TerrainTile] = []
	#action_instance.user.get_map_paths(action_instance.battle_manager.total_map_tiles, action_instance.battle_manager.units)
	
	var min_tile_pos: Vector2i = action_instance.user.tile_position.location - Vector2i(action_instance.action.max_targeting_range, action_instance.action.max_targeting_range)
	var max_tile_pos: Vector2i = action_instance.user.tile_position.location + Vector2i(action_instance.action.max_targeting_range, action_instance.action.max_targeting_range)
	
	for map_x: int in range(min_tile_pos.x, max_tile_pos.x + 1):
		for map_y: int in range(min_tile_pos.y, max_tile_pos.y + 1):
			var map_pos: Vector2i = Vector2i(map_x, map_y)
			if action_instance.battle_manager.total_map_tiles.has(map_pos):
				var relative_pos: Vector2i = map_pos - action_instance.user.tile_position.location
				var distance_xy: int = abs(relative_pos.x) + abs(relative_pos.y)
				
				if action_instance.action.targeting_linear:
					if relative_pos.x != 0 and relative_pos.y != 0:
						continue
				
				var min_height: float = 0
				if action_instance.action.targeting_top_down:
					var map_tiles_at_pos: Array[TileData] = action_instance.battle_manager.total_map_tiles[map_pos].duplicate()
					if map_tiles_at_pos.size() > 1:
						map_tiles_at_pos.sort_custom(func(a: TileData, b: TileData): return a.height_mid > b.height_mid)
						min_height = map_tiles_at_pos[0].height_mid
						
				
				for tile in action_instance.battle_manager.total_map_tiles[map_pos]:
					if action_instance.action.targeting_top_down and tile.height_mid < min_height:
						continue
					
					var distance_vert: float = tile.height_mid - action_instance.user.tile_position.height_mid
					if action_instance.action.targeting_direct:
						var collider = Raycaster.raycast(action_instance.user.tile_position.get_world_position() + Vector3.UP, tile.get_world_position() + Vector3.UP) # TODO adjust for different height sprites: chicken, frog, Altima
						if not is_instance_valid(collider):
							if collider is CharacterBody3D:
								var intersected_unit: UnitData = collider.get_parent_node_3d()
								if intersected_unit.tile_position != tile:
									continue
						# TODO fix raycast?
					if action_instance.action.cant_target_self and tile == action_instance.user.tile_position:
						continue
					elif distance_xy >= action_instance.action.min_targeting_range and distance_xy <= action_instance.action.max_targeting_range:
						if not action_instance.action.has_vertical_tolerance_from_user:
							potential_targets.append(tile)
						elif abs(distance_vert) <= action_instance.action.vertical_tolerance:
							potential_targets.append(tile)
					
					# TODO arc https://ffhacktics.com/wiki/Arc_Range_Calculation_Routine
					# TODO aoe flags: linear, 3 directions, direct, vertical tolerance, top-down
	
	return potential_targets


func start_targeting(action_instance: ActionInstance) -> void:
	super.start_targeting(action_instance)
	
	action_instance.battle_manager.map_input_event.connect(on_map_input_event)


func stop_targeting(action_instance: ActionInstance) -> void:
	if action_instance.battle_manager.map_input_event.is_connected(on_map_input_event):
		action_instance.battle_manager.map_input_event.disconnect(on_map_input_event)


func on_map_input_event(action_instance: ActionInstance, camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	#push_warning(event_position)
	var tile: TerrainTile = action_instance.battle_manager.get_tile(event_position)
	# TODO preview target highlighting
	if tile == null:
		return
	
	if tile != action_instance.current_tile_hovered:
		action_instance.current_tile_hovered = tile
		
		# show preview targets
		action_instance.clear_targets(action_instance.preview_targets_highlights)
		action_instance.preview_targets.clear()
		
		action_instance.preview_targets.append(tile)
		# TODO get aoe targets
		# TODO if targeting_direct and distance > 1, show line
		
		if action_instance.potential_targets.has(tile):
			action_instance.preview_targets_highlights = action_instance.get_tile_highlights(action_instance.preview_targets, action_instance.battle_manager.tile_highlights[Color.RED])
		else:
			action_instance.preview_targets_highlights = action_instance.get_tile_highlights(action_instance.preview_targets, action_instance.battle_manager.tile_highlights[Color.WHITE])
		
		action_instance.show_targets_highlights(action_instance.preview_targets_highlights)
	
	if not action_instance.potential_targets.has(tile):
		return
	
	# handle clicking tile
	if event.is_action_pressed("primary_action"):
		action_instance.submitted_targets = action_instance.preview_targets
		#action_instance.submitted_targets.append(tile)
		action_instance.use()
		return

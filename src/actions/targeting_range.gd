class_name RangeTargeting
extends TargetingStrategy

# TODO Arc https://ffhacktics.com/wiki/Arc_Range_Calculation_Routine

func get_potential_targets(action_instance: ActionInstance) -> Array[TerrainTile]:
	var potential_targets: Array[TerrainTile] = []
	#action_instance.user.get_map_paths(action_instance.battle_manager.total_map_tiles, action_instance.battle_manager.units)
	
	var min_tile_pos: Vector2i = action_instance.user.map_position - Vector2i(action_instance.action.max_targeting_range, action_instance.action.max_targeting_range)
	var max_tile_pos: Vector2i = action_instance.user.map_position + Vector2i(action_instance.action.max_targeting_range, action_instance.action.max_targeting_range)
	
	for map_x: int in range(min_tile_pos.x, max_tile_pos.x + 1):
		for map_y: int in range(min_tile_pos.y, max_tile_pos.y + 1):
			var map_pos: Vector2i = Vector2i(map_x, map_y)
			if action_instance.battle_manager.total_map_tiles.has(map_pos):
				var relative_pos: Vector2i = map_pos - action_instance.user.map_position
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
						
				
				for tile: TileData in action_instance.battle_manager.total_map_tiles[map_pos]:
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
						# TODO raycast from action_instance.user.tile_position + 0.5? to tile.world_position + 0.5?
					if action_instance.action.cant_target_self and tile == action_instance.user.tile_position:
						continue
					elif distance_xy >= action_instance.action.min_targeting_range and distance_xy <= action_instance.action.max_targeting_range:
						if not action_instance.action.has_vertical_tolerance_from_user:
							potential_targets.append(tile)
						elif abs(distance_vert) <= action_instance.action.vertical_tolerance:
							potential_targets.append(tile)
					
					# TODO direct (raycast), arc
					# TODO aoe flags: linear, 3 directions, direct, vertical tolerance, top-down
	
	return potential_targets


func start_targeting(action_instance: ActionInstance) -> void:
	action_instance.show_targets_highlights(action_instance.potential_targets_highlights)


func stop_targeting(action_instance: ActionInstance) -> void:
	push_error("Using base TargetingStrategy instead of specific targeting strategy")

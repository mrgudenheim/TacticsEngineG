class_name TargetingStrategy
extends Resource

# TODO implement TargetingStrategy

func _get_potential_targets(action_instance: ActionInstance) -> Array:
	push_error("Using base TargetingStrategy instead of specific targeting strategy")
	return []


func _start_targeting(action_instance: ActionInstance) -> void:
	push_error("Using base TargetingStrategy instead of specific targeting strategy")
	pass


func _stop_targeting(action_instance: ActionInstance) -> void:
	action_instance.queue_free()
	#for child: Node3D in action_instance.potential_targets:
		#child.queue_free()
	#
	#for child: Node3D in action_instance.preview_targets:
		#child.queue_free()
	#
	#for child: Node3D in action_instance.submitted_targets:
		#child.queue_free()
	
	push_error("Using base TargetingStrategy instead of specific targeting strategy")
	pass


func _submit_target(target) -> void:
	push_error("Using base TargetingStrategy instead of specific targeting strategy")
	pass


# TODO implement generic actions that can have tiles as targets, use this to highlight targets
func highlight_tiles(tiles: Array[TerrainTile], highlight_material: Material) -> Node3D:
	#var highlights: Array[MeshInstance3D] = []
	#highlights.resize(tiles.size())
	
	var new_highlights_container: Node3D = Node3D.new()
	
	for tile: TerrainTile in tiles:
		var new_tile_highlight: MeshInstance3D = tile.get_tile_mesh()
		new_tile_highlight.material_override = highlight_material # use pre-existing materials
		new_highlights_container.add_child(new_tile_highlight)
		#highlights.append(new_tile_highlight)
		new_tile_highlight.position = tile.get_world_position(true) + Vector3(0, 0.025, 0)
	
	return new_highlights_container

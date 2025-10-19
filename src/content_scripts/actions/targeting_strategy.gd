# TODO make abstract? in Godot 4.5 https://github.com/godotengine/godot-proposals/issues/5641
class_name TargetingStrategy
extends Resource

func get_potential_targets(action_instance: ActionInstance) -> Array[TerrainTile]:
	push_error("Using base TargetingStrategy instead of specific targeting strategy")
	return []


func get_aoe_targets(action_instance: ActionInstance, tile_target: TerrainTile) -> Array[TerrainTile]:
	push_error("Using base TargetingStrategy get_aoe_targets instead of specific targeting strategy")
	return []


func start_targeting(action_instance: ActionInstance) -> void:
	action_instance.show_targets_highlights(action_instance.potential_targets_highlights)


func stop_targeting(action_instance: ActionInstance) -> void:
	push_error("Using base TargetingStrategy instead of specific targeting strategy")

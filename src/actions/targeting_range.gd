class_name RangeTargeting
extends TargetingStrategy

func get_potential_targets(action_instance: ActionInstance) -> Array[TerrainTile]:
	push_error("Using base TargetingStrategy instead of specific targeting strategy")
	return []


func start_targeting(action_instance: ActionInstance) -> void:
	action_instance.show_targets_highlights(action_instance.potential_targets_highlights)


func stop_targeting(action_instance: ActionInstance) -> void:
	push_error("Using base TargetingStrategy instead of specific targeting strategy")

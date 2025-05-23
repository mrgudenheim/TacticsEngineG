class_name MoveUsable
extends UseableStrategy

func is_usable(action_instance: ActionInstance) -> bool:
	return action_instance.user.move_points_remaining - action_instance.action.move_points_cost >= 0

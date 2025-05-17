class_name ActionButton
extends Button

var action_instance: ActionInstance

func _init(new_action_instance: ActionInstance) -> void:
	action_instance = new_action_instance
	
	text = action_instance.action.action_name
	name = action_instance.action.action_name
	
	pressed.connect(action_instance.start_targeting)
	focus_entered.connect(action_instance.user.active_action.stop_targeting)
	focus_entered.connect(action_instance.show_potential_targets)
	
	focus_exited.connect(action_instance.hide_potential_targets)
	focus_exited.connect(action_instance.user.active_action.start_targeting)
	

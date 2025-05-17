class_name ActionButton
extends Button

var action_instance: ActionInstance

func _init(new_action_instance: ActionInstance) -> void:
	action_instance = new_action_instance
	
	text = action_instance.action.action_name
	name = action_instance.action.action_name
	
	pressed.connect(action_instance.start_targeting)
	
	focus_entered.connect(show_potential_targets)
	focus_exited.connect(hide_potential_targets)


func show_potential_targets() -> void:
	if is_instance_valid(action_instance.user.active_action):
		action_instance.user.active_action.stop_targeting()
	
	action_instance.show_potential_targets()


func hide_potential_targets() -> void:
	action_instance.hide_potential_targets()
	
	if is_instance_valid(action_instance.user.active_action):
		action_instance.user.active_action.start_targeting()

class_name ActionButton
extends Button

var action_instance: ActionInstance

func _init(new_action_instance: ActionInstance) -> void:
	action_instance = new_action_instance
	
	text = action_instance.action.action_name
	name = action_instance.action.action_name
	
	pressed.connect(action_instance.start_targeting)

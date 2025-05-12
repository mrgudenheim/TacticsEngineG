class_name Action

@export var action_name: String = "Action Name"
@export var description: String = "Action description"

@export var useable_strategy: UseableStrategy
@export var targeting_strategy: TargetingStrategy
@export var use_strategy: UseStrategy

func _to_string() -> String:
	return action_name

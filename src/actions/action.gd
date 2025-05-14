class_name Action
extends Resource

@export var action_name: String = "Action Name"
@export var description: String = "Action description"

@export var useable_strategy: UseableStrategy
@export var targeting_strategy: TargetingStrategy
@export var use_strategy: UseStrategy

func _to_string() -> String:
	return action_name


func is_usable(action_instance: ActionInstance) -> bool:
	return useable_strategy.is_usable(action_instance)


func start_targeting(action_instance: ActionInstance) -> void:
	targeting_strategy._start_targeting(action_instance)


func use(action_instance: ActionInstance) -> void:
	use_strategy.use(action_instance)

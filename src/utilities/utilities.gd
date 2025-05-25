extends Node

var targeting_strategies: Dictionary[TargetingTypes, TargetingStrategy] = {}


enum TargetingTypes {
	MOVE,
	RANGE,
	}


func _ready() -> void:
	targeting_strategies[TargetingTypes.MOVE] = MoveTargeting.new()
	targeting_strategies[TargetingTypes.RANGE] = RangeTargeting.new()

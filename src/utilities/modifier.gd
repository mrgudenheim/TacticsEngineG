class_name Modifier
extends RefCounted

enum ModifierType {
	ADD,
	MULT,
	SET,
}

var type: ModifierType = ModifierType.ADD
var value: float = 1.0
var priority: int = 1 # order to be applied
# TODO track modifier source?

func _init(new_value: float = 1.0, new_type: ModifierType = ModifierType.ADD, new_priority: int = 1) -> void:
	value = new_value
	type = new_type
	priority = new_priority


func apply(to_value: int) -> int:
	match type:
		ModifierType.ADD:
			return roundi(to_value + value)
		ModifierType.MULT:
			return roundi(to_value * value)
		ModifierType.SET:
			return roundi(value)
		_:
			push_warning("Modifier type unknown: " + str(type))
			return -1

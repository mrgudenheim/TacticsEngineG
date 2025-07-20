class_name Modifier
extends Resource

enum ModifierType {
	ADD,
	MULT,
	SET,
}

@export var type: ModifierType = ModifierType.ADD
@export var value: float = 1.0
@export var order: int = 1 # order to be appliede
# TODO track modifier source?

func _init(new_value: float = 1.0, new_type: ModifierType = ModifierType.ADD, new_order: int = 1) -> void:
	value = new_value
	type = new_type
	order = new_order


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

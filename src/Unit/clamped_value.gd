class_name ClampedValue
extends RefCounted

signal changed(clamped_value: ClampedValue)

var min_value: int = 0 # should not change
var max_value: int = 100 # should not change (except when linked to another stat, ex hp_max)
var base_value: int = 50 # should not change
var current_value: int = 50 # typically used for stats that get changed until end of battle: hp, mp, ct, faith, brave, exp, lvl
var modified_value: int: # typically used for stats that are modified from other things (equipment, etc): move, jump, speed, hp_max, mp_max
	get:
		return get_modified_value()

var modifiers: Array[Modifier] = []

enum ModifierType {
	ADD,
	MULT,
	SET,
}


class Modifier:
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


func _init(new_min_value: int = 0, new_max_value: int = 100, new_current_value: int = 50) -> void:
	min_value = new_min_value
	max_value = new_max_value
	current_value = new_current_value


func get_unclampped_modified_value(preview_value: int = current_value) -> int:
	var temp_modified_value: int = preview_value
	for modifier: Modifier in modifiers:
		modifier.apply(temp_modified_value) # TODO sort by add, mult, set
	
	return temp_modified_value


func get_modified_value(preview_value: int = current_value) -> int:
	var temp_modified_value = get_unclampped_modified_value(preview_value)
	temp_modified_value = clampi(temp_modified_value, min_value, max_value)
	
	return temp_modified_value


func set_value(new_value: int) -> int:
	new_value = clampi(new_value, min_value, max_value)
	var delta_value: int = new_value - current_value
	current_value = new_value
	
	changed.emit(self)
	return delta_value


func get_set_delta(new_value: int) -> int:
	new_value = clampi(new_value, min_value, max_value)
	var delta_value: int = new_value - current_value
	
	return delta_value


func add_value(add_value: int) -> int:
	add_value = get_add_delta(add_value)
	current_value += add_value
	
	changed.emit(self)
	return add_value


func get_add_delta(add_value: int) -> int:
	# clamp delta
	if add_value + current_value > max_value:
		add_value = max_value - current_value
	elif add_value + current_value < min_value:
		add_value = min_value - current_value
	
	return add_value


func set_max_value(new_max_value: int) -> int:
	if new_max_value < min_value:
		push_warning("New max value (" + str(new_max_value) + ") < min value (" + str(min_value)+ ")")
	
	max_value = new_max_value
	var delta_current: int = set_value(current_value)
	
	changed.emit(self)
	return delta_current


func set_min_value(new_min_value: int) -> int:
	if new_min_value > max_value:
		push_warning("New min value (" + str(new_min_value) + ") > max value (" + str(max_value)+ ")")
	
	min_value = new_min_value
	var delta_current: int = set_value(current_value)
	
	changed.emit(self)
	return delta_current


func update_max_from_clamped_value(max_value: ClampedValue):
	set_max_value(max_value.get_modified_value())

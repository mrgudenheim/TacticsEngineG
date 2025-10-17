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


func to_dictionary() -> Dictionary:
	var properties_to_exclude: PackedStringArray = [
		"RefCounted",
		"Resource",
		"resource_local_to_scene",
		"resource_path",
		"resource_name",
		"resource_scene_unique_id",
		"script",
	]
	return Utilities.object_properties_to_dictionary(self, properties_to_exclude)


static func create_from_json(json_string: String) -> Modifier:
	var property_dict: Dictionary = JSON.parse_string(json_string)
	var new_modifier: Modifier = create_from_dictionary(property_dict)
	
	return new_modifier


static func create_from_dictionary(property_dict: Dictionary) -> Modifier:
	var new_modifier: Modifier = Modifier.new()
	for property_name in property_dict.keys():
		new_modifier.set(property_name, property_dict[property_name])

	new_modifier.emit_changed()
	return new_modifier
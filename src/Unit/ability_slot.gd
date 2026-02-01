class_name AbilitySlot
extends Resource

@export var ability_slot_name: String = "[Ability Slot]"
@export var slot_types: Array[Ability.SlotType] = []
@export var ability_unique_name: String
var ability: Ability:
	get: return RomReader.abilities[ability_unique_name]


static func create_from_dictionary(property_dict: Dictionary) -> UnitData:
	var new_unit_data: UnitData = UnitData.new()
	for property_name in property_dict.keys():
		# if property_name == "corner_position":
		# 	var vector_as_array = property_dict[property_name]
		# 	var new_corner_position: Vector3i = Vector3i(roundi(vector_as_array[0]), roundi(vector_as_array[1]), roundi(vector_as_array[2]))
		# 	new_unit_data.set(property_name, new_corner_position)
		# elif property_name == "mirror_xyz":
		# 	var array = property_dict[property_name]
		# 	var new_mirror_xyz: Array[bool] = []
		# 	new_mirror_xyz.assign(array)
		# 	new_unit_data.set(property_name, new_mirror_xyz)
		# else:
			new_unit_data.set(property_name, property_dict[property_name])

	new_unit_data.emit_changed()
	return new_unit_data


func _init(new_name: String = "", new_slot_types: Array[Ability.SlotType] = [], new_ability_unique_name: String = "") -> void:
	ability_slot_name = new_name
	slot_types = new_slot_types
	ability_unique_name = new_ability_unique_name


func _to_string() -> String:
	return ability_slot_name + ": " + ability.display_name


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
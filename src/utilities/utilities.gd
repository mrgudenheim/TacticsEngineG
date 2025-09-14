extends Node

var targeting_strategies: Dictionary[Action.TargetingTypes, TargetingStrategy] = {}
var use_strategies: Dictionary[Action.UseTypes, UseStrategy] = {}

func _ready() -> void:
	targeting_strategies = {
		Action.TargetingTypes.MOVE : MoveTargeting.new(),
		Action.TargetingTypes.RANGE : RangeTargeting.new(),
	}

	use_strategies = {
		Action.UseTypes.NORMAL : null,
		Action.UseTypes.MOVE : MoveUse.new(),
	}


func object_properties_to_dictionary(object: Object, exclude_property_names: PackedStringArray = []) -> Dictionary:
	var property_list = object.get_property_list()
	var property_dict: Dictionary = {}
	for property_idx in property_list.size():
		var property = property_list[property_idx]
		if not property["usage"] & PROPERTY_USAGE_STORAGE:
			continue
		if exclude_property_names.has(property["name"]) or property["name"].ends_with(".gd"):
			continue
		if property["class_name"] == '' or object.get(property["name"]) == null or not (object.get(property["name"]) is Object):
			if property["type"] == 28: # TYPE_ARRAY
				var new_array: Array = []
				for element in object.get(property["name"]):
					if not element is Object:
						new_array.append(element)
					elif not element.has_method("to_dictionary"):
						new_array.append(element)
					else:
						new_array.append(element.to_dictionary())
				property_dict[property["name"]] = new_array
			else:
				property_dict[property["name"]] = object.get(property["name"])
		elif object.get(property["name"]).has_method("to_dictionary"):
			property_dict[property["name"]] = object.get(property["name"]).to_dictionary()
		else:
			property_dict[property["name"]] = object.get(property["name"])
	
	return property_dict


func object_properties_to_json(object, exclude_property_names: PackedStringArray = []) -> String:
	var property_dict: Dictionary = object_properties_to_dictionary(object, exclude_property_names)
	return JSON.stringify(property_dict, "\t")


## returns true if array1 has any element in array2 or if arry2 is empty
func has_any_elements(array1: Array, array2: Array) -> bool:
	if array2.is_empty():
		return true
	
	# alternate of below?
	# if array2.any(func(element): return array1.has(element)):
	# 	return true

	for element in array2:
		if array1.has(element):
			return true
	
	return false

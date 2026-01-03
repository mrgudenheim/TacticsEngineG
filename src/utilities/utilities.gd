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
			if property["type"] == TYPE_ARRAY:
				var new_array: Array = []
				for element in object.get(property["name"]):
					if not element is Object:
						new_array.append(element)
					elif not element.has_method("to_dictionary"):
						new_array.append(element)
					else:
						new_array.append(element.to_dictionary()) # handle array elements that are resources
				property_dict[property["name"]] = new_array
			elif property["type"] == TYPE_DICTIONARY: 
				var new_dict: Dictionary = {}
				for key in object.get(property["name"]).keys():
					var value = object.get(property["name"])[key]
					if not value is Object:
						new_dict[key] = value
					elif not value.has_method("to_dictionary"):
						new_dict[key] = value
					else:
						new_dict[key] = value.to_dictionary() # handle dictionary values that are resources
				property_dict[property["name"]] = new_dict
			elif property["type"] == TYPE_COLOR:
				var color: Color = object.get(property["name"])
				var new_array: Array = [color.r, color.g, color.b, color.a]
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


func save_json(object) -> void:
	var json_file = FileAccess.open(object.SAVE_DIRECTORY_PATH + object.unique_name + "." + object.FILE_SUFFIX + ".json", FileAccess.WRITE)
	json_file.store_line(object.to_json())
	json_file.close()


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


func get_array_unique(array: Array) -> Array:
	var unique_array: Array = []
	for item in array:
		if not unique_array.has(item):
			unique_array.append(item)
	return unique_array
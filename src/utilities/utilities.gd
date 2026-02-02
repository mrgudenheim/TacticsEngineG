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


# TODO store Strings of enums - if property["hint"] == PROPERTY_HINT_ENUM
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

				# check if element is enum to convert to String
				var hint_string: String = property["hint_string"]
				var element_is_enum: bool = hint_string.begins_with("2/2:")
				var element_enum_dict: Dictionary[int, String] = {}
				if element_is_enum:
					var element_hint_string: String = hint_string.trim_prefix("2/2:").to_upper().replace(" ", "_")
					element_enum_dict = get_enum_string_dict(element_hint_string)

				for element in object.get(property["name"]):
					if element is PackedVector2Array:
						var new_vector_array: Array = []
						for vector: Vector2 in element:
							new_vector_array.append([vector.x, vector.y])
						new_array.append(new_vector_array)
					elif not element is Object:
						if element_is_enum:
							new_array.append(element_enum_dict[element])
						else:
							new_array.append(element)
					elif not element.has_method("to_dictionary"):
						new_array.append(element)
					else:
						new_array.append(element.to_dictionary()) # handle array elements that are resources
				property_dict[property["name"]] = new_array
			elif property["type"] == TYPE_DICTIONARY: 
				var new_dict: Dictionary = {}

				# check if key is enum to convert to String
				var hint_string: String = property["hint_string"]
				var key_is_enum: bool = hint_string.begins_with("2/2:")
				var key_enum_dict: Dictionary[int, String] = {}
				if key_is_enum:
					var key_hint_string: String = hint_string.get_slice(";", 0) # get key hint_string
					key_hint_string = key_hint_string.trim_prefix("2/2:").to_upper().replace(" ", "_")
					key_enum_dict = get_enum_string_dict(key_hint_string)
				
				for key in object.get(property["name"]).keys():
					var new_key = key
					if key_is_enum:
						new_key = key_enum_dict[key]

					var value = object.get(property["name"])[key]
					if not value is Object:
						new_dict[new_key] = value
					elif not value.has_method("to_dictionary"):
						new_dict[new_key] = value
					else:
						new_dict[new_key] = value.to_dictionary() # handle dictionary values that are resources
				property_dict[property["name"]] = new_dict
			elif property["type"] == TYPE_COLOR:
				var color: Color = object.get(property["name"])
				var new_array: Array = [color.r, color.g, color.b, color.a]
				property_dict[property["name"]] = new_array
			elif property["type"] == TYPE_VECTOR3 or property["type"] == TYPE_VECTOR3I:
				var vector = object.get(property["name"])
				var new_array: Array = [vector.x, vector.y, vector.z]
				property_dict[property["name"]] = new_array
			elif property["type"] == TYPE_VECTOR2 or property["type"] == TYPE_VECTOR2I:
				var vector = object.get(property["name"])
				var new_array: Array = [vector.x, vector.y]
				property_dict[property["name"]] = new_array
			elif property["type"] == TYPE_PACKED_VECTOR2_ARRAY:
				var vector_array = object.get(property["name"])
				var new_array: Array = []
				for vector: Vector2 in vector_array:
					new_array.append([vector.x, vector.y])
				property_dict[property["name"]] = new_array
			elif property["hint"] == PROPERTY_HINT_ENUM:
				var enum_dict: Dictionary[int, String] = get_enum_string_dict(property["hint_string"])
				property_dict[property["name"]] = enum_dict[object.get(property["name"])]
			else:
				property_dict[property["name"]] = object.get(property["name"])
		elif object.get(property["name"]).has_method("to_dictionary"):
			property_dict[property["name"]] = object.get(property["name"]).to_dictionary()
		else:
			property_dict[property["name"]] = object.get(property["name"])
	
	return property_dict


func get_enum_string_dict(hint_string: String) -> Dictionary[int, String]:
	var new_enum_dict: Dictionary[int, String] = {}
	var regex = RegEx.new()
	regex.compile("_(?=\\d+)") # Pattern: _ (underscore) followed by a positive lookahead for digits (\d+)

	hint_string = hint_string.trim_prefix("2/2:").to_upper().replace(" ", "_")
	for string in hint_string.split(","):
		var enum_name: String = string.get_slice(":", 0)
		enum_name = regex.sub(enum_name, "", true) # remove underscores followed by a number, ex. "V_1" should be "V1"
		var enum_value: int = int(string.get_slice(":", 1))
		new_enum_dict[enum_value] = enum_name
		
	return new_enum_dict


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


func disconnect_all_connections(signal_to_disconnect: Signal) -> void:
	for connection_dictionary in signal_to_disconnect.get_connections():
		signal_to_disconnect.disconnect(connection_dictionary.callable)

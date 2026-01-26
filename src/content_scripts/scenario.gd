class_name Scenario
extends Resource

const SAVE_DIRECTORY_PATH: String = "user://overrides/scenario/"
const FILE_SUFFIX: String = "scenario"
@export var unique_name: String = "unique_name"
@export var display_name: String = "display_name"
@export var description: String = "description"




func add_to_global_list(will_overwrite: bool = false) -> void:
	if ["", "unique_name"].has(unique_name):
		unique_name = display_name.to_snake_case()
	
	if RomReader.scenarios.keys().has(unique_name) and will_overwrite:
		push_warning("Overwriting existing scenario: " + unique_name)
	elif RomReader.scenarios.keys().has(unique_name) and not will_overwrite:
		var num: int = 2
		var formatted_num: String = "%02d" % num
		var new_unique_name: String = unique_name + "_" + formatted_num
		while RomReader.scenarios.keys().has(new_unique_name):
			num += 1
			formatted_num = "%02d" % num
			new_unique_name = unique_name + "_" + formatted_num
		
		push_warning("Scenario list already contains: " + unique_name + ". Incrementing unique_name to: " + new_unique_name)
		unique_name = new_unique_name
	
	RomReader.scenarios[unique_name] = self


func to_json() -> String:
	var properties_to_exclude: PackedStringArray = [
		"RefCounted",
		"Resource",
		"resource_local_to_scene",
		"resource_path",
		"resource_name",
		"resource_scene_unique_id",
		"script",
	]
	return Utilities.object_properties_to_json(self, properties_to_exclude)


static func create_from_json(json_string: String) -> Scenario:
	var property_dict: Dictionary = JSON.parse_string(json_string)
	var new_scenario: Scenario = create_from_dictionary(property_dict)
	
	return new_scenario


static func create_from_dictionary(property_dict: Dictionary) -> Scenario:
	var new_scenario: Scenario = Scenario.new()
	for property_name in property_dict.keys():
		new_scenario.set(property_name, property_dict[property_name])

	new_scenario.emit_changed()
	return new_scenario

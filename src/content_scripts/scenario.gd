class_name Scenario
extends Resource

const SAVE_DIRECTORY_PATH: String = "user://overrides/scenarios/"
const FILE_SUFFIX: String = "scenario"
@export var unique_name: String = "unique_name"
@export var display_name: String = "display_name"
@export var description: String = "description"

@export var background_gradient_top: Color = Color.LIGHT_GRAY
@export var background_gradient_bottom: Color = Color.DARK_BLUE
@export var map_chunks: Array[MapChunk] = []
@export var deployment_zones: Array[PackedVector2Array] = [] # TODO what about locations with tiles at different hights?

# @export var units_data: Array[Unit] = [] # TODO separate unit data from node into Resource
# TODO scenario victory conditions

class MapChunk extends Resource:
	@export var unique_name: String = "unique_name"
	@export var mirror_xyz: Array[bool] = [false, false, false] # mirror y of fft maps to have postive y be up, invert x or z to mirror the map
	@export var corner_position: Vector3i = Vector3i.ZERO
	@export var rotation: int = 0 # values 0, 1, 2, 3 for 90 degree rotation increments
	var mirror_scale: Vector3i = Vector3i.ONE
	
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


	func set_mirror_xyz(new_mirror_xyz: Array[bool]) -> void:
		mirror_xyz = new_mirror_xyz

		mirror_scale.x = -1 if mirror_xyz[0] else 1
		mirror_scale.y = -1 if mirror_xyz[1] else 1
		mirror_scale.z = -1 if mirror_xyz[2] else 1


	static func create_from_dictionary(property_dict: Dictionary) -> MapChunk:
		var new_map_chunk: MapChunk = MapChunk.new()
		for property_name in property_dict.keys():
			if property_name == "corner_position":
				var vector_as_array = property_dict[property_name]
				var new_corner_position: Vector3i = Vector3i(roundi(vector_as_array[0]), roundi(vector_as_array[1]), roundi(vector_as_array[2]))
				new_map_chunk.set(property_name, new_corner_position)
			elif property_name == "mirror_xyz":
				var array = property_dict[property_name]
				var new_mirror_xyz: Array[bool] = []
				new_mirror_xyz.assign(array)
				new_map_chunk.set(property_name, new_mirror_xyz)
			else:
				new_map_chunk.set(property_name, property_dict[property_name])

		new_map_chunk.emit_changed()
		return new_map_chunk


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
		if property_name == "map_chunks":
			var new_map_chunks: Array[MapChunk] = []
			var map_chunks_array = property_dict[property_name]
			for map_chunk_dict: Dictionary in map_chunks_array:
				var new_map_chunk: MapChunk = MapChunk.create_from_dictionary(map_chunk_dict)
				new_map_chunks.append(new_map_chunk)

			new_scenario.set(property_name, new_map_chunks)
		elif property_name == "deployment_zones":
			var new_deployment_zones: Array[PackedVector2Array] = []
			var array_of_arrays = property_dict[property_name]
			for zone in array_of_arrays:
				var new_zone: PackedVector2Array = []
				for location in zone:
					new_zone.append(Vector2(location[0], location[1]))
				new_deployment_zones.append(new_zone)
			new_scenario.set(property_name, new_deployment_zones)
		else:
			new_scenario.set(property_name, property_dict[property_name])

	new_scenario.emit_changed()
	return new_scenario

class_name UnitData
extends Resource

@export var display_name: String = "display name"
@export var level: int = 0
@export var gender: String = "gender" # male, female, other, monster
@export var zodiac: String = "zodiac" # TODO should zodiac be derived from birthday?
@export var job_unique_name: String = "job_unique_name"
@export var team: int = 0
@export var controller: int = 0 # 0 = AI, 1 = Player 1, etc.
@export var sprite_unique_name: String = "sprite_unique_name"
@export var palette_id: int = 0
@export var facing_direction: String = "direction" # north, south, east, west

# job levels
# jp per job
# abilities learned

# Stats
@export var stats: Dictionary[Unit.StatType, ClampedValue]
@export var stats_raw: Dictionary[Unit.StatType, float]

# equipment
@export var primary_weapon_unique_name: String
@export var equip_slots: Array[EquipmentSlot]

# abilities
@export var ability_slots: Array[AbilitySlot]

# position
@export var tile_position: Vector3 # tile_position.get_world_position

# current statuses - to be used for saving/loading mid battle


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


func init_from_unit(unit: Unit) -> void:
	display_name = unit.unit_nickname
	level = unit.level
	gender = Unit.Gender.keys()[unit.gender] # male, female, other, monster
	zodiac = "zodiac" # TODO should zodiac be derived from birthday?
	job_unique_name = unit.job_data.unique_name
	team = unit.team_id
	controller = 0 if unit.is_ai_controlled else 1 # 0 = AI, 1 = Player 1, etc.
	sprite_unique_name = "sprite_unique_name"
	palette_id = unit.sprite_palette_id
	facing_direction = Unit.Facings.keys()[unit.facing] # NORTH, SOUTH, EAST, WEST

	# job levels
	# jp per job
	# abilities learned

	stats = unit.stats
	stats_raw = unit.stats_raw
	primary_weapon_unique_name = unit.primary_weapon.unique_name
	equip_slots = unit.equip_slots
	ability_slots = unit.ability_slots
	tile_position = unit.tile_position.get_world_position()

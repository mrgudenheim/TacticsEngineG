class_name Action
extends Resource

@export var action_name: String = "Action Name"
@export var description: String = "Action description"
@export var quote: String = "Action quote"
@export var display_action_name: bool = true

@export var useable_strategy: UseableStrategy
@export var targeting_strategy: TargetingStrategy
@export var use_strategy: UseStrategy

@export var move_points_cost: int = 0
@export var action_points_cost: int = 1

@export var mp_cost: int = 0

var formula_id: int = 0
@export var formula_x: int = 0
@export var formula_y: int = 0
@export var min_targeting_range: int = 0
@export var max_targeting_range: int = 4
@export var area_of_effect_radius: int = 0
@export var vertical_tolerance: int = 2
var inflict_status_id: int = 0
@export var ticks_charge_time: int = 0

@export var has_vertical_tolerance_from_user: bool = false # vertical fixed / linear range
@export var has_vertical_tolerance_from_target: bool = false # vertical tolerance
@export var use_weapon_range: bool = false
@export var use_weapon_potential_targets: bool = false
@export var auto_target: bool = false
@export var cant_target_self: bool = false
@export var cant_hit_enimies: bool = false
@export var cant_hit_allies: bool = false
@export var cant_hit_user: bool = false
@export var top_down_targeting: bool = false
@export var cant_follow_target: bool = true
@export var random_fire: bool = false
@export var targeting_linear: bool = false
@export var targeting_three_directions: bool = false
@export var targeting_direct: bool = false # stop at obstacle

#@export var is_evadable: bool = false
@export var applicable_evasion: EvadeType = EvadeType.PHYSICAL
@export var is_reflectable: bool = false
@export var is_math_usable: bool = false
@export var is_mimicable: bool = false
@export var blocked_by_golem: bool = false
@export var repeat_use: bool = false # performing
@export var vfx_on_empty: bool = false

@export var trigger_counter_flood: bool = false
@export var trigger_counter_magic: bool = false
@export var trigger_counter_grasp: bool = false

@export var can_select_unit: bool = true

@export var element: ElementalTypes = ElementalTypes.NONE

@export var base_hit_chance: int = 100
@export var action_power: int = 5
@export var base_damage_formula: Formulas = Formulas.PAxWP

# inflict status data
@export var status_list: Array[StatusEffect] = []
@export var status_chance: int = 100
@export var will_remove_status: bool = false
@export var status_list_type: StatusListType = StatusListType.EACH
var all_status: bool = false
var random_status: bool = false
var separate_status: bool = false

@export var status_prevents_use_any: Array[StatusEffect] = [] # silence, dont move, dont act, etc.
@export var required_equipment_type: Array[ItemData.ItemType] = [] # sword, gun, etc.
@export var required_equipment: Array[ItemData] = [] # materia_blade, etc.

enum EvadeType {
	NONE,
	PHYSICAL,
	MAGICAL,
	}

enum ElementalTypes {
	NONE = 0x00,
	DARK = 0x01,
	HOLY = 0x02,
	WATER = 0x04,
	EARTH = 0x08,
	WIND = 0x10,
	ICE = 0x20,
	LIGHTNING = 0x40,
	FIRE = 0x80,
	}

enum StatusListType {
	ALL,
	EACH,
	RANDOM,
	}

static var formula_descriptions: Dictionary[Formulas, String] = {
	Formulas.ZERO: "0",
	Formulas.PAxWP: "PAxWP",
	Formulas.MAxWP: "MAxWP",
	Formulas.AVG_PA_MAxWP: "AVG_PA_MAxWP",
	Formulas.AVG_PA_SPxWP: "AVG_PA_SPxWP",
	Formulas.PA_BRAVExWP: "PA_BRAVExWP",
	Formulas.RANDOM_PAxWP: "RANDOM_PAxWP",
	Formulas.WPxWP: "WPxWP",
	Formulas.PA_BRAVExPA: "PA_BRAVExPA",
	}

enum Formulas {
	ZERO,
	PAxWP,
	MAxWP,
	AVG_PA_MAxWP,
	AVG_PA_SPxWP,
	PA_BRAVExWP,
	RANDOM_PAxWP,
	WPxWP,
	PA_BRAVExPA,
	}


func _to_string() -> String:
	return action_name


func is_usable(action_instance: ActionInstance) -> bool:
	var is_usable: bool = false
	if useable_strategy == null: # default usable check
		var user_has_enough_move_points: bool = action_instance.user.move_points_remaining - action_instance.action.move_points_cost >= 0
		var user_has_enough_action_points: bool = action_instance.user.action_points_remaining - action_instance.action.action_points_cost >= 0
		
		is_usable= user_has_enough_move_points and user_has_enough_action_points
	else: # custom usable check
		is_usable = useable_strategy.is_usable(action_instance)
		
	return is_usable

func start_targeting(action_instance: ActionInstance) -> void:
	targeting_strategy.start_targeting(action_instance)


func stop_targeting(action_instance: ActionInstance) -> void:
	targeting_strategy.stop_targeting(action_instance)


func use(action_instance: ActionInstance) -> void:
	use_strategy.use(action_instance)




func get_base_damage(user: UnitData) -> int:
	var base_damage: int = 0
	
	match base_damage_formula:
		Formulas.ZERO:
			base_damage = 0
		Formulas.PAxWP:
			base_damage = user.physical_attack_current * action_power
		Formulas.MAxWP:
			base_damage = user.magical_attack_current * action_power
		Formulas.AVG_PA_MAxWP:
			base_damage = round(((user.physical_attack_current + user.magical_attack_current) / 2.0) * action_power)
		Formulas.AVG_PA_SPxWP:
			base_damage = round(((user.physical_attack_current + user.speed_current) / 2.0) * action_power)
		Formulas.PA_BRAVExWP:
			base_damage = round(user.physical_attack_current * user.brave_current * action_power / 100.0)
		Formulas.RANDOM_PAxWP:
			base_damage = randi_range(1, user.physical_attack_current) * action_power
		Formulas.WPxWP:
			base_damage = action_power * action_power
		Formulas.PA_BRAVExPA:
			base_damage = round(user.physical_attack_current * user.brave_current / 100.0) * user.physical_attack_current
	
	return base_damage



static func get_elemental_types_array(element_bitflags: PackedByteArray) -> Array[ElementalTypes]:
	var elemental_types: Array[ElementalTypes] = []
	
	for byte_idx: int in element_bitflags.size():
		for bit_idx: int in range(7, -1, -1):
			var byte: int = element_bitflags.decode_u8(byte_idx)
			if byte & (2 ** bit_idx) != 0:
				var element_index: int = (7 - bit_idx) + (byte_idx * 8)
				elemental_types.append(element_index)
	
	return elemental_types

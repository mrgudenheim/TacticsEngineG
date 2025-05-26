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
@export var area_of_effect_range: int = 0
@export var vertical_tolerance: float = 2
var inflict_status_id: int = 0
@export var ticks_charge_time: int = 0

@export var has_vertical_tolerance_from_user: bool = false # vertical fixed / linear range
@export var use_weapon_range: bool = false
@export var use_weapon_potential_targets: bool = false
@export var auto_target: bool = false
@export var cant_target_self: bool = false
@export var cant_hit_enimies: bool = false
@export var cant_hit_allies: bool = false
@export var cant_hit_user: bool = false
@export var targeting_top_down: bool = false
@export var cant_follow_target: bool = true
@export var random_fire: bool = false
@export var targeting_linear: bool = false
@export var targeting_direct: bool = false # stop at obstacle
@export var aoe_has_vertical_tolerance: bool = false # vertical tolerance
@export var aoe_vertical_tolerance: float = 2
@export var aoe_targeting_three_directions: bool = false
@export var aoe_targeting_direct: bool = false # stop at obstacle

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

# animation data
@export var animation_start_id: int = 0
@export var animation_charging_id: int = 0
@export var animation_executing_id: int = 0

var vfx_data: VisualEffectData

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
		var user_has_enough_move_points: bool = action_instance.user.move_points_remaining >= action_instance.action.move_points_cost
		var user_has_enough_action_points: bool = action_instance.user.action_points_remaining >= action_instance.action.action_points_cost
		var user_has_enough_mp: bool = action_instance.user.mp_current >= action_instance.action.mp_cost
		
		var action_not_prevented_by_status: bool = not action_instance.action.status_prevents_use_any.any(func(status: StatusEffect): return action_instance.user.current_statuses.has(status))
		
		is_usable = (user_has_enough_move_points 
				and user_has_enough_action_points 
				and user_has_enough_mp
				and action_not_prevented_by_status)
	else: # custom usable check
		is_usable = useable_strategy.is_usable(action_instance)
		
	return is_usable

func start_targeting(action_instance: ActionInstance) -> void:
	targeting_strategy.start_targeting(action_instance)


func stop_targeting(action_instance: ActionInstance) -> void:
	targeting_strategy.stop_targeting(action_instance)


func use(action_instance: ActionInstance) -> void:
	if use_strategy == null: # default usable check
		# face target
		var direction_to_target: Vector2i = action_instance.submitted_targets[0].location - action_instance.user.tile_position.location
		action_instance.user.update_unit_facing(Vector3(direction_to_target.x, 0, direction_to_target.y))
		
		var target_units: Array[UnitData] = []
		for target_tile: TerrainTile in action_instance.submitted_targets:
			var unit_index: int = action_instance.battle_manager.units.find_custom(func(unit: UnitData): return unit.tile_position == target_tile)
			if unit_index == -1:
				continue
			var target_unit: UnitData = action_instance.battle_manager.units[unit_index]
			target_units.append(target_unit)
		
		# look up animation based on weapon type and vertical angle to target
		var mod_animation_executing_id: int = animation_executing_id
		if animation_executing_id == 0:
			mod_animation_executing_id = RomReader.battle_bin_data.weapon_animation_ids[action_instance.user.primary_weapon.item_type].y * 2
			var angle_to_target: float = ((action_instance.submitted_targets[0].height_mid - action_instance.user.tile_position.height_mid) 
					/ (action_instance.submitted_targets[0].location - action_instance.user.tile_position.location).length())
			if angle_to_target > 1:
				mod_animation_executing_id += -2
			elif angle_to_target < 1:
				mod_animation_executing_id += 2
		
		#action_instance.user.current_animation_id_fwd = (RomReader.battle_bin_data.weapon_animation_ids[action_instance.user.primary_weapon.item_type].y * 2) # TODO lookup based on target relative height
		#action_instance.user.set_base_animation_ptr_id(action_instance.user.current_animation_id_fwd)
		
		await action_instance.user.animate_start_action(animation_start_id, animation_charging_id)
		
		action_instance.user.animate_execute_action(mod_animation_executing_id)
		
		await action_instance.user.get_tree().create_timer(0.2).timeout
		
		for target_unit: UnitData in target_units:
			target_unit.animate_take_hit()
		
		await action_instance.user.animation_manager.animation_completed

		action_instance.user.animate_return_to_idle()
		
		for target_unit: UnitData in target_units:
			target_unit.animate_return_to_idle()
		
		action_instance.clear() # clear all highlighting and target data
		
		# pay costs
		action_instance.user.move_points_remaining -= action_instance.action.move_points_cost
		action_instance.user.action_points_remaining -= action_instance.action.action_points_cost
		action_instance.user.mp_current -= action_instance.action.mp_cost
		
		action_instance.action_completed.emit(action_instance.battle_manager)
	else:
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

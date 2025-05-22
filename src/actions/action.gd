class_name Action
extends Resource

@export var action_name: String = "Action Name"
@export var description: String = "Action description"
@export var spell_quote: String = "spell quote"
@export var display_action_name: bool = true

@export var useable_strategy: UseableStrategy
@export var targeting_strategy: TargetingStrategy
@export var use_strategy: UseStrategy

@export var move_points_cost: int = 0
@export var action_points_cost: int = 1

@export var mp_cost: int = 0

@export var formula_id: int = 0
@export var formula_x: int = 0
@export var formula_y: int = 0
@export var targeting_range: int = 4
@export var effect_radius: int = 1
@export var vertical_tolerance: int = 2
@export var inflict_status_id: int = 0
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
@export var cant_follow_target: bool = false
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

@export var can_select_unit: bool = false

@export var element: Utilities.ElementalTypes = Utilities.ElementalTypes.NONE

# TODO create status type enum?
@export var status_prevents_any: Array[StatusEffect] = [] # silence, dont move, dont act, etc.
@export var required_equipment_type: Array[ItemData.ItemType] = [] # sword, materia_blade, etc.
@export var required_equipment: Array[ItemData] = [] # sword, materia_blade, etc.

enum EvadeType {
	NONE,
	PHYSICAL,
	MAGICAL,
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

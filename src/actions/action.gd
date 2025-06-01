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
var formula_x: int = 0
var formula_y: int = 0
@export var min_targeting_range: int = 0
@export var max_targeting_range: int = 4
@export var area_of_effect_range: int = 0
@export var vertical_tolerance: float = 2
var inflict_status_id: int = 0
@export var ticks_charge_time: int = 0

@export var has_vertical_tolerance_from_user: bool = false # vertical fixed / linear range
@export var use_weapon_range: bool = false
@export var use_weapon_targeting: bool = false
@export var use_weapon_damage: bool = false
@export var auto_target: bool = false
@export var cant_target_self: bool = false
@export var cant_hit_enimies: bool = false
@export var cant_hit_allies: bool = false
@export var cant_hit_user: bool = false
@export var targeting_top_down: bool = false
@export var cant_follow_target: bool = true
@export var random_fire: bool = false
@export var targeting_linear: bool = false
@export var targeting_los: bool = false # stop at obstacle
@export var aoe_has_vertical_tolerance: bool = false # vertical tolerance
@export var aoe_vertical_tolerance: float = 2
@export var aoe_targeting_three_directions: bool = false
@export var aoe_targeting_los: bool = false # stop at obstacle

@export var target_effects: Array[ActionEffect] = []
@export var user_effects: Array[ActionEffect] = []

#@export var is_evadable: bool = false
@export var applicable_evasion: EvadeData.EvadeType = EvadeData.EvadeType.PHYSICAL
@export var is_reflectable: bool = false
@export var is_math_usable: bool = false
@export var is_mimicable: bool = false
@export var blocked_by_golem: bool = false
@export var repeat_use: bool = false # performing
@export var vfx_on_empty: bool = false

@export var trigger_counter_flood: bool = false
@export var trigger_counter_magic: bool = false
@export var trigger_counter_grasp: bool = false

@export var can_target: bool = true

@export var element: ElementTypes = ElementTypes.NONE

@export var base_hit_formula: FormulaData = FormulaData.new(FormulaData.Formulas.UNMODIFIED, 100, 0, FormulaData.FaithModifier.NONE, FormulaData.FaithModifier.NONE, true, false)

@export var healing_damages_undead: bool = false

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

@export var secondary_actions: Array[Action] = [] # skip right to applying ActionEffects to targets, but can use new FormulaData
@export var secondary_actions_chances: PackedInt32Array = [100]
@export var secondary_action_list_type: StatusListType = StatusListType.EACH

@export var set_target_animation_on_hit: bool = true
@export var ends_turn: bool = false

enum ElementTypes {
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

enum ActionRelativePosition {
	FRONT,
	SIDE,
	BACK,
	}


func _to_string() -> String:
	return action_name


func is_usable(action_instance: ActionInstance) -> bool:
	var is_usable: bool = false
	if useable_strategy == null: # default usable check
		var user_has_enough_move_points: bool = action_instance.user.move_points_remaining >= action_instance.action.move_points_cost
		var user_has_enough_action_points: bool = action_instance.user.action_points_remaining >= action_instance.action.action_points_cost
		var user_has_enough_mp: bool = action_instance.user.mp_current >= action_instance.action.mp_cost
		var user_has_equipment_type: bool = required_equipment_type.is_empty() or required_equipment_type.has(action_instance.user.primary_weapon.item_type) # TODO check all unit.equipped, not just primary_weapon
		var user_has_equipment: bool = required_equipment.is_empty() or required_equipment.has(action_instance.user.primary_weapon) # TODO check all unit.equipped, not just primary_weapon
		
		var action_not_prevented_by_status: bool = not action_instance.action.status_prevents_use_any.any(func(status: StatusEffect): return action_instance.user.current_statuses.has(status))
		
		is_usable = (user_has_enough_move_points 
				and user_has_enough_action_points 
				and user_has_enough_mp
				and action_not_prevented_by_status
				and user_has_equipment_type
				and user_has_equipment)
	else: # custom usable check
		is_usable = useable_strategy.is_usable(action_instance)
		
	return is_usable


func start_targeting(action_instance: ActionInstance) -> void:
	if targeting_strategy != null:
		targeting_strategy.start_targeting(action_instance)


func stop_targeting(action_instance: ActionInstance) -> void:
	if targeting_strategy != null:
		targeting_strategy.stop_targeting(action_instance)


func use(action_instance: ActionInstance) -> void:
	if use_strategy == null: # default usable check
		apply_standard(action_instance)
	else:
		use_strategy.use(action_instance)


func check_hit(user: UnitData, target: UnitData) -> bool:
	var hit: bool = false
	var hit_chance: float = base_hit_formula.get_result(user, target, element)
	
	var relative_position: Vector2i = user.tile_position.location - target.tile_position.location
	var relative_facing_position: Vector2i = relative_position
	if target.facing == UnitData.Facings.NORTH:
		pass # relative position is already correct for North facing
	elif target.facing == UnitData.Facings.EAST:
		relative_facing_position = Vector2i(-relative_position.y, relative_position.x)
	elif target.facing == UnitData.Facings.SOUTH:
		relative_facing_position = -relative_position
	elif target.facing == UnitData.Facings.WEST:
		relative_facing_position = Vector2i(relative_position.y, -relative_position.x)
	
	# check target facing, check x>y
	var evade_direction: EvadeData.Directions = EvadeData.Directions.FRONT
	if relative_facing_position.y < 0:
		evade_direction = EvadeData.Directions.BACK
		if abs(relative_facing_position.x) >= abs(relative_facing_position.y):
			evade_direction = EvadeData.Directions.SIDE
	elif abs(relative_facing_position.x) > abs(relative_facing_position.y):
		evade_direction = EvadeData.Directions.SIDE
	
	var target_total_evade_factor: float = 1.0
	if applicable_evasion != EvadeData.EvadeType.NONE:
		# TODO loop over all EvadeData.EvadeSource possibilites?
		var job_evade_factor: float = 1 - (target.get_evade(EvadeData.EvadeSource.JOB, applicable_evasion, evade_direction) / 100.0) # TODO job/class evade factor - only front facing?
		var shield_evade_factor: float = 1 - (target.get_evade(EvadeData.EvadeSource.SHIELD, applicable_evasion, evade_direction) / 100.0) # TODO shield evade factor - only front and side facing?
		var accessory_factor: float = 1 - (target.get_evade(EvadeData.EvadeSource.ACCESSORY, applicable_evasion, evade_direction) / 100.0) # TODO accessory evade factor
		var weapon_evade_factor: float = 1 - (target.get_evade(EvadeData.EvadeSource.WEAPON, applicable_evasion, evade_direction) / 100.0) # TODO weapon evade factor - only front and side facing? and only with "Weapon Guard" ability

		target_total_evade_factor = job_evade_factor * shield_evade_factor * accessory_factor * weapon_evade_factor
		target_total_evade_factor = max(0, target_total_evade_factor) # prevent negative evasion
	
	var total_hit_chance: int = roundi(hit_chance * target_total_evade_factor)
	
	hit = randi_range(0, 99) < total_hit_chance
	if not hit:
		# TODO animate_evade, shield block, or weapon block
		push_warning("miss")
		return hit
	
	
	
	
	return hit


func get_preview_total_hit_chance(user: UnitData, target: UnitData) -> int:
	var hit_chance: float = base_hit_formula.get_result(user, target, element)
	
	# TODO check evade
	
	return roundi(hit_chance)


func apply_standard(action_instance: ActionInstance) -> void:
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
		if angle_to_target > 0.51:
			mod_animation_executing_id += -2
		elif angle_to_target < -0.51:
			mod_animation_executing_id += 2
	
	await action_instance.user.animate_start_action(animation_start_id, animation_charging_id)
	
	action_instance.user.animate_execute_action(mod_animation_executing_id)
	
	await action_instance.user.get_tree().create_timer(0.2).timeout
	
	# TODO show vfx, including rock, arrow, bolt...
	
	# apply effects to targets
	for target_unit: UnitData in target_units:
		var hit_success: bool = check_hit(action_instance.user, target_unit)
		if hit_success:
			for effect: ActionEffect in target_effects:
				var effect_value: int = roundi(effect.base_power_formula.get_result(action_instance.user, target_unit, element))
				effect.apply(action_instance.user, target_unit, effect_value)
			
			if set_target_animation_on_hit:
				target_unit.animate_take_hit() # TODO or animate_receive_heal, status change
		else:
			# TODO face user
			target_unit.animate_evade() # TODO or shield block?
	
	# apply effects to user
	for effect: ActionEffect in user_effects:
		var effect_value: int = roundi(effect.base_power_formula.get_result(action_instance.user, action_instance.user, element))
		effect.apply(action_instance.user, action_instance.user, effect_value)
	
	if action_instance.user.current_animation_id_fwd != action_instance.user.current_idle_animation_id:
		await action_instance.user.animation_manager.animation_completed
	
	action_instance.user.animate_return_to_idle()
	
	for target_unit: UnitData in target_units:
		target_unit.animate_return_to_idle()
		# TODO return to original facing
	
	action_instance.clear() # clear all highlighting and target data
	
	# pay costs
	action_instance.user.move_points_remaining -= action_instance.action.move_points_cost
	action_instance.user.action_points_remaining -= action_instance.action.action_points_cost
	action_instance.user.mp_current -= action_instance.action.mp_cost
	
	action_instance.action_completed.emit(action_instance.battle_manager)
	
	if ends_turn:
		action_instance.user.end_turn()

func set_data_from_formula_id(new_formula_id: int, x: int = 0, y: int = 0) -> void:
	formula_id = new_formula_id
	
	match formula_id:
		0, 1, 5:
			# TODO get weapon damage?
			use_weapon_damage = true
		2:
			# TODO get weapon damage?
			use_weapon_damage = true
			secondary_actions.append(RomReader.abilities[inflict_status_id].ability_action)
			secondary_actions_chances = [19]
		3: # weapon_power * weapon_power
			applicable_evasion = EvadeData.EvadeType.NONE
			use_weapon_damage = true
			# TODO get weapon damage?
		4:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			var secondary_action_ids: PackedInt32Array = []
			match element: # TODO get user.primary_weapon element?
				Action.ElementTypes.FIRE:
					secondary_action_ids = [0x10, 0x11, 0x12]
				Action.ElementTypes.LIGHTNING:
					secondary_action_ids = [0x14, 0x15, 0x16]
				Action.ElementTypes.ICE:
					secondary_action_ids = [0x18, 0x19, 0x1a]
			for id: int in secondary_action_ids:
				var new_secondary_action: Action = RomReader.abilities[id].ability_action # abilities need to be initialized before items
				secondary_actions.append(new_secondary_action)
			
			secondary_actions_chances = [60, 30, 10]
			secondary_action_list_type = Action.StatusListType.RANDOM
		6:
			# TODO get weapon damage?
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].transfer_to_user = true # absorb hp
		7:
			applicable_evasion = EvadeData.EvadeType.NONE
			# TODO get weapon damage?
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.reverse_sign = false # heal
		8:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			target_effects[0].base_power_formula.value_01 = formula_y
			target_effects[0].base_power_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			target_effects[0].base_power_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
		9:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.value_01 = formula_y / 100.0
		0x0a:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MAxV1
			base_hit_formula.value_01 = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
		0x0b:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.MAxV1
			base_hit_formula.value_01 = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
		0x0c:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			target_effects[0].base_power_formula.value_01 = formula_y
			target_effects[0].base_power_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			target_effects[0].base_power_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			target_effects[0].base_power_formula.reverse_sign = false
		0x0d:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.value_01 = formula_y
			target_effects[0].base_power_formula.reverse_sign = false
		0x0e:
			applicable_evasion = EvadeData.EvadeType.MAGICAL # Does this use magic evade?
			
			# TODO apply status first? if target is immune to status, no damage
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			
			status_chance = 100
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.value_01 = formula_y
		0x0f:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.MP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.value_01 = formula_y
			target_effects[0].transfer_to_user = true
		0x10:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.value_01 = formula_y
			target_effects[0].transfer_to_user = true
		0x11:
			pass
		0x12:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.CT))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = 100
			target_effects[0].set_value = true
		0x13:
			pass
		0x14:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			# TODO set Golem
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
		0x15:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.CT))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = 00
			target_effects[0].set_value = true
		0x16:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.MP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_CURRENT_MP_minus_V1
			target_effects[0].base_power_formula.value_01 = 0
		0x17:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_CURRENT_HP_minus_V1
			target_effects[0].base_power_formula.value_01 = 1
		0x18, 0x19:
			pass
		0x1a:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_y
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.PHYSICAL_ATTACK)) # TODO MAGICAL_ATTACK or SPEED dependent on ability ID?
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = formula_x
		0x1b:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.MP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_MPxV1
			target_effects[0].base_power_formula.value_01 = formula_y
		0x1c:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.UNMODIFIED
			base_hit_formula.value_01 = formula_x
			
			# TODO song effects based on ability ID
		0x1d:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.UNMODIFIED
			base_hit_formula.value_01 = formula_x
			
			# TODO dance effects based on ability ID
		0x1e:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MA_plus_V1xMA_div_2
			target_effects[0].base_power_formula.value_01 = formula_y
			# TODO random number of hits within AoE
		0x1f:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MA_plus_V1xMA_div_2
			target_effects[0].base_power_formula.value_01 = formula_y
			target_effects[0].base_power_formula.user_faith_modifier = FormulaData.FaithModifier.UNFAITH
			target_effects[0].base_power_formula.target_faith_modifier = FormulaData.FaithModifier.UNFAITH
			# TODO random number of hits within AoE
		0x20:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			target_effects[0].base_power_formula.value_01 = formula_y
			# TODO chance to decrease inventory
		0x21:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.MP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			target_effects[0].base_power_formula.value_01 = formula_y
			# TODO chance to decrease inventory
		0x22:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.UNMODIFIED
			base_hit_formula.value_01 = 100
			# TODO chance to decrease inventory
		0x23:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			target_effects[0].base_power_formula.value_01 = formula_y
			target_effects[0].base_power_formula.reverse_sign = false # heal
			# TODO chance to decrease inventory
		0x24:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PA_plus_V1xMA_div_2
			target_effects[0].base_power_formula.value_01 = formula_y
			# TODO usable based on terrain?
		0x25:
			base_hit_formula.formula = FormulaData.Formulas.PA_plus_WP_plus_V1
			base_hit_formula.value_01 = formula_x
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.REMOVE_EQUIPMENT))
			# TODO set equipement slod id based on ability id?
		0x26:
			base_hit_formula.formula = FormulaData.Formulas.SP_plus_V1
			base_hit_formula.value_01 = formula_x
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.REMOVE_EQUIPMENT))
			target_effects[0].transfer_to_user = true
			# TODO set equipement slod id based on ability id?
		0x27:
			base_hit_formula.formula = FormulaData.Formulas.SP_plus_V1
			base_hit_formula.value_01 = formula_x
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.LVLxSPxV1
			target_effects[0].base_power_formula.value_01 = 1
			# TODO add to user currency? user_effects.append(ActionEffect.new(ActionEffect.EffectType.CURRENCY))
		0x28:
			base_hit_formula.formula = FormulaData.Formulas.SP_plus_V1
			base_hit_formula.value_01 = formula_x
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.EXP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MIN_TARGET_EXP_or_SP_plus_V1
			target_effects[0].base_power_formula.value_01 = formula_y
			target_effects[0].transfer_to_user = true
		0x29:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			# TODO hit chance based on gender
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
		0x2a:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.BRAVE))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = formula_y
			target_effects[0].base_power_formula.reverse_sign = false
			# TODO set effects based on ability id
		0x2b:
			base_hit_formula.formula = FormulaData.Formulas.PA_plus_V1
			base_hit_formula.value_01 = formula_y
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.SPEED))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = formula_x
			# TODO set effects based on ability id
		0x2c:
			base_hit_formula.formula = FormulaData.Formulas.PA_plus_V1
			base_hit_formula.value_01 = formula_y
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.MP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = formula_y / 100.0
		0x2d:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxWP_plus_V1
			target_effects[0].base_power_formula.value_01 = formula_y
			
			
			status_chance = 25
			status_list_type = StatusListType.RANDOM
		0x2e:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxWPxV1
			target_effects[0].base_power_formula.value_01 = 1
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.REMOVE_EQUIPMENT))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = 1
			# TODO set equipement slod id based on ability id?
		0x2f:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.MP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxWPxV1
			target_effects[0].base_power_formula.value_01 = 1
			target_effects[0].transfer_to_user = true
		0x30:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxWPxV1
			target_effects[0].base_power_formula.value_01 = 1
			target_effects[0].transfer_to_user = true
		0x31:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxPA_plus_V1_div_2
			target_effects[0].base_power_formula.value_01 = formula_y
		0x32:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.RANDOM_V1xPAx3_plus_V2_div_2
			target_effects[0].base_power_formula.value_01 = formula_x
			target_effects[0].base_power_formula.value_02 = formula_y
		0x33:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.PA_plus_V1
			base_hit_formula.value_01 = formula_x
		0x34:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxV1
			target_effects[0].base_power_formula.value_01 = formula_y
			target_effects[0].base_power_formula.reverse_sign = false
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.MP))
			target_effects[1].base_power_formula.formula = FormulaData.Formulas.PAxV1
			target_effects[1].base_power_formula.value_01 = formula_y / 2.0
			target_effects[1].base_power_formula.reverse_sign = false
		0x35:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.PA_plus_V1
			base_hit_formula.value_01 = formula_x
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.value_01 = formula_y
			target_effects[0].base_power_formula.reverse_sign = false
		0x36:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.PHYSICAL_ATTACK))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = formula_y
			target_effects[0].base_power_formula.reverse_sign = false
		0x37:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.RANDOM_V1xPA
			target_effects[0].base_power_formula.value_01 = formula_y
		0x38:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			status_chance = 100
		0x39:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.SPEED))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = formula_y
			target_effects[0].base_power_formula.reverse_sign = false
		0x3a:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.BRAVE))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = formula_y
			target_effects[0].base_power_formula.reverse_sign = false
		0x3b:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.BRAVE))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = formula_x
			target_effects[0].base_power_formula.reverse_sign = false
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.SPEED)) # TODO set type based on ability id
			target_effects[1].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[1].base_power_formula.value_01 = formula_y
			target_effects[1].base_power_formula.reverse_sign = false
			
		0x3c:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.value_01 = 2.0 / 5.0
			target_effects[0].base_power_formula.reverse_sign = false
			
			user_effects.append(ActionEffect.new(ActionEffect.EffectType.HP)) # TODO this should be per target
			user_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			user_effects[0].base_power_formula.value_01 = 1.0 / 5.0
		0x3d:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
		0x3e:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_CURRENT_HP_minus_V1
			target_effects[0].base_power_formula.value_01 = 1
		0x3f:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.SP_plus_V1
			base_hit_formula.value_01 = formula_x
		0x40:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.SP_plus_V1
			base_hit_formula.value_01 = formula_x
			# TODO only hit undead? or chosen status?
		0x41:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
		0x42:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxV1
			target_effects[0].base_power_formula.value_01 = formula_y
			
			user_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			user_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxV1
			user_effects[0].base_power_formula.value_01 = formula_y / formula_x
		0x43:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.USER_MISSING_HPxV1
			target_effects[0].base_power_formula.value_01 = 1
		0x44:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_CURRENT_MP_minus_V1
			target_effects[0].base_power_formula.value_01 = 0
		0x45:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MISSING_HPxV1
			target_effects[0].base_power_formula.value_01 = 1
		0x46:
			pass
		0x47:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			status_chance = 100
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.value_01 = formula_y / 100.0
		0x48:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = formula_x * 10 # maybe should be handled in Item initialization?
			target_effects[0].base_power_formula.reverse_sign = false # heal
		0x49:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.MP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = formula_x * 10 # maybe should be handled in Item initialization?
			target_effects[0].base_power_formula.reverse_sign = false # heal
		0x4a:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			#target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			#target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			#target_effects[0].base_power_formula.value_01 = formula_x * 10 # maybe should be handled in Item initialization?
			#target_effects[0].base_power_formula.reverse_sign = false # heal
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.value_01 = 1 # maybe should be handled in Item initialization?
			target_effects[0].base_power_formula.reverse_sign = false # heal
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.MP))
			target_effects[1].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_MPxV1
			target_effects[1].base_power_formula.value_01 = 1 # maybe should be handled in Item initialization?
			target_effects[1].base_power_formula.reverse_sign = false # heal
		0x4b:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			status_chance = 100
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.RANDOM_V1_V2
			target_effects[0].base_power_formula.value_01 = 1
			target_effects[0].base_power_formula.value_02 = 9
			target_effects[0].base_power_formula.reverse_sign = false # heal
		0x4c:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			target_effects[0].base_power_formula.value_01 = formula_y
			target_effects[0].base_power_formula.reverse_sign = false # heal
		0x4d:
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.value_01 = formula_y / 100.0
			target_effects[0].transfer_to_user = true
		0x4e:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			target_effects[0].base_power_formula.value_01 = formula_y
		0x4f:
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.USER_MISSING_HPxV1
			target_effects[0].base_power_formula.value_01 = 1
		0x50:
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
		0x51:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
		0x52:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			status_chance = 100
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.USER_MISSING_HPxV1
			target_effects[0].base_power_formula.value_01 = 1
			
			user_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			user_effects[0].base_power_formula.formula = FormulaData.Formulas.USER_CURRENT_HP_minus_V1
			user_effects[0].base_power_formula.value_01 = 0
		0x53:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.value_01 = formula_y
		0x54:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.MP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			target_effects[0].base_power_formula.value_01 = formula_y
			target_effects[0].base_power_formula.reverse_sign = true
		0x55:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.PHYSICAL_ATTACK))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = formula_y
		0x56:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.MAGIC_ATTACK))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = formula_y
		0x57:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.LEVEL))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = 1
			target_effects[0].base_power_formula.reverse_sign = true # add
		0x58:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			
			# TODO set MORBOL
		0x59:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.LEVEL))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = 1
		0x5a:
			status_chance = 100
			# TODO miss if target is not Dragon type
		0x5b:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			status_chance = 100
			# TODO miss if target is not Dragon type
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.value_01 = formula_y
		0x5c:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.BRAVE))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = formula_x
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.SPEED)) # TODO set type based on ability id
			target_effects[1].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[1].base_power_formula.value_01 = formula_y
			target_effects[1].base_power_formula.reverse_sign = false
			
			# TODO miss if target is not Dragon type
		0x5d:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.CT))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = 100
			target_effects[0].set_value = true
			
			# TODO miss if target is not Dragon type
		0x5e:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MA_plus_V1xMA_div_2
			target_effects[0].base_power_formula.value_01 = formula_y
			
			# TODO x+1 hits at random target in AoE
		0x5f:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MA_plus_V1xMA_div_2
			target_effects[0].base_power_formula.value_01 = formula_y
		0x60:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MA_plus_V1xMA_div_2
			target_effects[0].base_power_formula.value_01 = formula_y
		0x61:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.BRAVE))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = formula_y
		0x62:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.value_01 = formula_x
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.BRAVE))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			target_effects[0].base_power_formula.value_01 = formula_y
		0x63:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxWPxV1 # TODO SPxWP
			target_effects[0].base_power_formula.value_01 = 1
		0x64:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxWPxV1
			target_effects[0].base_power_formula.value_01 = 1 # TODO 1.5 if spear, PAxBRAVE if unarmed, else 1


static func get_element_types_array(element_bitflags: PackedByteArray) -> Array[ElementTypes]:
	var elemental_types: Array[ElementTypes] = []
	
	for byte_idx: int in element_bitflags.size():
		for bit_idx: int in range(7, -1, -1):
			var byte: int = element_bitflags.decode_u8(byte_idx)
			if byte & (2 ** bit_idx) != 0:
				var element_index: int = (7 - bit_idx) + (byte_idx * 8)
				elemental_types.append(element_index)
	
	return elemental_types

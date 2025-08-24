# https://ffhacktics.com/wiki/Formulas
# TOFU https://ffhacktics.com/smf/index.php?topic=12969.0
class_name FormulaData
extends Resource

#@export var is_modified_by_faith: bool = false
#@export var is_modified_by_element: bool = false
#@export var is_modified_by_undead: bool = false

@export var formula: Formulas = Formulas.UNMODIFIED
@export var values: PackedInt32Array = [100, 0]
@export var reverse_sign: bool = true
@export var user_faith_modifier: FaithModifier = FaithModifier.NONE
@export var target_faith_modifier: FaithModifier = FaithModifier.NONE
#@export var is_modified_by_user_faith: bool = false
#@export var is_modified_by_target_faith: bool = false
@export var is_modified_by_element: bool = true
@export var is_modified_by_zodiac: bool = true
#@export var healing_damages_undead: bool = false # needs to be on Action since formula does not know if value will be used for healing

# applicable evasion is defined on Action
#@export var physical_evasion_applies: bool = false
#@export var magical_evasion_applies: bool = false
#@export var no_evasion_applies: bool = false

# TODO default description of "Formula description could not be found"
static var formula_descriptions: Dictionary[Formulas, String] = {
	Formulas.ZERO: "0",
	Formulas.PAxV1: "PAxWP",
	Formulas.MAxV1: "MAxWP",
	Formulas.AVG_PA_MAxV1: "AVG_PA_MAxWP",
	Formulas.AVG_PA_SPxV1: "AVG_PA_SPxWP",
	Formulas.PA_BRAVExV1: "PA_BRAVExWP",
	Formulas.RANDOM_PAxV1: "RANDOM_PAxWP",
	Formulas.V1xV1: "WPxWP",
	Formulas.PA_BRAVExPA: "PA_BRAVExPA",
	}

enum FaithModifier {
	NONE,
	FAITH,
	UNFAITH,
	}

enum Formulas {
	UNMODIFIED,
	ZERO,
	PAxV1,
	MAxV1,
	AVG_PA_MAxV1,
	AVG_PA_SPxV1,
	PA_BRAVExV1,
	RANDOM_PAxV1,
	V1xV1,
	PA_BRAVExPA,
	MA_plus_V1,
	MA_plus_V1xMA_div_2,
	PA_plus_V1xMA_div_2,
	PA_plus_WP_plus_V1,
	SP_plus_V1,
	LVLxSPxV1,
	MIN_TARGET_EXP_or_SP_plus_V1,
	PA_plus_V1,
	PAxWP_plus_V1,
	PAxWPxV1,
	PAxPA_plus_V1_div_2,
	RANDOM_V1xPAx3_plus_V2_div_2,
	RANDOM_V1xPA,
	USER_MAX_HPxV1,
	USER_MAX_MPxV1,
	TARGET_MAX_HPxV1,
	TARGET_MAX_MPxV1,
	USER_CURRENT_HP_minus_V1,
	TARGET_CURRENT_MP_minus_V1,
	TARGET_CURRENT_HP_minus_V1,
	USER_MISSING_HPxV1,
	TARGET_MISSING_HPxV1,
	TARGET_CURRENT_HPxV1,
	RANDOM_V1_V2,
	}


func _init(new_formula: Formulas = Formulas.UNMODIFIED, new_values: PackedInt32Array = [1, 1], 
		new_user_faith_modifier: FaithModifier = FaithModifier.NONE, new_target_faith_modifier: FaithModifier = FaithModifier.NONE, 
		new_modified_by_element: bool = true, new_reverse_sign = true) -> void:
	formula = new_formula
	values = new_values
	user_faith_modifier = new_user_faith_modifier
	target_faith_modifier = new_target_faith_modifier
	is_modified_by_element = new_modified_by_element
	reverse_sign = new_reverse_sign


func get_result(user: UnitData, target: UnitData, element: Action.ElementTypes) -> float:
	var result: float = get_base_value(formula, user, target)
	
	match user_faith_modifier:
		FaithModifier.FAITH:
			result = faith_modify(result, user)
		FaithModifier.UNFAITH:
			result = unfaith_modify(result, user)
	
	match target_faith_modifier:
		FaithModifier.FAITH:
			result = faith_modify(result, target)
		FaithModifier.UNFAITH:
			result = unfaith_modify(result, target)
	
	result = support_modify(result, user, target)
	
	result = status_modify(result, user, target)
	
	if is_modified_by_element:
		result = element_modify(result, user, target, element)
	
	if is_modified_by_zodiac:
		result = zodiac_modify(result, user, target)
	
	return result



func get_base_value(formula: Formulas, user: UnitData, target: UnitData) -> float:
	var base_value: float = values[0]
	var wp = user.primary_weapon.weapon_power
	
	match formula:
		Formulas.UNMODIFIED:
			base_value = values[0]
		Formulas.ZERO:
			base_value = 0
		Formulas.PAxV1:
			base_value = user.physical_attack_current * values[0]
		Formulas.MAxV1:
			base_value = user.magical_attack_current * values[0]
		Formulas.AVG_PA_MAxV1:
			base_value = ((user.physical_attack_current + user.magical_attack_current) / 2.0) * values[0]
		Formulas.AVG_PA_SPxV1:
			base_value = ((user.physical_attack_current + user.speed_current) / 2.0) * values[0]
		Formulas.PA_BRAVExV1:
			base_value = (user.physical_attack_current * user.brave_current / 100.0) * values[0]
		Formulas.RANDOM_PAxV1:
			base_value = randi_range(1, user.physical_attack_current) * values[0]
		Formulas.V1xV1:
			base_value = values[0] * values[0]
		Formulas.PA_BRAVExPA:
			base_value = (user.physical_attack_current * user.brave_current / 100.0) * user.physical_attack_current
		Formulas.MA_plus_V1:
			base_value = user.magical_attack_current + values[0] # MAplusV1
		Formulas.MA_plus_V1xMA_div_2:
			base_value = (user.magical_attack_current + values[0]) * user.magical_attack_current / 2.0 # 0x1e, 0x1f, 0x5e, 0x5f, 0x60 rafa/malak
		Formulas.PA_plus_V1xMA_div_2:
			base_value = (user.physical_attack_current + values[0]) * user.magical_attack_current / 2.0 # 0x24 geomancy
		Formulas.PA_plus_WP_plus_V1:
			base_value = user.physical_attack_current + wp + values[0] # 0x25 break equipment
		Formulas.SP_plus_V1:
			base_value = user.speed_current + values[0] # 0x26 steal equipment SPplusX
		Formulas.LVLxSPxV1:
			base_value = user.level * user.speed_current * values[0] # 0x27 steal gil LVLxSP
		Formulas.MIN_TARGET_EXP_or_SP_plus_V1:
			base_value = mini(target.unit_exp, user.speed_current + values[0]) # 0x28 steal exp
		Formulas.PA_plus_V1:
			base_value = user.physical_attack_current + values[0] # 0x2b, 0x2c PAplusY
		Formulas.PAxWP_plus_V1:
			base_value = user.physical_attack_current * (wp + values[0]) # 0x2d agrais sword skills
		Formulas.PAxWPxV1:
			base_value = user.physical_attack_current * wp * values[0] # 0x2e, 0x2f, 0x30
		Formulas.PAxPA_plus_V1_div_2:
			base_value = (user.physical_attack_current + values[0]) * user.physical_attack_current / 2.0 # 0x31 monk skills
		Formulas.RANDOM_V1xPAx3_plus_V2_div_2:
			base_value = randi_range(1, values[0]) * ((user.physical_attack_current * 3) + values[1]) / 2.0 # 0x32 repeating fist # TODO 2 variables rndm to X, PA + Y
			#base_value = user.physical_attack_current * values[0] / 2.0 # 0x34 chakra\
		Formulas.RANDOM_V1xPA:
			base_value = user.physical_attack_current * randi_range(1, values[0]) # 0x37
		Formulas.USER_MAX_HPxV1:
			base_value = user.hp_max * values[0] # 0x3c wish, energy USER_MAX_HP
		Formulas.USER_MAX_MPxV1:
			base_value = user.mp_max * values[0] # USER_MAX_MP
		Formulas.TARGET_MAX_HPxV1:
			base_value = target.hp_max * values[0] # 0x09 wish, energy TARGET_MAX_HP
		Formulas.TARGET_MAX_MPxV1:
			base_value = target.mp_max * values[0] # 0x09 wish, energy TARGET_MAX_HP
		
		Formulas.USER_CURRENT_HP_minus_V1:
			base_value = user.hp_current - values[0] # 0x17, 0x3e TARGET_CURRENT_HP
		Formulas.TARGET_CURRENT_MP_minus_V1:
			base_value = target.mp_current - values[0] # 0x16 mute TARGET_CURRENT_MP
		Formulas.TARGET_CURRENT_HP_minus_V1:
			base_value = target.hp_current - values[0] # 0x17, 0x3e TARGET_CURRENT_HP
		Formulas.USER_MISSING_HPxV1:
			base_value = (user.hp_max - user.hp_current) * values[0] # 0x43 USER_MISSING_HP
		Formulas.TARGET_MISSING_HPxV1:
			base_value = (target.hp_max - target.hp_current) * values[0] # 0x45 TARGET_MISSING_HP
		Formulas.TARGET_CURRENT_HPxV1:
			base_value = target.hp_current * values[0] # TARGET_CURRENT_HP, ai status score
		Formulas.RANDOM_V1_V2:
			base_value = randi_range(values[0], values[1]) # 0x4b RANDOM_RANGE
			
			
			#base_value = action_modifier / 100.0 # % treat value as a percent when actually applying effect
			# TODO target ct?
			
	if reverse_sign:
		base_value = -base_value
	
	return base_value


func faith_modify(value: float, unit: UnitData) -> float:
	return value * unit.faith_current / 100.0


func unfaith_modify(value: float, unit: UnitData) -> float:
	return value * (100 - unit.faith_current) / 100.0


func support_modify(value: float, user: UnitData, target: UnitData) -> float:
	# TODO AttackUp, DefendUp, MartialArts, etc.
	
	return value


func status_modify(value: float, user: UnitData, target: UnitData) -> float:
	# TODO Oil, Undead?, Charging, etc.
	
	return value


func zodiac_modify(value: float, user: UnitData, target: UnitData) -> float:
	# TODO user vs target zodiac compatability
	
	return value


func element_modify(value: float, user: UnitData, target: UnitData, element: Action.ElementTypes) -> float:
	if target.elemental_cancel.has(element):
		return 0.0
	
	var new_value: float = value
	if user.elemental_strengthen.has(element):
		new_value = new_value * 1.25
	
	if target.elemental_weakness.has(element):
		new_value = new_value * 2
	
	if target.elemental_half.has(element):
		new_value = new_value / 2
	
	if target.elemental_absorb.has(element):
		if new_value < 0:
			new_value = abs(new_value) # positive is healing
	
	return new_value

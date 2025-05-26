# https://ffhacktics.com/wiki/Formulas
# TOFU https://ffhacktics.com/smf/index.php?topic=12969.0
class_name FormulaData
extends Resource

#@export var is_modified_by_faith: bool = false
#@export var is_modified_by_element: bool = false
#@export var is_modified_by_undead: bool = false

@export var formula: Formulas = Formulas.UNMODIFIED
@export var value_01: int = 100
@export var value_02: int = 0
@export var is_modified_by_user_faith: bool = false
@export var is_modified_by_target_faith: bool = false
@export var is_modified_by_element: bool = false

# applicable evasion is defined on Action
#@export var physical_evasion_applies: bool = false
#@export var magical_evasion_applies: bool = false
#@export var no_evasion_applies: bool = false

# TODO default description of "Formula description could not be found"
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
	UNMODIFIED,
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


func _init(new_formula: Formulas, new_value_01: int, new_value_02: int, new_modified_by_user_faith: bool, new_modified_by_target_faith: bool, new_modified_by_element: bool) -> void:
	formula = new_formula
	value_01 = new_value_01
	value_02 = new_value_02
	is_modified_by_user_faith = new_modified_by_user_faith
	is_modified_by_target_faith = new_modified_by_target_faith
	is_modified_by_element = new_modified_by_element


func get_result(user: UnitData, target: UnitData, element: Action.ElementTypes) -> float:
	var result: float = get_base_value(formula, user, target, value_01, value_02)
	if is_modified_by_user_faith:
		result = faith_modify(result, user)
	
	if is_modified_by_target_faith:
		result = faith_modify(result, target)
	
	result = support_modify(result, user, target)
	
	result = status_modify(result, user, target)
	
	if is_modified_by_element:
		result = element_modify(result, user, target, element)
	
	return result



func get_base_value(formula: Formulas, user: UnitData, target: UnitData, action_value_01: float, action_value_02: float = 0.0) -> float:
	var base_value: float = action_value_01
	
	match formula:
		Formulas.UNMODIFIED:
			base_value = action_value_01
		Formulas.ZERO:
			base_value = 0
		Formulas.PAxWP:
			base_value = user.physical_attack_current * action_value_01
		Formulas.MAxWP: # also MA*Y
			base_value = user.magical_attack_current * action_value_01
		Formulas.AVG_PA_MAxWP:
			base_value = ((user.physical_attack_current + user.magical_attack_current) / 2.0) * action_value_01
		Formulas.AVG_PA_SPxWP:
			base_value = ((user.physical_attack_current + user.speed_current) / 2.0) * action_value_01
		Formulas.PA_BRAVExWP:
			base_value = (user.physical_attack_current * user.brave_current / 100.0) * action_value_01
		Formulas.RANDOM_PAxWP:
			base_value = randi_range(1, user.physical_attack_current) * action_value_01
		Formulas.WPxWP:
			base_value = action_value_01 * action_value_01
		Formulas.PA_BRAVExPA:
			base_value = (user.physical_attack_current * user.brave_current / 100.0) * user.physical_attack_current
			
			
			base_value = user.magical_attack_current * action_value_01 # MA * Y
			base_value = user.magical_attack_current + action_value_01 # MAplusX
			base_value = (user.magical_attack_current + action_value_01) * user.magical_attack_current / 2.0 # 0x1e, 0x1f, 0x5e, 0x5f, 0x60 rafa/malak
			base_value = (user.physical_attack_current + action_value_01) * user.magical_attack_current / 2.0 # geomancy
			base_value = user.physical_attack_current + user.primary_weapon.weapon_attack_action.action_power + action_value_01 # break
			base_value = user.speed_current + action_value_01 # SPplusX
			base_value = user.level * user.speed_current # LVLxSP
			base_value = mini(target.unit_exp, user.speed_current + action_value_01) # 0x28 steal exp
			base_value = user.physical_attack_current + action_value_01 # 0x2b, 0x2c PAplusY
			base_value = user.physical_attack_current * (user.primary_weapon.weapon_attack_action.action_power + action_value_01) # 0x2d agrais sword skills
			base_value = user.physical_attack_current * user.primary_weapon.weapon_attack_action.action_power # 0x2e, 0x2f, 0x30
			base_value = (user.physical_attack_current + action_value_01) * user.physical_attack_current / 2.0 # 0x31 monk skills
			base_value = randi_range(1, action_value_01) * ((user.physical_attack_current * 3) + action_value_02) / 2.0 # 0x32 repeating fist # TODO 2 variables rndm to X, PA + Y
			base_value = user.physical_attack_current * action_value_01 / 2.0 # 0x34 chakra
			base_value = user.physical_attack_current * randi_range(1, action_value_01) # 0x37
			base_value = user.hp_max * action_value_01 # 0x3c wish, energy USER_MAX_HP
			base_value = user.mp_max * action_value_01 # USER_MAX_MP
			base_value = target.mp_current - action_value_01 # 0x16 mute TARGET_CURRENT_MP
			base_value = target.hp_current - action_value_01 # 0x17, 0x3e TARGET_CURRENT_HP
			base_value = (user.hp_max - user.hp_current) * action_value_01 # 0x43 USER_MISSING_HP
			base_value = (target.hp_max - target.hp_current) * action_value_01 # 0x45 TARGET_MISSING_HP
			base_value = randi_range(action_value_01, action_value_02) # 0x4b RANDOM_RANGE
			
			
			#base_value = action_modifier / 100.0 # % treat value as a percent when actually applying effect
			
			# TODO target ct?
	
	return base_value


func faith_modify(value: float, unit: UnitData) -> float:
	return value * unit.faith_current / 100.0


func unfaith_modify(value: float, unit: UnitData) -> float:
	return value * (100 - unit.faith_current) / 100.0


func support_modify(value: float, user: UnitData, target: UnitData) -> float:
	# TODO AttackUp, DefendUp, MartialArts, etc.
	
	return value


func status_modify(value: float, user: UnitData, target: UnitData) -> float:
	# TODO Oil, Undead, Charging, etc.
	
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
		if new_value > 0:
			new_value = -new_value
	
	return new_value




func dmg_weapon_01() -> void:
	# damage calculation - base damage, modifiers (elements, status, zodiac, support abilities, critical hits, charge+x abilities)
	# apply status
	# post action proc # https://ffhacktics.com/wiki/02_Dmg_(Weapon)
	# reaction?
	pass


func get_hit_chance() -> int:
	var hit_chance: int = 100
	
	# check evades
	
	# check user and target faith?
	
	return hit_chance
	

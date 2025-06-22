class_name ActionEffect
extends Resource

@export var base_power_formula: FormulaData = FormulaData.new(FormulaData.Formulas.PAxV1, 5, 0, FormulaData.FaithModifier.NONE, FormulaData.FaithModifier.NONE, true)
@export var type: EffectType = EffectType.UNIT_STAT
@export var effect_stat_type: UnitData.StatType = UnitData.StatType.HP
var show_ui: bool = true
var transfer_to_user: bool = false # absorb, steal
var apply_to_user: bool = false
var set_value: bool = false # fales = add value, true = set value

enum EffectType {
	UNIT_STAT,
	CURRENCY,
	INVENTORY,
	#BREAK_EQUIPMENT, # Break is Remove equipment + lower inventory?
	REMOVE_EQUIPMENT, # Steal if transfer = true
	#PHYSICAL_EVADE, 
	#MAGIC_EVADE,
	}


func _init(new_type: EffectType = EffectType.UNIT_STAT, new_effect_stat: UnitData.StatType = UnitData.StatType.HP, new_show_ui: bool = true, new_transfer_to_user: bool = false, new_set_value: bool = false) -> void:
	type = new_type
	effect_stat_type = new_effect_stat
	show_ui = new_show_ui
	transfer_to_user = new_transfer_to_user
	set_value = new_set_value


func get_value(user: UnitData, target: UnitData, element: Action.ElementTypes) -> int:
	return roundi(base_power_formula.get_result(user, target, element))


func get_ai_value(user: UnitData, target: UnitData, element: Action.ElementTypes) -> int:
	var nominal_value: int = roundi(base_power_formula.get_result(user, target, element))
	var is_friendly: bool = target.team == user.team
	var ai_value: int = nominal_value
	
	if type == EffectType.UNIT_STAT:
		if set_value:
			ai_value = target.stats[effect_stat_type].get_set_delta(nominal_value)
		else:
			ai_value = target.stats[effect_stat_type].get_add_delta(nominal_value)
	else:
		ai_value = 0 # TODO remove equipment should not be 0, check changes/modifiers for stats, statuses, element interactions
	
	if not is_friendly:
		ai_value = -ai_value
	
	return ai_value


func apply_value(apply_unit: UnitData, value: int) -> int:
	var type_name: String = EffectType.keys()[type]
	
	match type:
		EffectType.UNIT_STAT:
			type_name = UnitData.StatType.keys()[effect_stat_type]
			if set_value:
				apply_unit.stats[effect_stat_type].set_value(value)
			else:
				apply_unit.stats[effect_stat_type].add_value(value)
		EffectType.CURRENCY:
			type_name = "Gold"
			if set_value:
				apply_unit.team.currency = value
			else:
				apply_unit.team.currency += value
		EffectType.INVENTORY:
			if set_value:
				apply_unit.team.inventory[0] = value # TODO get inventory item id to change
			else:
				apply_unit.team.inventory[0] += value # TODO get inventory item id to change
		EffectType.REMOVE_EQUIPMENT:
			apply_unit.change_equipment(0, null) # TODO get equipment slot id to change
	
	var text: String = str(value) + " " + type_name
	if value > 0:
		text = "+" + text
	
	if set_value:
		text = type_name + " = " + str(value)
	
	apply_unit.show_popup_text(text)
	
	return value

func apply(user: UnitData, target: UnitData, value: int) -> int:
	var apply_unit: UnitData = target
	if apply_to_user:
		apply_unit = user
	
	value = apply_value(apply_unit, value)
	
	if transfer_to_user:
		apply_value(user, -value)
	
	return value

class_name ActionEffect
extends Resource

@export var base_power_formula: FormulaData = FormulaData.new(FormulaData.Formulas.PAxV1, 5, 0, FormulaData.FaithModifier.NONE, FormulaData.FaithModifier.NONE, true)
@export var type: EffectType = EffectType.HP
var show_ui: bool = true
var transfer_to_user: bool = false # absorb, steal
var apply_to_user: bool = false
var set_value: bool = false # fales = add value, true = set value

enum EffectType {
	HP, # Absorb if transfer = true
	MP,
	CT,
	MOVE,
	JUMP,
	SPEED,
	PHYSICAL_ATTACK,
	MAGIC_ATTACK,
	BRAVE,
	FAITH,
	EXP,
	LEVEL,
	CURRENCY,
	INVENTORY,
	#BREAK_EQUIPMENT, # Break is Remove equipment + lower inventory?
	REMOVE_EQUIPMENT, # Steal if transfer = true
	#PE,
	#ME,
	}


func _init(new_type: EffectType, new_show_ui: bool = true, new_transfer_to_user: bool = false, new_set_value: bool = false) -> void:
	type = new_type
	show_ui = new_show_ui
	transfer_to_user = new_transfer_to_user
	set_value = new_set_value


func apply(user: UnitData, target: UnitData, value: int) -> int:
	var unit: UnitData = target
	if apply_to_user:
		unit = user
	
	match type:
		EffectType.HP:
			if set_value:
				unit.hp_current = value
			else:
				unit.hp_current += value
		EffectType.MP:
			if set_value:
				unit.mp_current = value
			else:
				unit.mp_current += value
		EffectType.CT:
			if set_value:
				unit.ct_current = value
			else:
				unit.ct_current += value
		EffectType.MOVE:
			if set_value:
				unit.move_current = value
			else:
				unit.move_current += value
		EffectType.JUMP:
			if set_value:
				unit.jump_current = value
			else:
				unit.jump_current += value
		EffectType.SPEED:
			if set_value:
				unit.speed_current = value
			else:
				unit.speed_current += value
		EffectType.PHYSICAL_ATTACK: # TODO way to modify MA
			if set_value:
				unit.hp_current = value
			else:
				unit.hp_current += value
		EffectType.MAGIC_ATTACK: # TODO way to modify MA
			if set_value:
				unit.hp_current = value
			else:
				unit.hp_current += value
		EffectType.BRAVE:
			if set_value:
				unit.brave_current = value
			else:
				unit.brave_current += value
		EffectType.FAITH:
			if set_value:
				unit.faith_current = value
			else:
				unit.faith_current += value
		EffectType.EXP:
			if set_value:
				unit.unit_exp = value
			else:
				unit.unit_exp += value
		EffectType.LEVEL:
			if set_value:
				unit.level = value
			else:
				unit.level += value
		EffectType.CURRENCY:
			if set_value:
				unit.team.currency = value
			else:
				unit.team.currency += value
		EffectType.INVENTORY:
			if set_value:
				unit.team.inventory[0] = value # TODO get inventory item id to change
			else:
				unit.team.inventory[0] += value # TODO get inventory item id to change
		EffectType.REMOVE_EQUIPMENT:
			unit.change_equipment(0, 0) # TODO get equipment slot id to change
	
	return value
	

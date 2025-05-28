class_name ActionEffect
extends Resource

var type: EffectType = EffectType.HP
var show_ui: bool = true
var transfer_target_to_user: bool = false # absorb, steal
var set_value: bool = false # fales = add value, true = set value

# on caster?

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
	BREAK_EQUIPMENT,
	REMOVE_EQUIPMENT, # Steal if transfer = true
	#PE,
	#ME,
	}


func _init(new_type: EffectType, new_show_ui: bool = true, new_transfer_target_to_user: bool = false, new_set_value: bool = false) -> void:
	type = new_type
	show_ui = new_show_ui
	transfer_target_to_user = new_transfer_target_to_user
	set_value = new_set_value


func apply(user: UnitData, target: UnitData, value: int) -> int:
	match type:
		EffectType.HP:
			target.hp_current += value
	
	return value
	

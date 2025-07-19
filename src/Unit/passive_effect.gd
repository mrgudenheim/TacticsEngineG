class_name PassiveEffect
extends Resource

var hit_chance_modifier_user: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
var hit_chance_modifier_targeted: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
var power_modifier_user: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
var power_modifier_targeted: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
var evade_modifier_user: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
var evade_modifier_targeted: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)

var ct_gain_modifier: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)


var stat_modifiers: Array[Modifier] = []

## dark, confusion, monster talk
#func modify_hit_chance_user(value: float) -> float:
	#var new_value: float = value * hit_chance_modifier_user
	#
	#return new_value
#
#
## protect, shell, frog, chicken, sleeping, charging, def up, mdef up, 
#func modify_hit_chance_targeted(value: float) -> float:
	#var new_value: float = value * hit_chance_modifier_targeted
	#
	#return new_value
#
#
## atk up, ma up, two hands, martial arts
#func modify_power_user(value: float) -> float:
	#var new_value: float = value * power_modifier_user
	#
	#return new_value
#
#
## protect, shell, frog, chicken, sleeping, charging, def up, mdef up, 
#func modify_power_targeted(value: float) -> float:
	#var new_value: float = value * power_modifier_targeted
	#
	#return new_value
#
#
## concentrate, transparent, night/weather
#func modify_evade_user(value: float) -> float:
	#var new_value: float = value * evade_modifier_user
	#
	#return new_value
#
#
## abandon, defending, blade grasp, dont act, sleep, stop, confuse, charging, performing
#func modify_evade_targeted(value: float) -> float:
	#var new_value: float = value * evade_modifier_targeted
	#
	#return new_value


func modify_stat() -> void:
	pass


# https://ffhacktics.com/wiki/Target_XA_affecting_Statuses_(Physical)
# https://ffhacktics.com/wiki/Target%27s_Status_Affecting_XA_(Magical)
# https://ffhacktics.com/wiki/Evasion_Changes_due_to_Statuses
# evade also affected by transparent, concentrate, dark or confuse, on user


#STATUS
#Execute action - charging, performing, jumping, death sentence, Regen, poison, reraise, undead, 
#Affect CT gain - slow, haste, stop, freeze CT flag
#Affect skillet/actions available - blood suck, frog, chicken
#Affect control - charm, invite, berserk, confuse, blood suck
#Affect evade - darkness, confuse, transparent, defending, don't act, sleep, stop, charging, performing
#Affect hit chance - protect, shell, frog, chicken, sleep, etc.
#Affect calculation - protect, shell, faith/innocent, charging, undead, (golem)
#Affect elemental affinity - float, (oil - in addition to element)
#Affect usable actions - silence, don't act/move
#Counts as defeated - dead, crystal, petrify, poached, etc
#Affects ai - critical, transparent
#affects targeting - float, reflect
#Affect reactions - transparent
#
#Reaction/Support/Move:
#Affect CT gain - 
#Affect skillet/actions - defend, equip change, two swords, beast master
#Affect control - 
#Affect evade - concentrate, abandon, blade grasp, monster talk
#Affect calculation - Atk Up, Ma Up, Def Up, MDef up, two hands, martial arts
#Affect elemental affinity - 
#Affect usable actions - 
#Counts as defeated - 
#Affects ai - 
#affects targeting - move+/jump+, throw item, ignore height
#Affect reactions - 
#Affects equipment - Equip x
#
#jp up, exp up, 
#maintenance, 
#affects stat - move+/jump+, hp up, item attributes
#short charge, no charge, poach, tame, half mp, 

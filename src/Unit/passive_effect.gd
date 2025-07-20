class_name PassiveEffect
extends Resource

var hit_chance_modifier_user: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
var hit_chance_modifier_targeted: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
var power_modifier_user: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
var power_modifier_targeted: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
var evade_modifier_user: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
var evade_modifier_targeted: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
var ct_gain_modifier: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)

var ai_strategy: UnitAi.Strategy = UnitAi.Strategy.PLAYER
var added_actions: Array[Action] = []
var added_equipment_types: Array[int] = []
var stat_modifiers: Dictionary[UnitData.StatType, Modifier] = {}

@export var elemental_absorb: Array[Action.ElementTypes] = [] # 1 byte of bitflags, elemental types
@export var elemental_cancel: Array[Action.ElementTypes] = [] # 1 byte of bitflags, elemental types
@export var elemental_half: Array[Action.ElementTypes] = [] # 1 byte of bitflags, elemental types
@export var elemental_weakness: Array[Action.ElementTypes] = [] # 1 byte of bitflags, elemental types
@export var elemental_strengthen: Array[Action.ElementTypes] = [] # 1 byte of bitflags, elemental types

var can_react: bool = true
var target_can_react: bool = true
var nullify_targeted: bool = false # ignore_attacks flag

# TODO affects targeting - float - can attack 1 higher, jump 1 higher, ignore depth and terrain cost, counts as 1 higher when being targeted, chicken/frog counts as further? maybe targeting just checks sprite height var
# TODO reflect


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
#Affects ai - critical, transparent, do_not_target flag? (Confusion/Transparent/Charm/Sleep)
#affects targeting - float, reflect
#Affect reactions - transparent, dont act, sleep, can_react flag
# ignore_attacks flag - attacks do not animate or do anything
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
#affects targeting - throw item, ignore height
#Affect reactions - 
#Affects equipment - Equip x
#
#jp up, exp up, 
#maintenance, 
#affects stat - move+/jump+, max_hp up, item attributes
#affects action data - short charge, no charge, half mp, poach (secondary action?), tame (secondary action?) 

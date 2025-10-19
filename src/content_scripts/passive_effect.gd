class_name PassiveEffect
extends Resource

const SAVE_DIRECTORY_PATH: String = "user://overrides/passive_effects/"
const FILE_SUFFIX: String = "passive_effect"
@export var unique_name: String = "unique_name"

@export var hit_chance_modifier_user: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
@export var hit_chance_modifier_targeted: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
@export var power_modifier_user: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
@export var power_modifier_targeted: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
@export var evade_modifier_user: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
@export var evade_modifier_targeted: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
@export var ct_gain_modifier: Modifier = Modifier.new(1.0, Modifier.ModifierType.MULT)
# TODO generalize to target or user Stat effective modifier

@export var ai_strategy: UnitAi.Strategy = UnitAi.Strategy.PLAYER
@export var added_actions: Array[Action] = []
@export var added_equipment_type_proficiencies: Array[int] = [] # equip x support abilities
@export var stat_modifiers: Dictionary[UnitData.StatType, Modifier] = {}

@export var element_absorb: Array[Action.ElementTypes] = []
@export var element_cancel: Array[Action.ElementTypes] = []
@export var element_half: Array[Action.ElementTypes] = []
@export var element_weakness: Array[Action.ElementTypes] = []
@export var element_strengthen: Array[Action.ElementTypes] = []

@export var status_always: PackedStringArray = []
@export var status_immune: PackedStringArray = []
@export var status_start: PackedStringArray = []

@export var can_react: bool = true
@export var target_can_react: bool = true
@export var nullify_targeted: bool = false # ignore_attacks flag


func add_to_global_list(will_overwrite: bool = false) -> void:
	if ["", "unique_name"].has(unique_name):
		push_warning("needs unique name added")
	if RomReader.passive_effects.keys().has(unique_name) and will_overwrite:
		push_warning("Overwriting existing passive effect: " + unique_name)
	elif RomReader.passive_effects.keys().has(unique_name) and not will_overwrite:
		var num: int = 2
		var formatted_num: String = "%02d" % num
		var new_unique_name: String = unique_name + "_" + formatted_num
		while RomReader.passive_effects.keys().has(new_unique_name):
			num += 1
			formatted_num = "%02d" % num
			new_unique_name = unique_name + "_" + formatted_num
		
		push_warning("PassiveEffect list already contains: " + unique_name + ". Incrementing unique_name to: " + new_unique_name)
		unique_name = new_unique_name
	
	RomReader.passive_effects[unique_name] = self


func to_json() -> String:
	var properties_to_exclude: PackedStringArray = [
		"RefCounted",
		"Resource",
		"resource_local_to_scene",
		"resource_path",
		"resource_name",
		"resource_scene_unique_id",
		"script",
	]
	return Utilities.object_properties_to_json(self, properties_to_exclude)


static func create_from_json(json_string: String) -> PassiveEffect:
	var property_dict: Dictionary = JSON.parse_string(json_string)
	var new_passive_effect: PassiveEffect = create_from_dictionary(property_dict)
	
	return new_passive_effect


static func create_from_dictionary(property_dict: Dictionary) -> PassiveEffect:
	var new_passive_effect: PassiveEffect = PassiveEffect.new()
	for property_name in property_dict.keys():
		if property_name == "stat_modifiers":
			var new_stat_modifiers: Dictionary[UnitData.StatType, Modifier] = {}
			var temp_dict = property_dict[property_name]
			for key in temp_dict:
				new_stat_modifiers[int(key)] = Modifier.create_from_dictionary(temp_dict[key])
			new_passive_effect.set(property_name, new_stat_modifiers)
		elif property_name.contains("modifier"):
			var new_modifier: Modifier = Modifier.create_from_dictionary(property_dict[property_name])
			new_passive_effect.set(property_name, new_modifier)
		else:	
			new_passive_effect.set(property_name, property_dict[property_name])

	new_passive_effect.emit_changed()
	return new_passive_effect

# TODO affects targeting - float - can attack 1 higher, jump 1 higher, ignore depth and terrain cost, counts as 1 higher when being targeted, chicken/frog counts as further? maybe targeting just checks sprite height var
# TODO reflect
# TODO undead healing -> damage
# TODO invite, charm
# TODO modify action - short charge, no charge, half mp, poach (secondary action?), tame (secondary action?) 

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
#affects targeting - throw item, ignore height, jump (lancer abilities)
#Affect reactions - 
#Affects equipment - Equip x
#
#jp up, exp up, 
#maintenance, 
#affects stat - move+/jump+, max_hp up, item attributes
#affects action data - short charge, no charge, half mp, poach (secondary action?), tame (secondary action?) 

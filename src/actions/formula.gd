# https://ffhacktics.com/wiki/Formulas
# TOFU https://ffhacktics.com/smf/index.php?topic=12969.0
class_name Formula
extends Resource

@export var is_modified_by_faith: bool = false

# applicable evasion is defined on Action
#@export var physical_evasion_applies: bool = false
#@export var magical_evasion_applies: bool = false
#@export var no_evasion_applies: bool = false

func dmg_weapon_01() -> void:
	# hit chance - base hit, evade
	# damage calculation - base damage, modifiers (elements, status, zodiac, support abilities, critical hits, charge+x abilities)
	# apply status
	# post action proc # https://ffhacktics.com/wiki/02_Dmg_(Weapon)
	pass


func get_hit_chance() -> int:
	var hit_chance: int = 100
	
	# check evades
	
	# check user and target faith?
	
	return hit_chance
	

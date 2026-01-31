class_name AbilitySlot
extends Resource

@export var ability_slot_name: String = "[Ability Slot]"
@export var slot_types: Array[Ability.SlotType] = []
@export var ability_unique_name: String
var ability: Ability:
	get: return RomReader.abilities[ability_unique_name]

func _init(new_name: String = "", new_slot_types: Array[Ability.SlotType] = [], new_ability_unique_name: String = "") -> void:
	ability_slot_name = new_name
	slot_types = new_slot_types
	ability_unique_name = new_ability_unique_name

func _to_string() -> String:
	return ability_slot_name + ": " + ability.display_name
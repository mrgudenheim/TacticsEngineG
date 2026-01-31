class_name AbilitySlot
extends Resource

var ability_slot_name: String = "[Ability Slot]"
var slot_types: Array[Ability.SlotType] = []
var ability_unique_name: String
var ability_idx: int = 0
var ability: Ability = Ability.new()

func _init(new_name: String = "", new_slot_types: Array[Ability.SlotType] = [], new_ability: Ability = Ability.new()) -> void:
	ability_slot_name = new_name
	slot_types = new_slot_types
	ability = new_ability

func _to_string() -> String:
	return ability_slot_name + ": " + ability.display_name
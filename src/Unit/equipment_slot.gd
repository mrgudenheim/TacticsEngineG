class_name EquipmentSlot
extends Resource

var equipment_slot_name: String = "[Equipment Slot]"
var slot_types: Array[ItemData.SlotType] = []
var item_idx: int = 0
var item: ItemData:
	get:
		return RomReader.items_array[item_idx]

func _init(new_name: String = "", new_slot_types: Array[ItemData.SlotType] = [], new_item_idx: int = 0) -> void:
	equipment_slot_name = new_name
	slot_types = new_slot_types
	item_idx = new_item_idx

func _to_string() -> String:
	return equipment_slot_name + ": " + item.display_name
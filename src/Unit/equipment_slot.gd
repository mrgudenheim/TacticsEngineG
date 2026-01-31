class_name EquipmentSlot
extends Resource

@export var equipment_slot_name: String = "[Equipment Slot]"
@export var slot_types: Array[ItemData.SlotType] = []
@export var item_unique_name: String
var item: ItemData:
	get:
		return RomReader.items[item_unique_name]

func _init(new_name: String = "", new_slot_types: Array[ItemData.SlotType] = [], new_item_unique_name: String = "") -> void:
	equipment_slot_name = new_name
	slot_types = new_slot_types
	item_unique_name = new_item_unique_name

func _to_string() -> String:
	return equipment_slot_name + ": " + item.display_name
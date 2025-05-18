# https://ffhacktics.com/wiki/Status_Effects
# https://ffhacktics.com/wiki/Status_Check_table_-_0x800662d0
class_name StatusEffect
extends Resource

@export var status_effect_name: String = "Status effect name"
@export var description: String = "Status effect description"

var byte_00: int = 0
var byte_01: int = 0
@export var order: int = 0
@export var ct: int = 10
@export_flags("Freeze CT", "(Crystal/Treasure)", "(Defend/Perform)", "(Poison/Regen)", "(Confusion/Transparent/Charm/Sleep)", "(Checks 3)", "(Checks 2)", "Counts as KO") var checks_01: int = 0
@export_flags("Cant React", "Unknown", "Ignore Attcks", "(Checks 10)", "(Checks 9)", "(Checks 8)", "(Checks 7 - Cancelled by Immortal?)", "(Checks 6)") var checks_02: int = 0
@export var status_cancels: PackedByteArray = [] # 5 bytes of bitflags for up to 40 statuses
@export var status_cant_stack: PackedByteArray = [] # 5 bytes of bitflags for up to 40 statuses

func set_data(status_effect_bytes: PackedByteArray) -> void:
	byte_00 = status_effect_bytes.decode_u8(0)
	byte_01 = status_effect_bytes.decode_u8(1)
	order = status_effect_bytes.decode_u8(2)
	ct = status_effect_bytes.decode_u8(3)
	checks_01 = status_effect_bytes.decode_u8(4)
	checks_02 = status_effect_bytes.decode_u8(5)
	status_cancels = status_effect_bytes.slice(6, 11)
	status_cant_stack = status_effect_bytes.slice(11, 16)

# https://ffhacktics.com/wiki/Status_Effects
# https://ffhacktics.com/wiki/Status_Check_table_-_0x800662d0
class_name StatusEffect
extends Resource

@export var status_effect_name: String = "Status effect name"
@export var description: String = "Status effect description"

var byte_00: int = 0
var byte_01: int = 0
@export var order: int = 0
@export var duration: int = 10
@export_flags("Freeze CT", "(Crystal/Treasure)", "(Defend/Perform)", "(Poison/Regen)", "(Confusion/Transparent/Charm/Sleep)", "(Checks 3)", "(Checks 2)", "Counts as KO") var checks_01: int = 0
@export_flags("Cant React", "Unknown", "Ignore Attcks", "(Checks 10)", "(Checks 9)", "(Checks 8)", "(Checks 7 - Cancelled by Immortal?)", "(Checks 6)") var checks_02: int = 0
@export var status_cancels_flags: PackedByteArray = [] # 5 bytes of bitflags for up to 40 statuses 
@export var status_cant_stack_flags: PackedByteArray = [] # 5 bytes of bitflags for up to 40 statuses

@export var status_cancels: Array[StatusEffect] = [] 
@export var status_cant_stack: Array[StatusEffect] = [] # TODO use bit index as index into StatusEffect array

enum DurationType {
	TICKS,
	TURNS, # death sentance, dead -> crystal/treasure
}
var duration_type: DurationType = DurationType.TICKS
@export var action_on_turn_start: Action
@export var action_on_turn_end: Action
@export var action_on_x_ticks: Action
@export var x_ticks: int
@export var action_on_complete: Action # charging, dead -> crystal/treasure

var visual_effect # TODO speech bubbles, sprite coloring, animation (haste, dead, etc.), float, etc.
@export var unit_shading_color: Color
@export var unit_shading_type: int
@export var status_bubble_texture: Texture2D # from Frame.bin
@export var unit_idle_animation_id: int


func set_data(status_effect_bytes: PackedByteArray) -> void:
	byte_00 = status_effect_bytes.decode_u8(0)
	byte_01 = status_effect_bytes.decode_u8(1)
	order = status_effect_bytes.decode_u8(2)
	duration = status_effect_bytes.decode_u8(3)
	checks_01 = status_effect_bytes.decode_u8(4)
	checks_02 = status_effect_bytes.decode_u8(5)
	status_cancels_flags = get_status_array(status_effect_bytes.slice(6, 11))
	status_cant_stack_flags = get_status_array(status_effect_bytes.slice(11, 16))


# called after all StatusEffects have already been initialized since this indexes into the complete array
func status_flags_to_status_array() -> void:
	status_cancels = get_status_array(status_cancels_flags)
	status_cant_stack = get_status_array(status_cant_stack_flags)


static func get_status_array(status_bitflags: PackedByteArray) -> Array[StatusEffect]:
	var status_array: Array[StatusEffect] = []
	
	#if RomReader.status_effects.is_empty():
		#push_warning("Trying to get StatusEffects before they are loaded")
		#return status_array
	
	for byte_idx: int in status_bitflags.size():
		for bit_idx: int in range(7, -1, -1):
			var byte: int = status_bitflags.decode_u8(byte_idx)
			if byte & (2 ** bit_idx) != 0:
				var status_index: int = (7 - bit_idx) + (byte_idx * 8)
				status_array.append(RomReader.scus_data.status_effects[status_index])
	
	return status_array


#Status Set 1
#0x80 - 
#0x40 - Crystal
#0x20 - Dead
#0x10 - Undead
#0x08 - Charging
#0x04 - Jump
#0x02 - Defending
#0x01 - Performing
#Status Set 2
#0x80 - Petrify
#0x40 - Invite
#0x20 - Darkness
#0x10 - Confusion
#0x08 - Silence
#0x04 - Blood Suck
#0x02 - Cursed
#0x01 - Treasure
#Status Set 3
#0x80 - Oil
#0x40 - Float
#0x20 - Reraise
#0x10 - Transparent
#0x08 - Berserk
#0x04 - Chicken
#0x02 - Frog
#0x01 - Critical
#Status Set 4
#0x80 - Poison
#0x40 - Regen
#0x20 - Protect
#0x10 - Shell
#0x08 - Haste
#0x04 - Slow
#0x02 - Stop
#Status Set 5
#0x80 - Faith
#0x40 - Innocent
#0x20 - Charm
#0x10 - Sleep
#0x08 - Don't Move
#0x04 - Don't Act
#0x02 - Reflect
#0x01 - Death Sentence

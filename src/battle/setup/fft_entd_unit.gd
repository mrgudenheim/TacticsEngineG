class_name FftEntdUnit
extends Resource

@export var sprite_id: int = 0
@export var flags1: int = 0
@export var name_idx: int = 0
@export var level: int = 0
@export var birthday_month: int = 0
@export var birthday_day: int = 0
@export var brave: int = 0
@export var faith: int = 0
@export var job_unlock: int = 0
@export var job_level: int = 0

@export var main_job: int = 0
@export var secondary_skillset: int = 0
@export var reaction: int = 0
@export var support: int = 0
@export var movement: int = 0

@export var equipment_head: int = 0
@export var equipment_body: int = 0
@export var equipment_accessory: int = 0
@export var equipment_right_hand: int = 0
@export var equipment_left_hand: int = 0

@export var palette: int = 0
@export var flags2: int = 0
@export var position_x: int = 0
@export var position_y: int = 0
@export var initial_direction: int = 0
@export var experience: int = 0
@export var x1d: int = 0
@export var x1e: int = 0
@export var unit_id: int = 0
@export var x21: int = 0
@export var flags3: int = 0
@export var target_unit_id: int = 0
@export var x25: int = 0
@export var x26: int = 0
@export var x27: int = 0

func _init(bytes: PackedByteArray) -> void:
	sprite_id = bytes.decode_u8(0)
	flags1 = bytes.decode_u8(1)
	name_idx = bytes.decode_u8(2)
	level = bytes.decode_u8(3)
	birthday_month = bytes.decode_u8(4)
	birthday_day = bytes.decode_u8(5)
	brave = bytes.decode_u8(6)
	faith = bytes.decode_u8(7)
	job_unlock = bytes.decode_u8(8)
	job_level = bytes.decode_u8(9)
	
	main_job = bytes.decode_u8(0xa)
	secondary_skillset = bytes.decode_u8(0xb)
	reaction = bytes.decode_u16(0xc)
	support = bytes.decode_u16(0xe)
	movement = bytes.decode_u16(0x10)
	
	equipment_head = bytes.decode_u8(0x12)
	equipment_body = bytes.decode_u8(0x13)
	equipment_accessory = bytes.decode_u8(0x14)
	equipment_right_hand = bytes.decode_u8(0x15)
	equipment_left_hand = bytes.decode_u8(0x16)
	
	palette = bytes.decode_u8(0x17)
	flags2 = bytes.decode_u8(0x18)
	position_x = bytes.decode_u8(0x19)
	position_y = bytes.decode_u8(0x1a)
	initial_direction = bytes.decode_u8(0x1b)
	experience = bytes.decode_u8(0x1c)
	x1d = bytes.decode_u8(0x1d)
	x1e = bytes.decode_u16(0x1e)
	unit_id = bytes.decode_u8(0x20)
	x21 = bytes.decode_u16(0x21)
	flags3 = bytes.decode_u8(0x23)
	target_unit_id = bytes.decode_u8(0x24)
	x25 = bytes.decode_u8(0x25)
	x26 = bytes.decode_u8(0x26)
	x27 = bytes.decode_u8(0x27)

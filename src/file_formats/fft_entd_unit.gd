class_name FftEntdUnit
extends Resource

@export var sprite_set_id: int = 0 # 0x80 = generic male, 0x81 = generic female, 0x82 = monster, <0x80 = special unit

@export var flags1: int = 0 # 0x80 = male, 0x40 = female, 0x20 = monster
@export var gender: int = 0
@export var join_after_event: bool = false # 0x10
@export var load_formation: bool = false # 0x08 looks for unit id in roster to load stats, used for guests?
@export var hide_stats: bool = false # 0x04 shows ??? instead of stat values
@export var flag1_02: int = 0 # 0x02 unknown
@export var join_as_guest: bool = false # 0x01

@export var name_idx: int = 0
@export var level: int = 0 # 0xFE = party_level - random
@export var birthday_month: int = 0
@export var birthday_day: int = 0
@export var brave: int = 0 # 0xFE = random
@export var faith: int = 0 # 0xFE = random
@export var job_unlock: int = 0
@export var job_level: int = 0

@export var main_job: int = 0
@export var secondary_skillset: int = 0  # 0x00 = none
@export var reaction: int = 0 # 0xFE01 = random
@export var support: int = 0 # 0xFE01 = random
@export var movement: int = 0 # 0xFE01 = random

@export var equipment_head: int = 0 # 0xFE = random
@export var equipment_body: int = 0 # 0xFE = random
@export var equipment_accessory: int = 0 # 0xFE = random
@export var equipment_right_hand: int = 0 # 0xFE = random
@export var equipment_left_hand: int = 0 # 0xFE = random

@export var palette: int = 0

@export var flags2: int = 0 # 0x80 = always present, 0x40 = randomly present
@export var always_present: bool = true # always or randomly
@export var randomly_present: bool = false
@export var team_color: int = 0 # 0x30 => 0x00 = blue, 0x01 = red, 0x02 = green, 0x03 = light blue
@export var is_player_controlled: bool = false # 0x08
@export var is_immortal: bool = false # 0x04

@export var position_x: int = 0
@export var position_y: int = 0

@export var flags3: int = 0
@export var upper_level: int = 0 #0x80
@export var initial_direction: int = 0 #0x00 = South, 0x02 = East, 0x02 = North, 0x03 = West

@export var experience: int = 0
@export var primary_skillset: int = 0
@export var reward_money: int = 0 # x100 for actual reward
@export var reward_item: int = 0
@export var unit_id: int = 0
@export var ai_target_x: int = 0
@export var ai_target_y: int = 0

@export var flags4: int = 0
@export var focus_unit: bool = false # 0x40 focused unit id stored in other variable
@export var stay_near_xy: bool = false # 0x20 position stored in other variables
@export var aggressive: bool = false # 0x10 position stored in other variables
@export var defensive: bool = false # 0x08 position stored in other variables

@export var target_unit_id: int = 0
@export var x25: int = 0
@export var flags5: int = 0
@export var conserve_ct: bool = false
@export var x27: int = 0

func _init(bytes: PackedByteArray) -> void:
	sprite_set_id = bytes.decode_u8(0)
	
	flags1 = bytes.decode_u8(1)
	gender = (flags1 & 0xe0) >> 5 # 4 = male, 2 = female, 1 = monster
	join_after_event = (flags1 & 0x10) == 0x10 # 0x10
	load_formation = (flags1 & 0x08) == 0x08 # 0x08 looks for unit id in roster to load stats, used for guests?
	hide_stats = (flags1 & 0x04) == 0x04 # 0x04 shows ??? instead of stat values
	flag1_02 = (flags1 & 0x02) # 0x02 unknown
	join_as_guest = (flags1 & 0x01) == 0x01 # 0x01
	
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
	always_present = (flags2 & 0x80) == 0x80 # always or randomly
	randomly_present = (flags2 & 0x40) == 0x40
	team_color = (flags2 & 0x30) >> 4 # 0x30 => 0x00 = blue, 0x01 = red, 0x02 = green, 0x03 = light blue
	is_player_controlled = (flags2 & 0x08) == 0x08 # 0x08
	is_immortal = (flags2 & 0x04) == 0x04 # 0x04
	
	position_x = bytes.decode_u8(0x19)
	position_y = bytes.decode_u8(0x1a)
	
	flags3 = bytes.decode_u8(0x1b)
	upper_level = (flags3 & 0x80) >> 7 #0x80
	initial_direction = flags3 & 0x03 #0x00 = South, 0x02 = East, 0x02 = North, 0x03 = West
	
	experience = bytes.decode_u8(0x1c)
	primary_skillset = bytes.decode_u8(0x1d)
	reward_item = bytes.decode_u8(0x1e)
	reward_money = bytes.decode_u8(0x1f)
	unit_id = bytes.decode_u8(0x20)
	ai_target_x = bytes.decode_u8(0x21)
	ai_target_y = bytes.decode_u8(0x22)
	
	flags4 = bytes.decode_u8(0x23)
	focus_unit = (flags4 & 0x40) == 0x40 # 0x40 focused unit id stored in other variable
	stay_near_xy = (flags4 & 0x20) == 0x20 # 0x20 position stored in other variables
	aggressive = (flags4 & 0x10) == 0x10 # 0x10 position stored in other variables
	defensive = (flags4 & 0x08) == 0x08 # 0x08 position stored in other variables
	
	target_unit_id = bytes.decode_u8(0x24)
	x25 = bytes.decode_u8(0x25)
	flags5 = bytes.decode_u8(0x26)
	conserve_ct = (flags5 & 0x04) == 0x04
	x27 = bytes.decode_u8(0x27)

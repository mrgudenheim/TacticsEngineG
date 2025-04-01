class_name JobData

# Job Data # 800610b8 in RAM
var job_id = 0
var job_name: String = ""
var skillset_id: int = 0
#var innate_abilities: PackedInt32Array = []
# equippable items
# hp growth
# hp multiplier
# mp growth
# mp multiplier
# speed growth
# speed multiplier
# pa growth
# pa multiplier
# ma growth
# ma multiplier
# move
# jump
# c-evade
# innate statuses
# status immunities
# starting statuses
# absorbed elements
# nullified elements
# halved elements
# element weaknesses
var monster_portrait_id: int = 0
var monster_palette_id: int = 0
var monster_type: int = 0 # monster type sprite? sprite_id = 0x85 + this
var sprite_id: int = 0

func _init(new_job_id: int, job_bytes: PackedByteArray) -> void:
	job_id = new_job_id
	if job_id < 155:
		job_name = RomReader.fft_text.job_names[job_id]
	skillset_id = job_bytes.decode_u8(0)
	monster_portrait_id = job_bytes.decode_u8(0x2d)
	monster_palette_id = job_bytes.decode_u8(0x2e)
	monster_type = job_bytes.decode_u8(0x2f)
	
	if job_id < 0x4a: # special units and monsters
		sprite_id = job_id
	elif job_id >= 0x4a and job_id < 0x5e: # generic humans
		sprite_id = 0x60 + ((job_id - 0x4a) * 2) # +1 for female sprite
	elif job_id >= 0x5e: # generic and special monsters
		sprite_id = monster_portrait_id
	

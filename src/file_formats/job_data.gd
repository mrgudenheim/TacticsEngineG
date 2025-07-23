class_name JobData
extends Resource

# Job Data # 800610b8 in RAM
@export var job_id = 0
@export var job_name: String = "Job Name"
@export var skillset_id: int = 0
@export var innate_abilities: PackedInt32Array = []
@export var equippable_item_types: Array[ItemData.ItemType] # 4 bytes of bitflags, 32 total
@export var hp_growth: int = 1
@export var mp_growth: int = 1
@export var speed_growth: int = 1
@export var pa_growth: int = 1
@export var ma_growth: int = 1

@export var hp_multiplier: int = 1
@export var mp_multiplier: int = 1
@export var speed_multiplier: int = 1
@export var pa_multiplier: int = 1
@export var ma_multiplier: int = 1

@export var move: int = 3
@export var jump: int = 3
@export var evade_physical: int = 0
@export var evade_datas: Array[EvadeData] = []

@export var status_always: PackedInt32Array = [] # 5 bytes of bitflags for up to 40 statuses
@export var status_immune: PackedInt32Array = [] # 5 bytes of bitflags for up to 40 statuses
@export var status_start: PackedInt32Array = [] # 5 bytes of bitflags for up to 40 statuses

@export var element_absorb: Array[Action.ElementTypes] = [] # 1 byte of bitflags, elemental types
@export var element_cancel: Array[Action.ElementTypes] = [] # 1 byte of bitflags, elemental types
@export var element_half: Array[Action.ElementTypes] = [] # 1 byte of bitflags, elemental types
@export var element_weakness: Array[Action.ElementTypes] = [] # 1 byte of bitflags, elemental types
@export var element_strengthen: Array[Action.ElementTypes] = [] # 1 byte of bitflags, elemental types

@export var passive_effect: PassiveEffect = PassiveEffect.new() # TODO job_data move element affinities, stat modifiers, and status arrays to passive_effect

@export var monster_portrait_id: int = 0
@export var monster_palette_id: int = 0
@export var monster_type: int = 0 # monster type sprite? sprite_id = 0x85 + this
@export var sprite_id: int = 0

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
	
	for innate_slot: int in 4:
		var innate_id: int = job_bytes.decode_u16(0x01 + (2 * innate_slot))
		if innate_id != 0:
			innate_abilities.append(innate_id) # TODO define non-action abilities
	
	# equippable item types
	var equipable_bytes: PackedByteArray = job_bytes.slice(0x09, 0x0d)
	for byte_idx: int in equipable_bytes.size():
		var equipable_byte: int = equipable_bytes.decode_u8(byte_idx)
		for bit_idx: int in 8:
			var reverse_idx: int = 7 - bit_idx
			if equipable_byte & (2 ** reverse_idx) == (2 ** reverse_idx):
				equippable_item_types.append((byte_idx * 8) + bit_idx)
	
	hp_growth = job_bytes.decode_u8(0x0d)
	mp_growth = job_bytes.decode_u8(0x0f)
	speed_growth = job_bytes.decode_u8(0x11)
	pa_growth = job_bytes.decode_u8(0x13)
	ma_growth = job_bytes.decode_u8(0x15)

	hp_multiplier = job_bytes.decode_u8(0x0e)
	mp_multiplier = job_bytes.decode_u8(0x10)
	speed_multiplier = job_bytes.decode_u8(0x12)
	pa_multiplier = job_bytes.decode_u8(0x14)
	ma_multiplier = job_bytes.decode_u8(0x16)
	
	move = job_bytes.decode_u8(0x17)
	jump = job_bytes.decode_u8(0x18)
	evade_physical = job_bytes.decode_u8(0x19)
	evade_datas.append(EvadeData.new(evade_physical, EvadeData.EvadeSource.JOB, EvadeData.EvadeType.PHYSICAL))
	
	status_always = StatusEffect.get_status_id_array(job_bytes.slice(0x1a, 0x1f))
	status_immune = StatusEffect.get_status_id_array(job_bytes.slice(0x1f, 0x24))
	status_start = StatusEffect.get_status_id_array(job_bytes.slice(0x24, 0x29))
	
	element_absorb = Action.get_element_types_array([job_bytes.decode_u8(0x29)])
	element_cancel = Action.get_element_types_array([job_bytes.decode_u8(0x2a)])
	element_half = Action.get_element_types_array([job_bytes.decode_u8(0x2b)])
	element_weakness = Action.get_element_types_array([job_bytes.decode_u8(0x2c)])
	#element_strengthen = Action.get_element_types_array([job_bytes.decode_u8(0x29)])
	

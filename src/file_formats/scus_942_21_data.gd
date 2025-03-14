class_name ScusData

# https://ffhacktics.com/wiki/SCUS_942.21_Data_Tables#MURATA_Main_Program_Data

# Job Data
class JobData:
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
	# portrait?
	# palette?
	# sprite?
	

class SkillsetData:
	var action_ability_ids: PackedInt32Array = []
	var rsm_ability_ids: PackedInt32Array = []


var jobs_start: int = 0x518b8 # 0x30 byte long entries
var jobs_data: Array[JobData] = []

var skillsets_start: int = 0x55294 # 0x55311 start of 05 Basic Skill, 0x19 bytes long
var skillsets_data: Array[SkillsetData] = []

# https://ffhacktics.com/wiki/Ability_Data
var ability_data_all_start: int = 0x4f3f0 # 0x200 entries, 0x08 bytes each
var jp_costs: PackedInt32Array = []
var chance_to_learn: PackedInt32Array = []
var ability_types: Array[AbilityData.AbilityType] = [] # AbilityData.AbilityType.NORMAL

var ability_data_normal_start: int = 0x503f0 # ids 0x000 - 0x16f, 0x170 entries, 0x0e bytes each
var ranges: PackedInt32Array = []
var effect_radius: PackedInt32Array = []
var vertical_tolerance: PackedInt32Array = []
var flags1: PackedInt32Array = []
var flags2: PackedInt32Array = []
var flags3: PackedInt32Array = []
var flags4: PackedInt32Array = []
var element_flags: PackedInt32Array = []
var formula_id: PackedInt32Array = []
var formula_x: PackedInt32Array = []
var formula_y: PackedInt32Array = []
var inflict_status_id: PackedInt32Array = []
var ct: PackedInt32Array = []
var mp_cost: PackedInt32Array = []

var ability_data_item_start: int = 0x503f0 # ids 0x170 - 0x17d, 0x0e entries, 0x01 bytes each
var ability_data_throw_start: int = 0x503f0 # ids 0x17e - 0x189, 0x0c entries, 0x01 bytes each
var ability_data_jump_start: int = 0x503f0 # ids 0x18a - 0x195, 0x0c entries, 0x02 bytes each
var ability_data_charge_start: int = 0x503f0 # ids 0x196 - 0x19d, 0x08 entries, 0x02 bytes each
var ability_data_math_start: int = 0x503f0 # ids 0x19e - 0x1a5, 0x08 entries, 0x02 bytes each
var ability_data_rsm_start: int = 0x503f0 # ids 0x1a6 - 0x1ff, 0x5a entries, 0x01 bytes each


# Item data
# https://ffhacktics.com/wiki/Item_Data
var item_data_base_start: int = 0x536b8 # 0xfd entries, 0x0c bytes each
var item_entries: int = 0xfe
var item_entry_length: int = 0x0c
var item_palettes: PackedInt32Array = []
var item_sprite_ids: PackedInt32Array = []
var item_min_levels: PackedInt32Array = []
var item_slot_types: PackedInt32Array = []
var item_types: PackedInt32Array = []
var item_attributes # TODO
var item_prices: PackedInt32Array = []
var item_shop_availability: PackedInt32Array = []


func init_from_scus() -> void:
	var scus_bytes: PackedByteArray = RomReader.get_file_data("SCUS_942.21")
	
	# job data
	var entry_size: int = 0x30 # bytes
	var num_entries: int = RomReader.NUM_JOBS
	var job_bytes: PackedByteArray = scus_bytes.slice(jobs_start, jobs_start + (num_entries * entry_size))
	jobs_data.resize(num_entries)
	for job_id: int in num_entries:
		var job_data: JobData = JobData.new()
		job_data.skillset_id = job_bytes.decode_u8(job_id * entry_size)
		jobs_data[job_id] = job_data
	
	
	skillsets_data.resize(RomReader.NUM_SKILLSETS)
	# unit skillset data
	entry_size = 0x19 # bytes
	num_entries = RomReader.NUM_UNIT_SKILLSETS
	var unit_skillsets_bytes: PackedByteArray = scus_bytes.slice(skillsets_start, skillsets_start + (num_entries * entry_size))
	for skillset_id: int in num_entries:
		var skillset_data: SkillsetData = SkillsetData.new()
		skillset_data.action_ability_ids.resize(16)
		skillset_data.rsm_ability_ids.resize(6)
		for skill_slot: int in 16: # action abilities
			var ability_id: int = unit_skillsets_bytes.decode_u8((skillset_id * entry_size) + 3 + skill_slot)
			var flag: int = 2**(7 - (skill_slot % 8)) # add 0x100 to ability ID if bit is 1 for each ability, 0x80 = Ability 1 (eg. Item ability, etc)
			if skill_slot < 8:
				ability_id += 0x100 if unit_skillsets_bytes.decode_u8((skillset_id * entry_size)) & flag != 0 else 0
			elif skill_slot < 16:
				ability_id += 0x100 if unit_skillsets_bytes.decode_u8((skillset_id * entry_size) + 1) & flag != 0 else 0
			
			skillset_data.action_ability_ids[skill_slot] = ability_id
			
		for skill_slot: int in 6: # rsm abilities
			var ability_id: int = unit_skillsets_bytes.decode_u8((skillset_id * entry_size) + 3 + 16 + skill_slot)
			var flag: int = 2**(7 - (skill_slot % 8)) # add 0x100 to ability ID if bit is 1 for each ability, 0x80 = RSM Ability 1 (rightmost 2 bits unused)
			ability_id += 0x100 if unit_skillsets_bytes.decode_u8((skillset_id * entry_size) + 2) & flag != 0 else 0
			skillset_data.rsm_ability_ids[skill_slot] = ability_id
		
		skillsets_data[skillset_id] = skillset_data
	
	# monster skillset data
	var monster_skillsets_start: int = skillsets_start + (RomReader.NUM_UNIT_SKILLSETS * entry_size)
	entry_size = 0x05 # bytes
	num_entries = RomReader.NUM_MONSTER_SKILLSETS
	var monster_skillsets_bytes: PackedByteArray = scus_bytes.slice(monster_skillsets_start, monster_skillsets_start + (num_entries * entry_size))
	for skillset_id: int in num_entries:
		var skillset_data: SkillsetData = SkillsetData.new()
		skillset_data.action_ability_ids.resize(4)
		for skill_slot: int in 4: # action abilities
			var ability_id: int = monster_skillsets_bytes.decode_u8((skillset_id * entry_size) + 1 + skill_slot)
			var flag: int = 2**(7 - (skill_slot % 8)) # add 0x100 to ability ID if bit is 1 for each ability, 0x80 = Ability 1 (eg. Item ability, etc)
			ability_id += 0x100 if monster_skillsets_bytes.decode_u8(skillset_id * entry_size) & flag != 0 else 0
			skillset_data.action_ability_ids[skill_slot] = ability_id
		
		skillsets_data[skillset_id + RomReader.NUM_UNIT_SKILLSETS] = skillset_data
	
	# ability data all
	jp_costs.resize(RomReader.NUM_ABILITIES)
	chance_to_learn.resize(RomReader.NUM_ABILITIES)
	ability_types.resize(RomReader.NUM_ABILITIES)
	
	entry_size = 0x08 # bytes
	num_entries = RomReader.NUM_ABILITIES
	var ability_data_bytes: PackedByteArray = scus_bytes.slice(ability_data_all_start, ability_data_all_start + (num_entries * entry_size))
	for id: int in num_entries:
		jp_costs[id] = ability_data_bytes.decode_u16(id * entry_size)
		chance_to_learn[id] = ability_data_bytes.decode_u8((id * entry_size) + 2)
		ability_types[id] = ability_data_bytes.decode_u8((id * entry_size) + 3) % 16
	
	# ability data normal
	ranges.resize(RomReader.NUM_ABILITIES)
	effect_radius.resize(RomReader.NUM_ABILITIES)
	vertical_tolerance.resize(RomReader.NUM_ABILITIES)
	flags1.resize(RomReader.NUM_ABILITIES)
	flags2.resize(RomReader.NUM_ABILITIES)
	flags3.resize(RomReader.NUM_ABILITIES)
	flags4.resize(RomReader.NUM_ABILITIES)
	element_flags.resize(RomReader.NUM_ABILITIES)
	formula_id.resize(RomReader.NUM_ABILITIES)
	formula_x.resize(RomReader.NUM_ABILITIES)
	formula_y.resize(RomReader.NUM_ABILITIES)
	inflict_status_id.resize(RomReader.NUM_ABILITIES)
	ct.resize(RomReader.NUM_ABILITIES)
	mp_cost.resize(RomReader.NUM_ABILITIES)
	
	entry_size = 0x0e # bytes
	num_entries = 0x170
	ability_data_bytes = scus_bytes.slice(ability_data_normal_start, ability_data_normal_start + (num_entries * entry_size))
	for id: int in num_entries:
		ranges[id] = ability_data_bytes.decode_u8(id * entry_size)
		effect_radius[id] = ability_data_bytes.decode_u8((id * entry_size) + 1)
		vertical_tolerance[id] = ability_data_bytes.decode_u8((id * entry_size) + 2)
		flags1[id] = ability_data_bytes.decode_u8((id * entry_size) + 3)
		flags2[id] = ability_data_bytes.decode_u8((id * entry_size) + 4)
		flags3[id] = ability_data_bytes.decode_u8((id * entry_size) + 5)
		flags4[id] = ability_data_bytes.decode_u8((id * entry_size) + 6)
		element_flags[id] = ability_data_bytes.decode_u8((id * entry_size) + 7)
		formula_id[id] = ability_data_bytes.decode_u8((id * entry_size) + 8)
		formula_x[id] = ability_data_bytes.decode_u8((id * entry_size) + 9)
		formula_y[id] = ability_data_bytes.decode_u8((id * entry_size) + 10)
		inflict_status_id[id] = ability_data_bytes.decode_u8((id * entry_size) + 11)
		ct[id] = ability_data_bytes.decode_u8((id * entry_size) + 12)
		mp_cost[id] = ability_data_bytes.decode_u8((id * entry_size) + 13)
	
	# item data base
	item_palettes.resize(item_entries)
	item_sprite_ids.resize(item_entries)
	item_min_levels.resize(item_entries)
	item_slot_types.resize(item_entries)
	item_types.resize(item_entries)
	# item_attributes # TODO
	item_prices.resize(item_entries)
	item_shop_availability.resize(item_entries)
	
	var item_data_bytes: PackedByteArray = scus_bytes.slice(item_data_base_start, item_data_base_start + (item_entries * item_entry_length))
	for id: int in item_entries:
		item_palettes[id] = item_data_bytes.decode_u8(id * item_entry_length)
		item_sprite_ids[id] = item_data_bytes.decode_u8((id * item_entry_length) + 1)
		item_min_levels[id] = item_data_bytes.decode_u8((id * item_entry_length) + 2)
		item_slot_types[id] = item_data_bytes.decode_u8((id * item_entry_length) + 3)
		item_types[id] = item_data_bytes.decode_u8((id * item_entry_length) + 5)
		item_prices[id] = item_data_bytes.decode_u16((id * item_entry_length) + 8)
		item_shop_availability[id] = item_data_bytes.decode_u8((id * item_entry_length) + 10)

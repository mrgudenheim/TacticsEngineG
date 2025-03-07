class_name ScusData

# https://ffhacktics.com/wiki/SCUS_942.21_Data_Tables#MURATA_Main_Program_Data

class JobData:
	var skillset_id: int = 0
	#var innate_abilities:

class SkillsetData:
	var action_ability_ids: PackedInt32Array = []
	var rsm_ability_ids: PackedInt32Array = []


var jobs_start: int = 0x518b8 # 0x30 byte long entries
var jobs_data: Array[JobData] = []

var skillsets_start: int = 0x55294 # 0x55311 start of 05 Basic Skill, 0x19 bytes long
var skillsets_data: Array[SkillsetData] = []


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

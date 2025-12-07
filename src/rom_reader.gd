#class_name RomReader
extends Node

signal rom_loaded

var is_ready: bool = false

var rom: PackedByteArray = []
var file_records: Dictionary[String, FileRecord] = {} # {file_name, FileRecord}
var lba_to_file_name: Dictionary[int, String] = {} # {int, String}

const DIRECTORY_DATA_SECTORS_ROOT: PackedInt32Array = [22]
const OFFSET_RECORD_DATA_START: int = 0x60

# https://en.wikipedia.org/wiki/CD-ROM#CD-ROM_XA_extension
const BYTES_PER_SECTOR: int = 2352
const BYTES_PER_SECTOR_HEADER: int = 24
const BYTES_PER_SECTOR_FOOTER: int = 280
const DATA_BYTES_PER_SECTOR: int = 2048

const NUM_ABILITIES = 512
const NUM_ACTIVE_ABILITIES = 0x1C6
const NUM_SPRITESHEETS = 0x9f
const NUM_SKILLSETS = 0xe0
const NUM_UNIT_SKILLSETS = 0xb0
const NUM_MONSTER_SKILLSETS = 0xe0 - 0xb0
const NUM_JOBS = 0xa0
const NUM_VFX = 511
const NUM_ITEMS = 254 # 256?
const NUM_WEAPONS = 122

var sprs: Array[Spr] = []
var spr_file_name_to_id: Dictionary[String, int] = {}
var spr_id_file_idxs: PackedInt32Array = [] # 0x60 starts generic jobs

var shps: Array[Shp] = []
var seqs: Array[Seq] = []
var maps: Array[MapData] = []
var vfx: Array[VisualEffectData] = []
var fft_abilities: Array[FftAbilityData] = []
var items_array: Array[ItemData] = []
# var status_effects: Array[StatusEffect] = [] # TODO reference scus_data.status_effects
var items: Dictionary[String, ItemData] = {} # [unique_name, ItemData]
var status_effects: Dictionary[String, StatusEffect] = {} # [unique_name, StatusEffect]
var jobs_data: Dictionary[String, JobData] = {} # [unique_name, JobData]
var actions: Dictionary[String, Action] = {} # [unique_name, Action]
var triggered_actions: Dictionary[String, TriggeredAction] = {} # [unique_name, TriggeredAction]
var passive_effects: Dictionary[String, PassiveEffect] = {} # [unique_name, TriggeredAction]
var abilities: Dictionary[String, Ability] = {} # [unique_name, Ability]

# BATTLE.BIN tables
var battle_bin_data: BattleBinData = BattleBinData.new()

# SCUS.942.41 tables
var scus_data: ScusData = ScusData.new()

# Images
# https://github.com/Glain/FFTPatcher/blob/master/ShishiSpriteEditor/PSXImages.xml#L148
var frame_bin: Bmp = Bmp.new()
var frame_bin_texture: Texture2D

# Text
var fft_text: FftText = FftText.new()

class SpritesheetRegionData:
	var shp_type: String
	var region_id: int
	var region_location: Vector2i
	var region_size: Vector2i
	var shp_frame_ids: PackedInt32Array = []
	var shp_frame_id_labels: PackedStringArray = []
	var animation_ids: PackedInt32Array = []
	var animation_descriptions: PackedStringArray = []

#func _init() -> void:
	#pass


func on_load_rom_dialog_file_selected(path: String) -> void:
	var start_time: int = Time.get_ticks_msec()
	rom = FileAccess.get_file_as_bytes(path)
	push_warning("Time to load file (ms): " + str(Time.get_ticks_msec() - start_time))
	
	process_rom()


func clear_data() -> void:
	file_records.clear()
	lba_to_file_name.clear()
	sprs.clear()
	spr_file_name_to_id.clear()
	shps.clear()
	seqs.clear()
	maps.clear()
	vfx.clear()
	fft_abilities.clear()
	items_array.clear()
	status_effects.clear()
	jobs_data.clear()


func process_rom() -> void:
	clear_data()
	
	var start_time: int = Time.get_ticks_msec()
	
	RomReader.spr_id_file_idxs.resize(NUM_SPRITESHEETS)
	
	# http://wiki.osdev.org/ISO_9660#Directories
	process_file_records(DIRECTORY_DATA_SECTORS_ROOT)
	
	push_warning("Time to process ROM (ms): " + str(Time.get_ticks_msec() - start_time))
	
	process_frame_bin()
	
	fft_text.init_text()
	scus_data.init_from_scus()
	battle_bin_data.init_from_battle_bin()
	
	cache_associated_files()
	
	for ability_id: int in NUM_ABILITIES:
		var new_fft_ability: FftAbilityData = FftAbilityData.new(ability_id)
		fft_abilities.append(new_fft_ability)
		var new_ability: Ability = new_fft_ability.create_ability()
		new_ability.add_to_global_list()
	
	for fft_ability: FftAbilityData in fft_abilities:
		if fft_ability.ability_type == FftAbilityData.AbilityType.NORMAL:
			fft_ability.set_action()

	# must be after fft_abilities to set secondary actions
	items_array.resize(NUM_ITEMS)
	for id: int in NUM_ITEMS:
		items_array[id] = (ItemData.new(id))
	
	scus_data.init_statuses()
	# for status_: int in status_effects.size():
		# status_effects[idx].ai_score_formula.values[0] = battle_bin_data.ai_status_priorities[idx] / 128.0
		# TODO implement ai formulas that are modified by other statuses (ex. stop is worth zero if target is already confused/charm/blood suck) or action properties (ex. evadeable, silenceable)
	
	
	# testing vfx vram data
	#for ability_id: int in NUM_ACTIVE_ABILITIES:
		#if not fft_abilities[ability_id].vfx_data.is_initialized:
			#fft_abilities[ability_id].vfx_data.init_from_file()
		#var ability: FftAbilityData = fft_abilities[ability_id]
		#for frameset_idx: int in ability.vfx_data.frame_sets.size():
			#for frame_idx: int in ability.vfx_data.frame_sets[frameset_idx].frame_set.size():
				#var frame_data: VisualEffectData.VfxFrame = ability.vfx_data.frame_sets[frameset_idx].frame_set[frame_idx]
				#if ((frame_data.vram_bytes[1] & 0x02) >> 1) == 0:
					#push_warning([ability_id, ability.name, ability.vfx_data.vfx_id, frameset_idx, frame_idx])
	
	# for seq: Seq in seqs:
	# 	seq.set_data_from_seq_bytes(get_file_data(seq.file_name))
	# 	seq.write_wiki_table()
	
	# write_all_spritesheet_region_data()

	# var json_file = FileAccess.open("user://overrides/action2_to_json.json", FileAccess.WRITE)
	# json_file.store_line(fft_abilities[2].ability_action.to_json())
	# json_file.close()
	
	import_custom_data()
	connect_data_references()

	# var vfx_scripts: Dictionary[String, PackedStringArray] = {}
	# for vfx_file in vfx:
	# 	if file_records[vfx_file.file_name].size == 0:
	# 		continue

	# 	if not vfx_file.is_initialized:
	# 		vfx_file.init_from_file()

	# 	var script_bytes: String = vfx_file.script_bytes.hex_encode()
	# 	if not vfx_scripts.has(script_bytes):
	# 		var files_list: PackedStringArray = []
	# 		vfx_scripts[script_bytes] = files_list
		
	# 	vfx_scripts[script_bytes].append(vfx_file.file_name + " " + vfx_file.ability_names)

		#if vfx_file.child_emitter_timelines.any(func(timeline: VisualEffectData.EmitterTimeline): return timeline.has_unknown_flags):
			#push_warning(vfx_file.file_name + "child flags")
		#if vfx_file.phase1_emitter_timelines.any(func(timeline: VisualEffectData.EmitterTimeline): return timeline.has_unknown_flags):
			#push_warning(vfx_file.file_name + "phase1 flags")
		#if vfx_file.phase2_emitter_timelines.any(func(timeline: VisualEffectData.EmitterTimeline): return timeline.has_unknown_flags):
			#push_warning(vfx_file.file_name + "phase2 flags")


	#var output_array: PackedStringArray = []
	#for key: String in vfx_scripts.keys():
		#output_array.append(key + ": " + ", ".join(vfx_scripts[key]))
#
	#var final_output: String = "\n".join(output_array)
	
	#DirAccess.make_dir_recursive_absolute("user://wiki_tables")
	#var file_name: String = "vfx_scripts"
	#var save_file := FileAccess.open("user://wiki_tables/" + file_name + ".txt", FileAccess.WRITE)
	#save_file.store_string(final_output)

	#for action: Action in actions.values():
		#Utilities.save_json(action)
#
	#for ability: Ability in abilities.values():
		#Utilities.save_json(ability)

	# var new_action: Action = Action.new()
	
	# new_action.display_name = "Defend"
	# new_action.unique_name = "defend"
	# new_action.status_chance = 100
	# new_action.target_status_list = ["defending"]
	# new_action.target_status_list_type = Action.StatusListType.ALL
	# new_action.targeting_type = Action.TargetingTypes.RANGE
	# new_action.auto_target = true
	# new_action.max_targeting_range = 0
	# new_action.status_prevents_use_any = [
	# 	"crystal",
	# 	"dead",
	# 	"petrify",
	# 	"blood_suck",
	# 	"treasure",
	# 	"berserk",
	# 	"chicken",
	# 	"frog",
	# 	"stop",
	# 	"don't_act",
	# ]
	# new_action.ignore_passives = [
	# 	"protect_status",
	# 	"shell_status",
	# 	"attack_up",
	# 	"defense_up",
	# 	"magic_attack_up",
	# 	"magic_defense_up",
	# 	"martial_arts",
	# 	"throw_item",
	# 	"monster_talk",
	# 	"maintenance",
	# 	"finger_guard",
	# ]
	# Utilities.save_json(new_action)

	# var new_passive_effect: PassiveEffect 

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "attack_up"
	# new_passive_effect.power_modifier_user = Modifier.new(1.33, Modifier.ModifierType.MULT)
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "magic_attack_up"
	# new_passive_effect.power_modifier_user = Modifier.new(1.33, Modifier.ModifierType.MULT)
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "martial_arts"
	# new_passive_effect.power_modifier_user = Modifier.new(1.5, Modifier.ModifierType.MULT)
	# new_passive_effect.requires_user_item_type = ["FIST"]
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "defense_up"
	# new_passive_effect.power_modifier_targeted = Modifier.new(0.66, Modifier.ModifierType.MULT)
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "magic_defense_up"
	# new_passive_effect.power_modifier_targeted = Modifier.new(0.66, Modifier.ModifierType.MULT)
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "concentrate"
	# var evade_modifier_dict: Dictionary[EvadeData.EvadeSource, Modifier] = {
	# 	EvadeData.EvadeSource.JOB : Modifier.new(0, Modifier.ModifierType.SET),
	# 	EvadeData.EvadeSource.SHIELD : Modifier.new(0, Modifier.ModifierType.SET),
	# 	EvadeData.EvadeSource.ACCESSORY : Modifier.new(0, Modifier.ModifierType.SET),
	# 	EvadeData.EvadeSource.WEAPON : Modifier.new(0, Modifier.ModifierType.SET),
	# }
	# new_passive_effect.evade_source_modifiers_user = evade_modifier_dict
	# Utilities.save_json(new_passive_effect)
	
	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "monster_talk"
	# new_passive_effect.add_applicable_target_stat_bases = [UnitData.StatBasis.MONSTER]
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "maintenance"
	# new_passive_effect.hit_chance_modifier_targeted = Modifier.new(0, Modifier.ModifierType.SET)
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "defend"
	# new_passive_effect.added_actions_names = ["defend"]
	# # TODO create defend action
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "half_of_mp"
	# new_passive_effect.action_mp_modifier = Modifier.new(0.5, Modifier.ModifierType.MULT)
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "throw_item"
	# new_passive_effect.action_max_range_modifier = Modifier.new(3, Modifier.ModifierType.ADD)
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "short_charge"
	# new_passive_effect.action_charge_time_modifier = Modifier.new(0.5, Modifier.ModifierType.MULT)
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "non_charge"
	# new_passive_effect.action_charge_time_modifier = Modifier.new(0.0, Modifier.ModifierType.SET)
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "equip_change"
	# new_passive_effect.added_actions_names = ["equip_change"]
	# # TODO create equip_change action
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "monster_skill"
	# new_passive_effect.effect_range = 3
	# new_passive_effect.unit_basis_filter = [UnitData.StatBasis.MONSTER]
	# new_passive_effect.added_actions_names = ["choco_ball"] # TODO change to 'learned' flag for each job's unique action?
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "move+1"
	# var stat_modifier_dict: Dictionary[UnitData.StatType, Modifier] = {
	# 	UnitData.StatType.MOVE : Modifier.new(1, Modifier.ModifierType.ADD),
	# }
	# new_passive_effect.stat_modifiers = stat_modifier_dict
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "move+2"
	# stat_modifier_dict = {
	# 	UnitData.StatType.MOVE : Modifier.new(2, Modifier.ModifierType.ADD),
	# }
	# new_passive_effect.stat_modifiers = stat_modifier_dict
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "move+3"
	# stat_modifier_dict = {
	# 	UnitData.StatType.MOVE : Modifier.new(3, Modifier.ModifierType.ADD),
	# }
	# new_passive_effect.stat_modifiers = stat_modifier_dict
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "jump+1"
	# stat_modifier_dict = {
	# 	UnitData.StatType.JUMP : Modifier.new(1, Modifier.ModifierType.ADD),
	# }
	# new_passive_effect.stat_modifiers = stat_modifier_dict
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "jump+2"
	# stat_modifier_dict = {
	# 	UnitData.StatType.JUMP : Modifier.new(2, Modifier.ModifierType.ADD),
	# }
	# new_passive_effect.stat_modifiers = stat_modifier_dict
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "jump+3"
	# stat_modifier_dict = {
	# 	UnitData.StatType.JUMP : Modifier.new(3, Modifier.ModifierType.ADD),
	# }
	# new_passive_effect.stat_modifiers = stat_modifier_dict
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "ignore_height"
	# new_passive_effect.ignore_height = true
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "ignore_terrain"
	# var terrain_modifier_dict: Dictionary[int, Modifier] = {
	# 	0x0e : Modifier.new(1, Modifier.ModifierType.SET),
	# 	0x0f: Modifier.new(1, Modifier.ModifierType.SET),
	# 	0x10 : Modifier.new(1, Modifier.ModifierType.SET),
	# 	0x11 : Modifier.new(1, Modifier.ModifierType.SET),
	# 	0x2d : Modifier.new(1, Modifier.ModifierType.SET),
	# }
	# new_passive_effect.terrain_cost_modifiers = terrain_modifier_dict
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "walk_on_water"
	# # TODO handle depth
	# new_passive_effect.terrain_cost_modifiers = terrain_modifier_dict
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "swim"
	# # TODO handle depth
	# new_passive_effect.terrain_cost_modifiers = terrain_modifier_dict
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "move_underwater"
	# # TODO handle depth
	# new_passive_effect.terrain_cost_modifiers = terrain_modifier_dict
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "walk_on_lava"
	# new_passive_effect.remove_prohibited_terrain = [0x12]
	# Utilities.save_json(new_passive_effect)

	# # new_passive_effect = PassiveEffect.new()
	# # new_passive_effect.unique_name = "ignore_weather"
	# # Utilities.save_json(new_passive_effect)

	# # new_passive_effect = PassiveEffect.new()
	# # new_passive_effect.unique_name = "cant_enter_depth"
	# # Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "float"
	# new_passive_effect.status_always = ["float"]
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "fly"
	# new_passive_effect.added_actions_names = ["fly"]
	# # TODO create fly action
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "teleport"
	# new_passive_effect.added_actions_names = ["teleport"]
	# # TODO create teleport action
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "teleport_2"
	# new_passive_effect.added_actions_names = ["teleport_2"]
	# # TODO create teleport_2 action
	# Utilities.save_json(new_passive_effect)

	# new_passive_effect = PassiveEffect.new()
	# new_passive_effect.unique_name = "reflect"
	# new_passive_effect.status_always = ["reflect"]
	# Utilities.save_json(new_passive_effect)

	is_ready = true
	rom_loaded.emit()


func process_file_records(sectors: PackedInt32Array, folder_name: String = "") -> void:
	for sector: int in sectors:
		
		var offset_start: int = 0
		if sector == sectors[0]:
			offset_start = OFFSET_RECORD_DATA_START
		var directory_start: int = sector * BYTES_PER_SECTOR
		var directory_data: PackedByteArray = rom.slice(directory_start + BYTES_PER_SECTOR_HEADER, directory_start + DATA_BYTES_PER_SECTOR + BYTES_PER_SECTOR_HEADER)
		
		var byte_index: int = offset_start
		while byte_index < DATA_BYTES_PER_SECTOR:
			var record_length: int = directory_data.decode_u8(byte_index)
			var record_data: PackedByteArray = directory_data.slice(byte_index, byte_index + record_length)
			var record: FileRecord = FileRecord.new(record_data)
			record.record_location_sector = sector
			record.record_location_offset = byte_index
			file_records[record.name] = record
			lba_to_file_name[record.sector_location] = record.name
			
			var file_extension: String = record.name.get_extension()
			if record.flags & 0b10 == 0b10: # folder
				#push_warning("Getting files from folder: " + record.name)
				var data_length_sectors: int = ceil(float(record.size) / DATA_BYTES_PER_SECTOR)
				var directory_sectors: PackedInt32Array = range(record.sector_location, record.sector_location + data_length_sectors)
				process_file_records(directory_sectors, record.name)
			elif folder_name == "EFFECT":
				record.type_index = vfx.size()
				vfx.append(VisualEffectData.new(record.name))
			elif file_extension == "SPR":
				record.type_index = sprs.size()
				sprs.append(Spr.new(record.name))
			elif file_extension == "SHP":
				record.type_index = shps.size()
				shps.append(Shp.new(record.name))
			elif file_extension == "SEQ":
				record.type_index = seqs.size()
				seqs.append(Seq.new(record.name))
			elif file_extension == "GNS":
				record.type_index = maps.size()
				maps.append(MapData.new(record.name))
			
			byte_index += record_length
			if byte_index < DATA_BYTES_PER_SECTOR:
				if directory_data.decode_u8(byte_index) == 0: # end of data, rest of sector will be padded with zeros
					break


func cache_associated_files() -> void:
	var associated_file_names: PackedStringArray = [
		"WEP1.SEQ",
		"WEP2.SEQ",
		"EFF1.SEQ",
		"WEP1.SHP",
		"WEP2.SHP",
		"EFF1.SHP",
		"WEP.SPR",
		]
	
	for file_name: String in associated_file_names:
		var type_index: int = file_records[file_name].type_index
		match file_name.get_extension():
			"SPR":
				var spr: Spr = sprs[type_index]
				spr.set_data(get_file_data(file_name))
				if file_name != "WEP.SPR":
					spr.set_spritesheet_data(spr_file_name_to_id[file_name])
			"SHP":
				var shp: Shp = shps[type_index]
				shp.set_data_from_shp_bytes(get_file_data(file_name))
			"SEQ":
				var seq: Seq = seqs[type_index]
				seq.set_data_from_seq_bytes(get_file_data(file_name))
	
	# getting effect / weapon trail / glint
	var eff_spr_name: String = "EFF.SPR"
	var eff_spr: Spr = Spr.new(eff_spr_name)
	eff_spr.height = 144
	var eff_spr_record: FileRecord = FileRecord.new()
	eff_spr_record.name = eff_spr_name
	eff_spr_record.type_index = sprs.size()
	file_records[eff_spr_name] = eff_spr_record
	eff_spr.set_data(get_file_data("WEP.SPR").slice(0x8200, 0x10400))
	eff_spr.shp_name = "EFF1.SHP"
	eff_spr.seq_name = "EFF1.SEQ"
	sprs.append(eff_spr)
	
	# TODO get trap effects - not useful for this tool at this time
	
	# crop wep spr
	var wep_spr_start: int = 0
	var wep_spr_end: int = 256 * 256 # wep is 256 pixels tall
	var wep_spr_index: int = file_records["WEP.SPR"].type_index
	var wep_spr: Spr = sprs[wep_spr_index].get_sub_spr("WEP.SPR", wep_spr_start, wep_spr_end)
	wep_spr.shp_name = "WEP1.SHP"
	wep_spr.seq_name = "WEP1.SEQ"
	sprs[wep_spr_index] = wep_spr
	
	# get item graphics
	var item_record: FileRecord = FileRecord.new()
	item_record.sector_location = 6297 # ITEM.BIN is in EVENT not BATTLE, so needs a new record created
	item_record.size = 33280
	item_record.name = "ITEM.BIN"
	item_record.type_index = sprs.size()
	file_records[item_record.name] = item_record
	
	var item_spr_data: PackedByteArray = RomReader.get_file_data(item_record.name)
	var item_spr: Spr = Spr.new(item_record.name)
	item_spr.height = 256
	item_spr.set_palette_data(item_spr_data.slice(0x8000, 0x8200))
	item_spr.color_indices = item_spr.set_color_indices(item_spr_data.slice(0, 0x8000))
	item_spr.set_pixel_colors()
	item_spr.spritesheet = item_spr.get_rgba8_image()
	sprs.append(item_spr)


func get_file_data(file_name: String) -> PackedByteArray:
	var file_data: PackedByteArray = []
	var sector_location: int = file_records[file_name].sector_location
	var file_size: int = file_records[file_name].size
	var file_data_start: int = (sector_location * BYTES_PER_SECTOR) + BYTES_PER_SECTOR_HEADER
	var num_sectors_full: int = floor(file_size / float(DATA_BYTES_PER_SECTOR))
	
	for sector_index: int in num_sectors_full:
		var sector_data_start: int = file_data_start + (sector_index * BYTES_PER_SECTOR)
		var sector_data_end: int = sector_data_start + DATA_BYTES_PER_SECTOR
		var sector_data: PackedByteArray = rom.slice(sector_data_start, sector_data_end)
		file_data.append_array(sector_data)
	
	# add data from last sector
	var last_sector_data_start: int = file_data_start + (num_sectors_full * BYTES_PER_SECTOR)
	var last_sector_data_end: int = last_sector_data_start + (file_size % DATA_BYTES_PER_SECTOR)
	var last_sector_data: PackedByteArray = rom.slice(last_sector_data_start, last_sector_data_end)
	file_data.append_array(last_sector_data)
	
	return file_data


func get_spr_file_idx(sprite_id: int) -> int:
	return sprs.find_custom(func(spr: Spr): return spr.sprite_id == sprite_id)


func init_abilities() -> void:
	for ability_id: int in NUM_ABILITIES:
		fft_abilities[ability_id] = FftAbilityData.new(ability_id)


func process_frame_bin() -> void:
	var file_name: String = "FRAME.BIN"
	frame_bin.file_name = file_name
	var frame_bin_bytes: PackedByteArray = get_file_data(file_name)
	
	frame_bin.num_colors = 22 * 16
	frame_bin.bits_per_pixel = 4
	frame_bin.palette_data_start = frame_bin_bytes.size() - (frame_bin.num_colors * 2) # 2 bytes per color - 1 bit for alpha, followed by 5 bits per channel (B,G,R)
	frame_bin.pixel_data_start = 0
	frame_bin.width = 256 # pixels
	frame_bin.height = 288
	frame_bin.num_pixels = frame_bin.width * frame_bin.height
	
	var palette_bytes: PackedByteArray = frame_bin_bytes.slice(frame_bin.palette_data_start)
	var pixel_bytes: PackedByteArray = frame_bin_bytes.slice(frame_bin.pixel_data_start, frame_bin.palette_data_start)
	
	# set palette data
	frame_bin.color_palette.resize(frame_bin.num_colors)
	for i: int in frame_bin.num_colors:
		var color: Color = Color.BLACK
		var color_bits: int = palette_bytes.decode_u16(i*2)
		var alpha_bit: int = (color_bits & 0b1000_0000_0000_0000) >> 15 # first bit is alpha
		#color.a8 = 1 - () # first bit is alpha (if bit is zero, color is opaque)
		color.b8 = (color_bits & 0b0111_1100_0000_0000) >> 10 # then 5 bits each: blue, green, red
		color.g8 = (color_bits & 0b0000_0011_1110_0000) >> 5
		color.r8 = color_bits & 0b0000_0000_0001_1111
		
		# convert 5 bit channels to 8 bit
		#color.a8 = 255 * color.a8 # first bit is alpha (if bit is zero, color is opaque)
		color.a8 = 255 # TODO use alpha correctly
		color.b8 = roundi(255 * (color.b8 / float(31))) # then 5 bits each: blue, green, red
		color.g8 = roundi(255 * (color.g8 / float(31)))
		color.r8 = roundi(255 * (color.r8 / float(31)))
		
		# psx transparency: https://www.psxdev.net/forum/viewtopic.php?t=953
		# TODO use Material3D blend mode Add for mode 1 or 3, where brightness builds up from a dark background instead of normal "mix" transparency
		if color == Color.BLACK:
			color.a8 = 0
		
		# if first color in 16 color palette is black, treat it as transparent
		if (i % 16 == 0
			and color == Color.BLACK):
				color.a8 = 0
		frame_bin.color_palette[i] = color
	
	# set color indicies
	var new_color_indicies: Array[int] = []
	new_color_indicies.resize(pixel_bytes.size() * (8 / frame_bin.bits_per_pixel))
	
	for i: int in new_color_indicies.size():
		var pixel_offset: int = (i * frame_bin.bits_per_pixel)/8
		var byte: int = pixel_bytes.decode_u8(pixel_offset)
		
		if frame_bin.bits_per_pixel == 4:
			if i % 2 == 1: # get 4 leftmost bits
				new_color_indicies[i] = byte >> 4
			else:
				new_color_indicies[i] = byte & 0b0000_1111 # get 4 rightmost bits
		elif frame_bin.bits_per_pixel == 8:
			new_color_indicies[i] = byte
	
	frame_bin.color_indices = new_color_indicies
	
	# set_pixel_colors()
	var palette_id: int = 5
	var new_pixel_colors: PackedColorArray = []
	var new_size: int = frame_bin.color_indices.size()
	var err: int = new_pixel_colors.resize(new_size)
	#pixel_colors.resize(color_indices.size())
	new_pixel_colors.fill(Color.BLACK)
	for i: int in frame_bin.color_indices.size():
		new_pixel_colors[i] = frame_bin.color_palette[frame_bin.color_indices[i] + (16 * palette_id)]
	
	frame_bin.pixel_colors = new_pixel_colors
	
	# get_rgba8_image() -> Image:
	frame_bin.height = frame_bin.color_indices.size() / frame_bin.width
	var image:Image = Image.create_empty(frame_bin.width, frame_bin.height, false, Image.FORMAT_RGBA8)
	for x in frame_bin.width:
		for y in frame_bin.height:
			var color: Color = frame_bin.pixel_colors[x + (y * frame_bin.width)]
			var color8: Color = Color8(color.r8, color.g8, color.b8, color.a8) # use Color8 function to prevent issues with format conversion changing color by 1/255
			image.set_pixel(x,y, color8) # spr stores pixel data left to right, top to bottm
	
	frame_bin_texture = ImageTexture.create_from_image(image)


func import_custom_data() -> void:
	# order of loading matters. Triggered Actions, PassiveEffect reference actions. Abilities, StatusEffect reference PassiveEffect. Items reference a lot.
	# TODO break into 2 steps: 1) load all json for all types, 2) connect cross references
	var folder_names: PackedStringArray = [
		"actions",
		"passive_effects",
		"triggered_actions",
		"status_effects",
		"items",
		"abilities",
	]

	for content_folder: String in folder_names:
		var dir_path: String = "res://src/_content/" + content_folder + "/"
		var dir := DirAccess.open(dir_path)

		if dir:
			dir.list_dir_begin()
			var file_name: String = dir.get_next()
			while file_name != "":
				if not file_name.begins_with("."): # Exclude hidden files
					#push_warning("Found file: " + file_name)
					if file_name.ends_with(".json"):
						var file_path: String = dir_path + file_name
						var file := FileAccess.open(file_path, FileAccess.READ)
						var file_text = file.get_as_text()

						var data_type: String = file_name.split(".")[-2]

						match data_type:
							"action":
								var new_content: Action = Action.create_from_json(file_text)
								if not actions.keys().has(new_content.unique_name):
									new_content.add_to_global_list()
							"ability":
								var new_content: Ability = Ability.create_from_json(file_text)
								if not abilities.keys().has(new_content.unique_name):
									new_content.add_to_global_list()
							"triggered_action":
								var new_content: TriggeredAction = TriggeredAction.create_from_json(file_text)
								if not triggered_actions.keys().has(new_content.unique_name):
									new_content.add_to_global_list()
							"passive_effect":
								var new_content: PassiveEffect = PassiveEffect.create_from_json(file_text)
								if not passive_effects.keys().has(new_content.unique_name):
									new_content.add_to_global_list()
							"status_effect":
								var new_content: StatusEffect = StatusEffect.create_from_json(file_text)
								if not status_effects.keys().has(new_content.unique_name):
									new_content.add_to_global_list()
							"item":
								var new_content: ItemData = ItemData.create_from_json(file_text)
								if not items.keys().has(new_content.unique_name):
									new_content.add_to_global_list()
				file_name = dir.get_next()
			dir.list_dir_end()
		else:
			push_warning("Could not open directory: " + dir_path)


func connect_data_references() -> void:
	# actions have no direct references, stores StatusEffect names in several places
	# for action: Action in actions:
		
	for triggered_action: TriggeredAction in triggered_actions.values():
		if actions.has(triggered_action.action_unique_name):
			triggered_action.action = actions[triggered_action.action_unique_name]

	for status_effect: StatusEffect in status_effects.values():
		if passive_effects.has(status_effect.passive_effect_name):
			status_effect.passive_effect = passive_effects[status_effect.passive_effect_name]
	
	for job_data: JobData in jobs_data.values():
		for passive_effect_name_idx: int in job_data.passive_effect_names.size():
			var passive_effect_name: String = job_data.passive_effect_names[passive_effect_name_idx]
			if passive_effect_name == "" and passive_effects.has(job_data.unique_name):
				passive_effect_name = job_data.unique_name
				job_data.passive_effect_names[passive_effect_name_idx] = passive_effect_name
				job_data.passive_effects.append(passive_effects[passive_effect_name])
			elif passive_effects.has(passive_effect_name):
				job_data.passive_effects.append(passive_effects[passive_effect_name])
			
		
		for innate_ability_id: int in job_data.innate_abilities_ids:
			# var ability_uname: String = fft_abilities[innate_ability_id].display_name.to_snake_case()
			var ability_uname: String = abilities.values()[innate_ability_id].unique_name
			if not job_data.innate_ability_names.has(ability_uname):
				job_data.innate_ability_names.append(ability_uname)

		for ability_name: String in job_data.innate_ability_names:
			if abilities.has(ability_name):
				job_data.innate_abilities.append(abilities[ability_name])

	for ability: Ability in abilities.values():
		if ability.passive_effect_name == "" and passive_effects.has(ability.unique_name):
			ability.passive_effect_name = ability.unique_name
			ability.passive_effect = passive_effects[ability.passive_effect_name]
		elif passive_effects.has(ability.passive_effect_name):
			ability.passive_effect = passive_effects[ability.passive_effect_name]
		
		
		for triggered_action_name: String in ability.triggered_actions_names:
			if triggered_actions.has(triggered_action_name):
				ability.triggered_actions.append(triggered_actions[triggered_action_name])
		
		if ability.triggered_actions_names.is_empty():
			if triggered_actions.has(ability.unique_name):
				ability.triggered_actions_names = [ability.unique_name]
				ability.triggered_actions.append(triggered_actions[ability.unique_name])

	for passive_effect: PassiveEffect in passive_effects.values():
		for action_name: String in passive_effect.added_actions_names:
			if actions.has(action_name):
				passive_effect.added_actions.append(actions[action_name])
		for triggered_action_name: String in passive_effect.added_triggered_actions_names:
			if triggered_actions.has(triggered_action_name):
				passive_effect.added_triggered_actions.append(triggered_actions[triggered_action_name])

	for item: ItemData in items.values():
		if passive_effects.has(item.passive_effect_name):
			item.passive_effect = passive_effects[item.passive_effect_name]
		if actions.has(item.weapon_attack_action_name):
			item.weapon_attack_action = actions[item.weapon_attack_action_name]


func write_all_spritesheet_region_data() -> void:
	# SEQs: 0 - arute, 1 - cyoko, 4 - kanzen, 5 - mon, 8 - type1, 10 - type3
	# SHPs: 0 - arute, 1 - cyoko, 4 - kanzen, 5 - mon, 7 - type1, 8 - type2
	var seq_indicies: PackedInt32Array = [
		0,
		1,
		4,
		5,
		8,
		10,
	]
	var shp_indicies: PackedInt32Array = [
		0,
		1,
		4,
		5,
		7,
		8,
	]

	for idx: int in seq_indicies.size():
		write_spritesheet_region_data(seq_indicies[idx], shp_indicies[idx])


func write_spritesheet_region_data(seq_index: int, shp_index: int) -> void:
	var regions: Array[SpritesheetRegionData] = []
	
	var seq: Seq = seqs[seq_index] # 0 - arute, 1 - cyoko, 4 - kanzen, 5 - mon, 8 - type1, 10 - type3
	var shp: Shp = shps[shp_index] # 0 - arute, 1 - cyoko, 4 - kanzen, 5 - mon, 7 - type1, 8 - type2

	if not seq.is_initialized:
		seq.set_data_from_seq_bytes(RomReader.get_file_data(seq.file_name))

	if not shp.is_initialized:
		shp.set_data_from_shp_bytes(RomReader.get_file_data(shp.file_name))
	
	for seq_ptr_index: int in seq.sequence_pointers.size():
		var seq_idx: int = seq.sequence_pointers[seq_ptr_index]
		var animation: Sequence = seq.sequences[seq_idx]
		var seq_description: String = animation.seq_name
		if seq_description == "":
			seq_description = "?"
		
		for part: SeqPart in animation.seq_parts:
			if part.opcode == "LoadFrameAndWait":
				var shp_frame_id: int = part.parameters[0]
				var frame: FrameData = shp.frames[shp_frame_id]
				
				for subframe_idx: int in frame.subframes.size():
					var subframe: SubFrameData = frame.subframes[subframe_idx]
					var subframe_region_size = subframe.rect_size
					var subframe_region_location = Vector2i(subframe.load_location_x, subframe.load_location_y)

					var region_id: int = regions.find_custom(func(region_data: SpritesheetRegionData): 
						return region_data.region_size == subframe_region_size and region_data.region_location == subframe_region_location)
					
					var modified_description: String = seq_description.replace("\n", ", ").replace("-, ", "-<br>").replace(", -", "<br>-")
					if modified_description.contains("-"):
						modified_description = "<br>" + modified_description

					if region_id != -1: # add data to existing region
						var existing_region: SpritesheetRegionData = regions[region_id]
						var new_shp_frame_id_label: String = str(shp_frame_id)

						if not existing_region.shp_frame_ids.has(shp_frame_id):
							existing_region.shp_frame_ids.append(shp_frame_id)

						if not existing_region.shp_frame_id_labels.has(new_shp_frame_id_label):
							existing_region.shp_frame_id_labels.append(new_shp_frame_id_label)
						
						if not existing_region.animation_ids.has(seq_ptr_index):
							existing_region.animation_ids.append(seq_ptr_index)
							existing_region.animation_descriptions.append(modified_description)
					else: # add new region if an existing region does not have the same location and size
						var new_region: SpritesheetRegionData = SpritesheetRegionData.new()
						new_region.shp_type = shp.file_name
						new_region.region_id = regions.size()
						new_region.region_size = subframe_region_size
						new_region.region_location = subframe_region_location
						new_region.shp_frame_ids.append(shp_frame_id)
						new_region.animation_ids.append(seq_ptr_index)

						var new_shp_frame_id_label: String = str(shp_frame_id)
						new_region.shp_frame_id_labels.append(new_shp_frame_id_label)

						modified_description = modified_description.trim_prefix("<br>")
						new_region.animation_descriptions.append(modified_description)
						regions.append(new_region)
				
				if shp.has_submerged_data:
					var frame_submerged: FrameData = shp.frames_submerged[shp_frame_id]
					
					for subframe_idx: int in frame_submerged.subframes.size():
						var subframe: SubFrameData = frame_submerged.subframes[subframe_idx]
						var subframe_region_size = subframe.rect_size
						var subframe_region_location = Vector2i(subframe.load_location_x, subframe.load_location_y)

						var region_id: int = regions.find_custom(func(region_data: SpritesheetRegionData): 
							return region_data.region_size == subframe_region_size and region_data.region_location == subframe_region_location)
						
						var modified_description: String = seq_description.replace("\n", ", ").replace("-, ", "-<br>").replace(", -", "<br>-")
						if modified_description.contains("-"):
							modified_description = "<br>" + modified_description

						if region_id != -1: # add data to existing region
							var existing_region: SpritesheetRegionData = regions[region_id]
							var new_shp_frame_id_label: String = str(shp_frame_id) + "-S"

							if not existing_region.shp_frame_ids.has(shp_frame_id):
								existing_region.shp_frame_ids.append(shp_frame_id)
							
							if not existing_region.shp_frame_id_labels.has(new_shp_frame_id_label):
								existing_region.shp_frame_id_labels.append(new_shp_frame_id_label)
							
							if not existing_region.animation_ids.has(seq_ptr_index):
								existing_region.animation_ids.append(seq_ptr_index)
								existing_region.animation_descriptions.append(modified_description)
						else: # add new region if an existing region does not have the same location and size
							var new_region: SpritesheetRegionData = SpritesheetRegionData.new()
							new_region.shp_type = shp.file_name
							new_region.region_id = regions.size()
							new_region.region_size = subframe_region_size
							new_region.region_location = subframe_region_location
							new_region.shp_frame_ids.append(shp_frame_id)
							new_region.animation_ids.append(seq_ptr_index)

							var new_shp_frame_id_label: String = str(shp_frame_id) + "-S"
							new_region.shp_frame_id_labels.append(new_shp_frame_id_label)

							modified_description = modified_description.trim_prefix("<br>")
							new_region.animation_descriptions.append(modified_description)
							regions.append(new_region)
	
	# convert data to text file
	var table_start: String = '{| class="wikitable mw-collapsible mw-collapsed sortable"\n|+ style="text-align:left; white-space:nowrap" | ' + shp.file_name + ' Regions\n'
	var headers: PackedStringArray = [
		"! SHP Type",
		"Region ID",
		"Region Location",
		"Region Size",
		"SHP Frame IDs",
		"SEQ Animation IDs",
		"Animation Descriptions",
	]
	
	var output: String = table_start + " !! ".join(headers)
	var output_array: PackedStringArray = []
	output_array.append(output)
	for region: SpritesheetRegionData in regions:
		var row_strings: PackedStringArray = []
		row_strings.append("| " + region.shp_type)
		row_strings.append(str(region.region_id))
		row_strings.append(str(region.region_location))
		row_strings.append(str(region.region_size))
		row_strings.append(str(region.shp_frame_id_labels).remove_chars('[]"'))
		row_strings.append(str(region.animation_ids).remove_chars("[]"))
		row_strings.append(str(region.animation_descriptions).remove_chars('[]"'))
		
		# var description_list: String = str(region.animation_descriptions)
		# description_list = description_list.replace("\n", "<br>")
		# row_strings.append(description_list)

		output_array.append(" || ".join(row_strings))
	
	var final_output: String = "\n|-\n".join(output_array)
	final_output += "\n|}"
	
	var file_name: String = shp.file_name.to_snake_case().replace(".","_") + "_regions"
	DirAccess.make_dir_recursive_absolute("user://wiki_tables")
	var save_file := FileAccess.open("user://wiki_tables/wiki_table_" + file_name + ".txt", FileAccess.WRITE)
	save_file.store_string(final_output)

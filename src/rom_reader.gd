#class_name RomReader
extends Node

signal rom_loaded

var is_ready: bool = false

var rom: PackedByteArray = []
var file_records: Dictionary = {} # {String, FileRecord}
var lba_to_file_name: Dictionary = {} # {int, String}

const DIRECTORY_DATA_SECTORS_ROOT: PackedInt32Array = [22]
const OFFSET_RECORD_DATA_START: int = 0x60

# https://en.wikipedia.org/wiki/CD-ROM#CD-ROM_XA_extension
const BYTES_PER_SECTOR: int = 2352
const BYTES_PER_SECTOR_HEADER: int = 24
const BYTES_PER_SECTOR_FOOTER: int = 280
const DATA_BYTES_PER_SECTOR: int = 2048

var sprs: Array[Spr] = []
var spr_file_name_to_id: Dictionary = {}

var shps: Array[Shp] = []
var seqs: Array[Seq] = []
var maps: Array[MapData] = []
var effects: Array[VisualEffectData] = []
var abilities: Array[AbilityData] = []

@export_file("*.txt") var item_frames_csv_filepath: String = "res://src/fftae/frame_data_item.txt"

# BATTLE.BIN tables
# https://ffhacktics.com/wiki/BATTLE.BIN_Data_Tables#Animation_.26_Display_Related_Data
var sounds_attacks # BATTLE.BIN offset="2cd40" - table of sounds for miss, hit, and deflected, by weapong type
var ability_animations # BATTLE.BIN offset="2ce10" - sets of 3 bytes total for 1) charging, 2) executing, and 3) text
var wep_animation_offsets # BATTLE.BIN offset="2d364" - Weapon Change of Animation (multiplied by 2 (+1 if camera is behind the unit) to get true animation - applied to unit when attacking
var item_graphics # BATTLE.BIN offset="2d3e4" - Item Graphic Data (0x7f total?), palettes (wep1 or wep2), and graphic id (multiple of 2)
var unit_frame_sizes # BATTLE.BIN offset="2d53c" - Unit raw size measurements? all words. contains many possible raw size combinations (for the record, these are all *8 to get the true graphic size.)
var wep_eff_frame_sizes # BATTLE.BIN offset="2d6c8" - weapon/effect raw size measurements? all words, with only a byte of data each. this is just inefficient.
var spritesheet_data # BATTLE.BIN offset="2d748" - Spritesheet Data (4 bytes each, 0x9f total), SHP, SEQ, Flying, Graphic Height
var frame_targeted # BATTLE.BIN offset="2d9c4" - called if target hasn't replaced target animation (e.g. shield)


# Images
# https://github.com/Glain/FFTPatcher/blob/master/ShishiSpriteEditor/PSXImages.xml#L148


# Text
# https://github.com/Glain/FFTPatcher/blob/master/FFTacText/notes.txt
# BATTLE.BIN
# fa35c - fa928 - Battle Error Messages Text
# fa929 - fad41 - Battle Messages Text
# fad41 - fb2c2 - Job Names Text
# fb2c3 - fbe48 - Item Names Text
# fbe50 - fc0d9 - Japanese writing (FREE SPACE)
# fc0da - fcb87 - Act menus display data (0x05 bytes each, 0x06 for each unit?)
# fcb88 - fdeb6 - Skill/Ability Names Text
# fe93a - fed73 - skillset names
# fed88 - fedf5? - Summon names
# fedf6 -  - Draw out names

# https://ffhacktics.com/wiki/Load_FFTText
# OPEN.LZW - Sound Test - Track Names
# SPELL.MES - Spell Quotes
# WORLD.BIN 09 - Locations - Names
# WORLD.LZW 0x713b - 0x73e3 - Locations - Names
# WORLD.LZW - World Map Menu
# WORLD.LZW 0x74df - 0x7e69  - Maps - Names


#func _init() -> void:
	#pass


func on_load_rom_dialog_file_selected(path: String) -> void:
	var start_time: int = Time.get_ticks_msec()
	rom = FileAccess.get_file_as_bytes(path)
	push_warning("Time to load file (ms): " + str(Time.get_ticks_msec() - start_time))
	
	process_rom()
	
	#var ability_names: String = text_to_string(get_file_data("BATTLE.BIN").slice(0xfcb88, 0xfdeb6 + 1))
	#var map_names: String = text_to_string(get_file_data("WORLD.LZW").slice(0x74df, 0x7e69 + 1))
	#var location_names: String = text_to_string(get_file_data("WORLD.LZW").slice(0x713b, 0x73e3 + 1))
	#var text: String = text_to_string(get_file_data("WORLD.LZW").slice(0x7cd0, 0x8600 + 1))
	#push_warning(text)


func clear_data() -> void:
	file_records.clear()
	lba_to_file_name.clear()
	sprs.clear()
	spr_file_name_to_id.clear()
	shps.clear()
	seqs.clear()
	maps.clear()
	effects.clear()
	abilities.clear()


func process_rom() -> void:
	clear_data()
	
	var start_time: int = Time.get_ticks_msec()
	
	# http://wiki.osdev.org/ISO_9660#Directories
	process_file_records(DIRECTORY_DATA_SECTORS_ROOT)
	
	push_warning("Time to process ROM (ms): " + str(Time.get_ticks_msec() - start_time))
	
	_load_battle_bin_sprite_data()
	cache_associated_files()
	
	is_ready = true
	rom_loaded.emit()


func process_file_records(sectors: PackedInt32Array) -> void:
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
			if file_extension == "": # folder
				#push_warning("Getting files from folder: " + record.name)
				var data_length_sectors: int = ceil(float(record.size) / DATA_BYTES_PER_SECTOR)
				var directory_sectors: PackedInt32Array = range(record.sector_location, record.sector_location + data_length_sectors)
				process_file_records(directory_sectors)
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
	
	# get shp for item graphics
	var item_shp_name: String = "ITEM.SHP"
	var item_shp_record: FileRecord = FileRecord.new()
	item_shp_record.name = item_shp_name
	item_shp_record.type_index = shps.size()
	file_records[item_shp_name] = item_shp_record
	var item_shp: Shp = Shp.new(item_shp_name)
	item_shp.set_frames_from_csv(item_frames_csv_filepath)
	shps.append(item_shp)
	
	# get item graphics
	# TODO set type_index
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


# https://ffhacktics.com/wiki/BATTLE.BIN_Data_Tables#Animation_.26_Display_Related_Data
func _load_battle_bin_sprite_data() -> void:
	# get BATTLE.BIN file data
	# get item graphics
	var battle_bin_record: FileRecord = FileRecord.new()
	battle_bin_record.sector_location = 1000 # ITEM.BIN is in EVENT not BATTLE, so needs a new record created
	battle_bin_record.size = 1397096
	battle_bin_record.name = "BATTLE.BIN"
	file_records[battle_bin_record.name] = battle_bin_record
	
	# look up spr file_name based on LBA
	var spritesheet_file_data_length: int = 8
	var battle_bin_bytes: PackedByteArray = file_records["BATTLE.BIN"].get_file_data(rom)
	for sprite_id: int in range(0, 0x9f):
		var spritesheet_file_data_start: int = 0x2dcd4 + (sprite_id * spritesheet_file_data_length)
		var spritesheet_file_data_bytes: PackedByteArray = battle_bin_bytes.slice(spritesheet_file_data_start, spritesheet_file_data_start + spritesheet_file_data_length)
		var spritesheet_lba: int = spritesheet_file_data_bytes.decode_u32(0)
		var spritesheet_file_name: String = ""
		if spritesheet_lba != 0:
			spritesheet_file_name = lba_to_file_name[spritesheet_lba]
		spr_file_name_to_id[spritesheet_file_name] = sprite_id


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


# https://ffhacktics.com/wiki/Font
static func text_to_string(bytes_text: PackedByteArray) -> String:
	var text : String = ""
	
	if bytes_text.size() == 0:                        
		push_warning("No text data")
		return text
	
	
	var byte_index: int = 0
	while byte_index < bytes_text.size():
		var char_code: int = bytes_text[byte_index]
		
		if char_code > 0xda:
			byte_index += 1
		elif char_code > 0xcf:
			var code_2bytes: String = bytes_text.slice(byte_index, byte_index + 2).hex_encode()
			char_code = code_2bytes.hex_to_int()
			#char_code = bytes_text.decode_u16(byte_index)
			byte_index += 2
		else:
			byte_index += 1
		
		if char_code == 0xfa or char_code == 0xda73: # space
			char_code = 0x20
		elif char_code == 0xfe: # end string?
			char_code = 0x0d
		elif char_code < 10: # 0-9 are digits
			char_code += 0x30
		elif char_code < 36: # next 26 are upper case alphabet
			char_code += (0x41 - 10)
		elif char_code < 62: # next 26 are lower case alphabet
			char_code += (0x61 - 36)
		elif char_code == 62 or char_code == 0xd11a: # exclamation mark
			char_code = 0x21
		elif char_code == 63: # japanese
			char_code = 0 # TODO fix
		elif char_code == 64 or char_code == 0xd9c9: # question mark
			char_code = 0x3f
		elif char_code == 65: # japanese
			char_code = 0 # TODO fix
		elif char_code == 66 or char_code == 0xd11e: # plus sign
			char_code = 0x2b
		elif char_code == 67: # japanese
			char_code = 0 # TODO fix
		elif char_code == 68 or char_code == 0xd9c6: # forward slash
			char_code = 0x2f
		elif char_code == 69: # japanese
			char_code = 0 # TODO fix
		elif char_code == 70 or char_code == 0xd9bd: # colon
			char_code = 0x3a
		# 71 - 94 japanese
		elif char_code == 95 or char_code == 0xd11c or char_code == 0xd9b6: # period
			char_code = 0x2e
		# 96 - 138 japanese
		elif char_code == 139 or char_code == 0xd9bc: # middle dot
			char_code = 0xb7
		elif char_code == 140: # japanese
			char_code = 0 # TODO fix
		elif char_code == 141 or char_code == 0xd9be: # open parentheses
			char_code = 0x28
		elif char_code == 142 or char_code == 0xd9bf: # close parentheses
			char_code = 0x29
		# 143 - 144 japanese
		elif char_code == 145 or char_code == 0xda77 or char_code == 0xd9c0: # double quote
			char_code = 0x22
		elif char_code == 147 or char_code == 0xda76 or char_code == 0xd9c1: # single quote, apostrophe
			char_code = 0x27
		elif char_code == 178: # music note
			char_code = 0x1d160
		elif char_code == 181 or char_code == 0xd111: # asterisk
			char_code = 0x2a
		elif char_code == 0xd117: # underscore
			char_code = 0x5f
		elif char_code == 0xd11b: # ellipsis
			char_code = 0x2026
		elif char_code == 0xd11d: # minus sign
			char_code = 0x2d
		elif char_code == 0xd11f: # multiplication sign
			char_code = 0xd7
		elif char_code == 0xd120: # division sign
			char_code = 0xf7
		elif char_code == 0xd123 or char_code == 0xda70: # equal sign
			char_code = 0x3d
		elif char_code == 0xd125: # greater than
			char_code = 0x3e
		elif char_code == 0xd126: # less than
			char_code = 0x3c
		elif char_code == 0xd9b5: # infinity
			char_code = 0x221e
		elif char_code == 0xd9b7: # ampersand
			char_code = 0x26
		elif char_code == 0xd9b8: # percent
			char_code = 0x25
		elif char_code == 0xd9b9: # circle
			char_code = 0x25cb
		elif char_code == 0xd9c5: # tilde
			char_code = 0x7e
		elif char_code == 0xd9c7: # triangle
			char_code = 0x25b3
		elif char_code == 0xd9c8: # square
			char_code = 0x25a1
		elif char_code == 0xd9ca: # heart
			char_code = 0x2665
		elif char_code >= 0xd9cb and char_code <= 0xd9cf: # roman numerals
			char_code = (char_code - 0xd9cb) + 0x2160
		elif char_code >= 0xda00 and char_code <= 0xda0b: # zodiac signs
			char_code = (char_code - 0xda00) + 0x2648
		elif char_code == 0xda0c: # serpentarius zodiac signs
			text += "[Serpentarius]"
			continue
		elif char_code == 0xda71: # dollar sign
			char_code = 0x24
		elif char_code == 0xda74: # comma
			char_code = 0x2c
		elif char_code == 0xda75: # semi colon
			char_code = 0x3b
		
		text += String.chr(char_code)
	
	return text

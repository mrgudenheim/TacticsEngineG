#class_name RomReader
extends Node

signal rom_loaded

var is_ready: bool = false

var rom: PackedByteArray = []
var file_records: Dictionary[String, FileRecord] = {} # {String, FileRecord}
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

var sprs: Array[Spr] = []
var spr_file_name_to_id: Dictionary[String, int] = {}

var shps: Array[Shp] = []
var seqs: Array[Seq] = []
var maps: Array[MapData] = []
var effects: Array[VisualEffectData] = []
var abilities: Array[AbilityData] = []

@export_file("*.txt") var item_frames_csv_filepath: String = "res://src/fftae/frame_data_item.txt"

# BATTLE.BIN tables
var battle_bin_data: BattleBinData = BattleBinData.new()

# SCUS.942.41 tables
var scus_data: ScusData = ScusData.new()

# Images
# https://github.com/Glain/FFTPatcher/blob/master/ShishiSpriteEditor/PSXImages.xml#L148


# Text
var fft_text: FftText = FftText.new()


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
	effects.clear()
	abilities.clear()


func process_rom() -> void:
	clear_data()
	
	var start_time: int = Time.get_ticks_msec()
	
	# http://wiki.osdev.org/ISO_9660#Directories
	process_file_records(DIRECTORY_DATA_SECTORS_ROOT)
	
	push_warning("Time to process ROM (ms): " + str(Time.get_ticks_msec() - start_time))
	
	fft_text.init_text()
	battle_bin_data.init_from_battle_bin()
	scus_data.init_from_scus()
	
	cache_associated_files()
	
	for ability_id: int in NUM_ACTIVE_ABILITIES:
		abilities.append(AbilityData.new(ability_id))
	
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


func init_abilities() -> void:
	for ability_id: int in NUM_ABILITIES:
		abilities[ability_id] = AbilityData.new(ability_id)

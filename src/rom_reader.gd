#class_name RomReader
extends Node

signal rom_loaded

static var rom: PackedByteArray = []
static var file_records: Dictionary = {}
static var lba_to_file_name: Dictionary = {}

static var directory_data_sectors_battle: PackedInt32Array = range(56436, 56442)
static var directory_data_sectors_map: PackedInt32Array = range(9555, 9601)
static var directory_data_sectors: PackedInt32Array = []
const OFFSET_RECORD_DATA_START: int = 0x60

# https://en.wikipedia.org/wiki/CD-ROM#CD-ROM_XA_extension
const BYTES_PER_SECTOR: int = 2352
const BYTES_PER_SECTOR_HEADER: int = 24
const BYTES_PER_SECTOR_FOOTER: int = 280
const DATA_BYTES_PER_SECTOR: int = 2048

static var sprs: Array[Spr] = []
static var spr_file_name_to_id: Dictionary = {}

static var shps: Array[Shp] = []
static var seqs: Array[Seq] = []
static var maps: Array[MapData] = []


func _init() -> void:
	directory_data_sectors.append_array(directory_data_sectors_battle)
	directory_data_sectors.append_array(directory_data_sectors_map)


func on_load_rom_dialog_file_selected(path: String) -> void:
	var start_time: int = Time.get_ticks_msec()
	rom = FileAccess.get_file_as_bytes(path)
	push_warning("Time to load file (ms): " + str(Time.get_ticks_msec() - start_time))
	
	process_rom(rom)


static func clear_data() -> void:
	file_records.clear()
	sprs.clear()
	spr_file_name_to_id.clear()
	shps.clear()
	seqs.clear()
	maps.clear()


func process_rom(new_rom: PackedByteArray) -> void:
	clear_data()
	
	var start_time: int = Time.get_ticks_msec()
	
	# http://wiki.osdev.org/ISO_9660#Directories
	for directory_sector: int in directory_data_sectors:
		var offset_start: int = 0
		if (directory_sector == directory_data_sectors_battle[0]
				or directory_sector == directory_data_sectors_map[0]):
			offset_start = OFFSET_RECORD_DATA_START
		var directory_start: int = directory_sector * BYTES_PER_SECTOR
		var directory_data: PackedByteArray = new_rom.slice(directory_start + BYTES_PER_SECTOR_HEADER, directory_start + DATA_BYTES_PER_SECTOR + BYTES_PER_SECTOR_HEADER)
		
		var byte_index: int = offset_start
		while byte_index < DATA_BYTES_PER_SECTOR:
			var record_length: int = directory_data.decode_u8(byte_index)
			var record_data: PackedByteArray = directory_data.slice(byte_index, byte_index + record_length)
			var record: FileRecord = FileRecord.new(record_data)
			record.record_location_sector = directory_sector
			record.record_location_offset = byte_index
			file_records[record.name] = record
			lba_to_file_name[record.sector_location] = record.name
			
			var file_extension: String = record.name.get_extension()
			if file_extension == "SPR":
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
	
	push_warning("Time to process ROM (ms): " + str(Time.get_ticks_msec() - start_time))
	
	_load_battle_bin_sprite_data()
	rom_loaded.emit()


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


static func get_file_data(file_name: String) -> PackedByteArray:
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

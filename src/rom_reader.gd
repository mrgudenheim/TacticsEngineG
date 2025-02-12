class_name RomReader

signal rom_loaded

static var rom: PackedByteArray = []
static var file_records: Dictionary = {}
static var lba_to_file_name: Dictionary = {}

var directory_data_sectors_battle: PackedInt32Array = range(56436, 56442)
var directory_data_sectors_map: PackedInt32Array = range(9555, 9601)
var directory_data_sectors: PackedInt32Array = []
const OFFSET_RECORD_DATA_START: int = 0x60

# https://en.wikipedia.org/wiki/CD-ROM#CD-ROM_XA_extension
const BYTES_PER_SECTOR: int = 2352
const BYTES_PER_SECTOR_HEADER: int = 24
const BYTES_PER_SECTOR_FOOTER: int = 280
const DATA_BYTES_PER_SECTOR: int = 2048


func _init() -> void:
	directory_data_sectors.append_array(directory_data_sectors_battle)
	directory_data_sectors.append_array(directory_data_sectors_map)


func on_load_rom_dialog_file_selected(path: String) -> void:
	var start_time: int = Time.get_ticks_msec()
	rom = FileAccess.get_file_as_bytes(path)
	push_warning("Time to load file (ms): " + str(Time.get_ticks_msec() - start_time))
	
	process_rom(rom)


func process_rom(new_rom: PackedByteArray) -> void:
	file_records.clear()
	
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
			
			byte_index += record_length
			if directory_data.decode_u8(byte_index) == 0: # end of data, rest of sector will be padded with zeros
				break
	
	push_warning("Time to process ROM (ms): " + str(Time.get_ticks_msec() - start_time))
	
	rom_loaded.emit()


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

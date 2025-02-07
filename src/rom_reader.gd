class_name RomReader

var rom: PackedByteArray = []
var file_records: Dictionary = {}
var lba_to_file_name: Dictionary = {}

static var directory_start_sector: int = 56436
static var directory_data_sectors: PackedInt32Array = [56436, 56437, 56438, 56439, 56440, 56441]
static var directory_data_sectors_map: PackedInt32Array = range(9555, 9601)
const OFFSET_RECORD_DATA_START: int = 0x60

# https://en.wikipedia.org/wiki/CD-ROM#CD-ROM_XA_extension
const bytes_per_sector: int = 2352
const bytes_per_sector_header: int = 24
const bytes_per_sector_footer: int = 280
const data_bytes_per_sector: int = 2048

func process_rom(new_rom: PackedByteArray) -> void:
	file_records.clear()
	
	var start_time: int = Time.get_ticks_msec()
	
	for directory_sector: int in directory_data_sectors:
		var offset_start: int = 0
		if directory_sector == directory_data_sectors[0]:
			offset_start = OFFSET_RECORD_DATA_START
		var directory_start: int = directory_sector * bytes_per_sector
		var directory_data: PackedByteArray = new_rom.slice(directory_start, directory_start + data_bytes_per_sector + bytes_per_sector_header)
		
		var byte_index: int = offset_start + bytes_per_sector_header
		while byte_index < data_bytes_per_sector + bytes_per_sector_header:
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

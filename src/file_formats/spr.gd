class_name Spr extends Bmp

const PORTRAIT_HEIGHT: int = 32 # pixels

var spritesheet: Image
var has_compressed: bool = true
var is_sp2: bool = false
var sp2s: Dictionary = {}
var shp_name: String = ""
var seq_name: String = ""
var sprite_id: int = 0

func _init() -> void:
	file_name = "spr_file"
	bits_per_pixel = 4
	palette_data_start = 0
	pixel_data_start = num_colors * 2 # after 256 color palette, 2 bytes per color - 1 bit for alpha, followed by 5 bits per channel (B,G,R)
	width = 256 # pixels
	height = 488 # need to set based on file?
	num_pixels = width * height


func get_sub_spr(new_name: String, start_pixel: int, end_pixel: int) -> Spr:
	var sub_spr: Spr = Spr.new()
	sub_spr.file_name = new_name
	sub_spr.color_palette = color_palette
	sub_spr.color_indices = color_indices.slice(start_pixel, end_pixel)
	sub_spr.set_pixel_colors()
	sub_spr.spritesheet = sub_spr.get_rgba8_image()
	
	return sub_spr

func set_data(spr_file: PackedByteArray, new_name: String) -> void:
	file_name = new_name
	if file_name.to_upper().contains("OTHER"):
		num_colors = 512
		has_compressed = false
	elif (file_name.to_upper().contains("WEP") 
		or file_name.to_upper().contains("EFF")
		or file_name.to_upper().contains("0")
		or file_name.to_upper().contains("CYOMON")
		or file_name.to_upper().contains("DAMI")
		or file_name.to_upper().contains("FURAIA")
		or file_name.to_upper().contains("ITEM")
		):
			has_compressed = false
	
	var num_palette_bytes: int = num_colors * 2
	var palette_bytes: PackedByteArray = spr_file.slice(0, num_palette_bytes)
	var num_bytes_top: int = (width * 256) /2
	var top_pixels_bytes: PackedByteArray = spr_file.slice(num_palette_bytes, num_palette_bytes + num_bytes_top)
	var num_bytes_portrait_rows: int = (width * PORTRAIT_HEIGHT) /2
	var portrait_rows_pixels: PackedByteArray = spr_file.slice(num_palette_bytes + num_bytes_top, num_palette_bytes + num_bytes_top + num_bytes_portrait_rows)
	var spr_compressed_bytes: PackedByteArray = spr_file.slice(0x9200) if has_compressed else PackedByteArray()
	var spr_decompressed_bytes: PackedByteArray = decompress(spr_compressed_bytes)
	
	var spr_total_decompressed_bytes: PackedByteArray = []
	spr_total_decompressed_bytes.append_array(top_pixels_bytes)
	spr_total_decompressed_bytes.append_array(spr_decompressed_bytes)
	spr_total_decompressed_bytes.append_array(portrait_rows_pixels)
	
	set_palette_data(palette_bytes)
	color_indices = set_color_indices(spr_total_decompressed_bytes)
	set_pixel_colors()
	spritesheet = get_rgba8_image()


func set_palette_data(palette_bytes: PackedByteArray) -> void:
	color_palette.resize(num_colors)
	for i: int in num_colors:
		var color: Color = Color.BLACK
		var color_bits: int = palette_bytes.decode_u16(palette_data_start + (i*2))
		color.a8 = 1 - ((color_bits & 0b1000_0000_0000_0000) >> 15) # first bit is alpha (if bit is zero, color is opaque)
		color.b8 = (color_bits & 0b0111_1100_0000_0000) >> 10 # then 5 bits each: blue, green, red
		color.g8 = (color_bits & 0b0000_0011_1110_0000) >> 5
		color.r8 = color_bits & 0b0000_0000_0001_1111
		
		# convert 5 bit channels to 8 bit
		#color.a8 = 255 * color.a8 # first bit is alpha (if bit is zero, color is opaque)
		color.a8 = 255 # TODO use alpha correctly
		color.b8 = roundi(255 * (color.b8 / float(31))) # then 5 bits each: blue, green, red
		color.g8 = roundi(255 * (color.g8 / float(31)))
		color.r8 = roundi(255 * (color.r8 / float(31)))
		
		# if first color in 16 color palette is black, treat it as transparent
		if (i % 16 == 0
			and color == Color.BLACK):
				color.a8 = 0
		color_palette[i] = color


func set_color_indices(pixel_bytes: PackedByteArray) -> Array[int]:
	var new_color_indicies: Array[int] = []
	new_color_indicies.resize(pixel_bytes.size() * 2)
	
	for i: int in new_color_indicies.size():
		var pixel_offset: int = (i * bits_per_pixel)/8
		var byte: int = pixel_bytes.decode_u8(pixel_offset)
		
		if i % 2 == 1: # get 4 leftmost bits
			new_color_indicies[i] = byte >> 4
		else:
			new_color_indicies[i] = byte & 0b0000_1111 # get 4 rightmost bits
	
	return new_color_indicies

func set_pixel_colors(palette_id: int = 0) -> void:
	var new_pixel_colors: PackedColorArray = []
	var new_size: int = color_indices.size()
	var err: int = new_pixel_colors.resize(new_size)
	#pixel_colors.resize(color_indices.size())
	new_pixel_colors.fill(Color.BLACK)
	for i: int in color_indices.size():
		new_pixel_colors[i] = color_palette[color_indices[i] + (16 * palette_id)]
	
	pixel_colors = new_pixel_colors


func get_rgba8_image() -> Image:
	height = color_indices.size() / width
	var image:Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for x in width:
		for y in height:
			var color:Color = pixel_colors[x + (y * width)]
			var color8:Color = Color8(color.r8, color.g8, color.b8, color.a8) # use Color8 function to prevent issues with format conversion changing color by 1/255
			image.set_pixel(x,y, color8) # spr stores pixel data left to right, top to bottm
	
	return image


func decompress(compressed_bytes: PackedByteArray) -> PackedByteArray:
	var num_pixels_compressed: int = 200 * width if has_compressed else 0
	
	var decompressed_bytes: PackedByteArray = []
	decompressed_bytes.resize(num_pixels_compressed / 2)
	decompressed_bytes.fill(0)
	
	var half_byte_data: PackedByteArray = []
	half_byte_data.resize(compressed_bytes.size() * 2)
	half_byte_data.fill(0)
	
	var decompressed_full_bytes: PackedByteArray = []
	decompressed_full_bytes.resize(num_pixels_compressed)
	decompressed_full_bytes.fill(0)
	
	# get half bytes
	for i: int in compressed_bytes.size():
		var byte: int = compressed_bytes.decode_u8(i)
		half_byte_data[i * 2] = byte >> 4 # get 4 leftmost bits
		half_byte_data[(i * 2) + 1] = byte & 0b0000_1111 # get 4 rightmost bits
	
	# decompress
	var half_byte_index: int = 0
	var decompressed_full_byte_index: int = 0
	while half_byte_index < half_byte_data.size():
		var half_byte: int = half_byte_data[half_byte_index]
		if half_byte != 0:
			decompressed_full_bytes[decompressed_full_byte_index] = half_byte_data[half_byte_index]
			half_byte_index += 1
			decompressed_full_byte_index += 1
			continue
		elif half_byte_index + 1 < half_byte_data.size(): # if 0, start compressed area
			var next_half: int = half_byte_data[half_byte_index + 1]
			var num_zeroes: int = next_half
			
			if next_half == 0:
				num_zeroes = half_byte_data[half_byte_index + 2]
				decompressed_full_byte_index += num_zeroes
				half_byte_index += 3
			elif next_half == 7:
				num_zeroes = half_byte_data[half_byte_index + 2] + (half_byte_data[half_byte_index + 3] << 4)
				decompressed_full_byte_index += num_zeroes
				half_byte_index += 4
			elif next_half == 8:
				num_zeroes = half_byte_data[half_byte_index + 2] + (half_byte_data[half_byte_index + 3] << 4) + (half_byte_data[half_byte_index + 4] << 8)
				decompressed_full_byte_index += num_zeroes
				half_byte_index += 5
			else:
				decompressed_full_byte_index += num_zeroes
				half_byte_index += 2
		else:
			half_byte_index += 1
	
	# full bytes to half bytes
	for index: int in decompressed_full_bytes.size() / 2:
		decompressed_bytes[index] = decompressed_full_bytes[index * 2] << 4
		decompressed_bytes[index] = decompressed_bytes[index] | decompressed_full_bytes[(index * 2) + 1]
	
	return decompressed_bytes


func set_sp2s(file_records: Dictionary, rom: PackedByteArray) -> void:
	var sp2_name_base: String = file_name.get_basename()
	if sp2_name_base == "TETSU":
		sp2_name_base = "IRON"
	
	for file_num: int in range(5):
		var sp2_name: String = sp2_name_base + str(file_num) + ".SP2"
		if file_records.has(sp2_name):
			var file_record: FileRecord = file_records[sp2_name]
			var sp2_data: PackedByteArray = file_record.get_file_data(rom)
			color_indices.append_array(set_color_indices(sp2_data))
	
	set_pixel_colors()
	spritesheet = get_rgba8_image()


func set_spritesheet_data(new_sprite_id: int, battle_bin_bytes: PackedByteArray) -> void:
	# WEP and EFF partially handled directly in preview_manager QueueSpriteAnim opcode
	# TODO handle WEP and EFF when direclty selected
	sprite_id = new_sprite_id
	var spritesheet_data_length: int = 4
	var spritesheet_data_start: int = 0x2d748 + (sprite_id * spritesheet_data_length)
	
	var spritesheet_data_bytes: PackedByteArray = battle_bin_bytes.slice(spritesheet_data_start, spritesheet_data_start + spritesheet_data_length)
	var shp_id: int = spritesheet_data_bytes[0]
	var seq_id: int = spritesheet_data_bytes[1]
	var flying_flag: int = spritesheet_data_bytes[2]
	var graphic_height: int = spritesheet_data_bytes[3]
	
	match shp_id:
		0:
			shp_name = "TYPE1.SHP"
		1:
			shp_name = "TYPE2.SHP"
		2:
			shp_name = "CYOKO.SHP"
		3:
			shp_name = "MON.SHP"
		4:
			shp_name = "OTHER.SHP"
		5:
			shp_name = "MON.SHP" # RUKA
		6:
			shp_name = "ARUTE.SHP"
		7:
			shp_name = "KANZEN.SHP"
	
	match seq_id:
		0:
			seq_name = "TYPE1.SEQ"
		1:
			seq_name = "TYPE3.SEQ"
		2:
			seq_name = "CYOKO.SEQ"
		3:
			seq_name = "MON.SEQ"
		4:
			seq_name = "OTHER.SEQ"
		5:
			seq_name = "RUKA.SEQ"
		6:
			seq_name = "ARUTE.SHP"
		7:
			seq_name = "KANZEN.SEQ"

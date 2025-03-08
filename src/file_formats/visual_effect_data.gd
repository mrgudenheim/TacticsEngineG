class_name VisualEffectData

# https://ffhacktics.com/wiki/Effect_Files
# https://ffhacktics.com/wiki/Effect_Data
var is_initialized: bool = false
var file_name: String = "effect file name"
var vfx_id: int = 0

var header_start: int = 0

var spritesheet: Image
var sprite_format: int = 8 # 8bpp or 4bpp
var image_height: int = 0 # pixels
var image_width = sprite_format * 16 # unless

# SINGLE - camera will point at the targeted location
# SEQUENTIAL - camera will move between each each target
# MULTI - camera will point at a single location, but make sure all targets are in view
enum camera_focus {SINGLE, SEQUENTIAL, MULTI} 

var sound_effects
var partical_effects

func _init(new_file_name: String = "") -> void:
	file_name = new_file_name
	vfx_id = new_file_name.trim_suffix(".BIN").trim_prefix("E").to_int()


func init_from_file() -> void:
	var vfx_bytes: PackedByteArray = RomReader.get_file_data(file_name)
	header_start = RomReader.battle_bin_data.ability_vfx_header_offsets[vfx_id]
	var section_offsets_bytes: PackedByteArray = vfx_bytes.slice(header_start, header_start + 40)
	
	is_initialized = true

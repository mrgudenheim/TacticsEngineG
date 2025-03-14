class_name BattleBinData

var sounds_whoosh_start: int = 0x2cd40
var sounds_hit_start: int = 0x2cd60
var sounds_deflection_start: int = 0x2cd80


var ability_animation_charging_sets_start: int = 0x2cde8 # 20 entries, 2 bytes each
var ability_animation_start_ids: PackedInt32Array = [] # multiplied by 2 (+1 if unit is backfacing) to get animation_ptr_id
var ability_animation_charging_ids: PackedInt32Array = [] # multiplied by 2 (+1 if unit is backfacing) to get animation_ptr_id

var ability_animation_ids_start: int = 0x2ce10 # 1 byte each, 3 bytes per entry
var ability_animation_charging_set_ids: PackedInt32Array = [] # index into ability_animation_start_ids and ability_animation_charging_ids
var ability_animation_executing_ids: PackedInt32Array = [] # multiplied by 2 (+1 if unit is backfacing) to get animation_ptr_id
var ability_animation_text_ids: PackedInt32Array = [] # index into BATTLE_ACTION_EFFECT text

var weapon_animation_ids_start: int = 0x2d364 # 3 bytes per entry, 1 entry per item type
var weapon_animation_ids: PackedVector3Array = [] # attack high, mid, low - multiplied by 2 (+1 if unit is backfacing) to get true animation, Fists/Unarmed used by MON

var item_graphic_data_start: int = 0x2d3e4
var item_graphic_palettes: PackedInt32Array = [] # 0xF0 - WEP1 Palette, 0x0F - WEP2 Palette
var item_graphic_ids: PackedInt32Array = [] 

var unit_subframe_sizes_start: int = 0x2d53c # 8 bytes each, two uint16 per entry, 32 entries
var unit_subframe_sizes: PackedVector2Array = []
var wep_eff_subframe_sizes_start: int = 0x2d6c8 # 8 bytes each, two uint16 per entry, 32 entries
var wep_eff_subframe_sizes: PackedVector2Array = []

var spritesheet_data_start: int = 0x2d748 # 4 bytes each
var spritesheet_shp_id: PackedInt32Array = [] # Type 1, 2, cyoko, mon, other, ruka, arute, kanzen
var spritesheet_seq_id: PackedInt32Array = [] 
var spritesheet_flying: PackedByteArray = [] # bool
var spritesheet_graphic_height: PackedInt32Array = [] # pixels

var targeted_front_frame_id_start: int = 0x2d9c4 # 0x0c entries, 1 byte each
var targeted_front_frame_id: PackedInt32Array = []
var targeted_back_frame_id_start: int = 0x2d9d0 # 0x0c entries
var targeted_back_frame_id: PackedInt32Array = []

var ability_vfx_header_offsets_start: int = 0x14d8d0 # 511 entries, 8 bytes each, 2 uint32 each
var ability_vfx_header_offsets: PackedInt32Array = [] 

var ability_vfx_ids_start: int = 0x14f3f0 # 2 bytes each - uint16
var ability_vfx_ids: PackedInt32Array = [] 


func init_from_battle_bin() -> void:
	var battle_bytes: PackedByteArray = RomReader.get_file_data("BATTLE.BIN")
	
	# ability animation charging sets
	var entry_size: int = 2 # bytes
	var num_entries: int = 20
	var ability_animation_charging_sets_bytes: PackedByteArray = battle_bytes.slice(ability_animation_charging_sets_start, ability_animation_charging_sets_start + (num_entries * entry_size))
	ability_animation_start_ids.resize(num_entries)
	ability_animation_charging_ids.resize(num_entries)
	for set_id: int in ability_animation_charging_sets_bytes.size() / entry_size:
		ability_animation_start_ids[set_id] = ability_animation_charging_sets_bytes.decode_u8(set_id * entry_size)
		ability_animation_charging_ids[set_id] = ability_animation_charging_sets_bytes.decode_u8((set_id * entry_size) + 1)
	
	# ability animations
	entry_size = 3 # bytes
	var ability_animation_id_bytes: PackedByteArray = battle_bytes.slice(ability_animation_ids_start, ability_animation_ids_start + (RomReader.NUM_ACTIVE_ABILITIES * entry_size))
	ability_animation_charging_set_ids.resize(RomReader.NUM_ACTIVE_ABILITIES)
	ability_animation_executing_ids.resize(RomReader.NUM_ACTIVE_ABILITIES)
	ability_animation_text_ids.resize(RomReader.NUM_ACTIVE_ABILITIES)
	for ability_id: int in ability_animation_id_bytes.size() / entry_size:
		ability_animation_charging_set_ids[ability_id] = ability_animation_id_bytes.decode_u8(ability_id * entry_size)
		ability_animation_executing_ids[ability_id] = ability_animation_id_bytes.decode_u8((ability_id * entry_size) + 1)
		ability_animation_text_ids[ability_id] = ability_animation_id_bytes.decode_u8((ability_id * entry_size) + 2)
	
	# ability vfx header offsets
	entry_size = 3
	num_entries = ItemData.ItemType.CLOTH + 1
	weapon_animation_ids.resize(num_entries)
	var data_bytes: PackedByteArray = battle_bytes.slice(weapon_animation_ids_start, weapon_animation_ids_start + (num_entries * entry_size))
	for id: int in data_bytes.size() / entry_size:
		weapon_animation_ids[id] = Vector3(data_bytes.decode_u8(id * entry_size), data_bytes.decode_u8(id * entry_size) + 1, data_bytes.decode_u8(id * entry_size) + 2)
	
	# ability vfx header offsets
	entry_size = 4
	num_entries = RomReader.NUM_VFX
	data_bytes = battle_bytes.slice(ability_vfx_header_offsets_start, ability_vfx_header_offsets_start + (num_entries * entry_size))
	ability_vfx_header_offsets.resize(RomReader.NUM_VFX)
	for id: int in data_bytes.size() / entry_size:
		ability_vfx_header_offsets[id] = data_bytes.decode_u32(id * entry_size) - 0x801c2500
	
	# ability vfx
	entry_size = 2
	var ability_vfx_id_bytes: PackedByteArray = battle_bytes.slice(ability_vfx_ids_start, ability_vfx_ids_start + (RomReader.NUM_ACTIVE_ABILITIES * entry_size))
	ability_vfx_ids.resize(RomReader.NUM_ACTIVE_ABILITIES)
	for ability_id: int in ability_vfx_id_bytes.size() / entry_size:
		ability_vfx_ids[ability_id] = ability_vfx_id_bytes.decode_u16(ability_id * entry_size)
	
	# TODO get vfx_ids for items, reations (support and movement don't have vfx)
	
	_load_battle_bin_sprite_data()
	
	# TODO all the other battle.bin data


# https://ffhacktics.com/wiki/BATTLE.BIN_Data_Tables#Animation_.26_Display_Related_Data
func _load_battle_bin_sprite_data() -> void:
	var battle_bytes: PackedByteArray = RomReader.get_file_data("BATTLE.BIN")
	
	# look up spr file_name based on LBA
	var spritesheet_file_data_length: int = 8
	for sprite_id: int in RomReader.NUM_SPRITESHEETS:
		var spritesheet_file_data_start: int = 0x2dcd4 + (sprite_id * spritesheet_file_data_length)
		var spritesheet_file_data_bytes: PackedByteArray = battle_bytes.slice(spritesheet_file_data_start, spritesheet_file_data_start + spritesheet_file_data_length)
		var spritesheet_lba: int = spritesheet_file_data_bytes.decode_u32(0)
		var spritesheet_file_name: String = ""
		if spritesheet_lba != 0:
			spritesheet_file_name = RomReader.lba_to_file_name[spritesheet_lba]
		RomReader.spr_file_name_to_id[spritesheet_file_name] = sprite_id

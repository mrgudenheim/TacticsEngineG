# ffhacktics.com/wiki/BATTLE.BIN_Data_Tables
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

var weapon_graphic_data_start: int = 0x2d3e4
var weapon_graphic_palettes_1: PackedInt32Array = [] # 0xF0 - WEP1 Palette, 0x0F - WEP2 Palette
var weapon_graphic_palettes_2: PackedInt32Array = [] # 0xF0 - WEP1 Palette, 0x0F - WEP2 Palette
var weapon_frames_vertical_offsets: PackedInt32Array = [] # WEP.SHP vertical offsets

var animation_layer_priorities_start: int = 0x2d548 # 4 uint32 per entry, 0x1b entries? maybe only 0x17?
var animation_layer_priorities: PackedVector4Array = []

var shp_subframe_sizes_start: int = 0x2d6c8 # 8 bytes each, two uint32 per entry, 16 entries
var shp_subframe_sizes: PackedVector2Array = []

var spritesheet_data_start: int = 0x2d748 # 4 bytes each
var spritesheet_shp_id: PackedInt32Array = [] # Type 1, 2, cyoko, mon, other, ruka, arute, kanzen
var spritesheet_seq_id: PackedInt32Array = [] 
var spritesheet_flying: PackedByteArray = [] # bool
var spritesheet_graphic_height: PackedInt32Array = [] # pixels

var targeted_front_frame_id_start: int = 0x2d9c4 # 0x0c entries, 1 byte each, index is seq type?
var targeted_front_frame_id: PackedInt32Array = []
var targeted_back_frame_id_start: int = 0x2d9d0 # 0x0c entries
var targeted_back_frame_id: PackedInt32Array = []

var ability_vfx_header_offsets_start: int = 0x14d8d0 # 511 entries, 8 bytes each, 2 uint32 each
var ability_vfx_header_offsets: PackedInt32Array = [] 

var ability_vfx_ids_start: int = 0x14f3f0 # 2 bytes each - uint16
var ability_vfx_ids: PackedInt32Array = [] 

var status_image_rects_start: int = 0x14cf68 - 0x67000 # 4 bytes each, 49 entries, mostly text + sword and rod icon
var status_image_rects: Array[Rect2i] = []

var status_bubble_locations_x_start: int = 0x949dc - 0x67000 # 22 bytes long
var status_bubble_locations_y_start: int = 0x949f4 - 0x67000 # 22 bytes long
var status_death_counter_locations_x_start: int = 0x94a0c - 0x67000 # 22 bytes long
var status_death_counter_locations_y_start: int = 0x94a24 - 0x67000 # 22 bytes long

var ai_status_priority_start: int = 0x19f308 - 0x67000 # 40 entries, 2 bytes each, signed int16s
var ai_status_priorities: PackedInt32Array = []

# https://ffhacktics.com/wiki/Palette_mod_by_status
var status_colors_start: int = 0x822bc - 0x67000 # color RGBs per status are littered throughout routine
var status_colors: Dictionary[int, PackedInt32Array] = { # status_id :  [R, G, B, Shade type]
	8 : [0, 0, 0, 6], # petrify
	13 : [3, -1, 8, 6], # blood suck
	20 : [8, 0, 0, 4], # berserk
	24 : [0, 8, 0, 5], # poison
	25 : [0, 0, 8, 4], # regen
	16 : [-4, -4, -4, 5], # oil
	14 : [-8, -8, -8, 5], # cursed
	3 : [4, 0, 5, 5], # undead
}

# https://ffhacktics.com/wiki/Set_Idle_Animation_based_on_status_(not_MON)
# https://ffhacktics.com/wiki/More_animation_based_on_status,_death_sound_effects
# https://ffhacktics.com/wiki/Set_Animation_Based_On_Unit_Status
var status_idle_animations: Dictionary[int, int] = { # status_id :  animation_id
	1 : 18, # crystal
	15: 42, # treasure
	2 : 52, # dead
	32 : 4, # stop
	35 : 72, # sleep
	8 : 4, # petrify
	11 : 74, # confusion
	7 : 0x50, # performing - use ability ID (0x50 singing or 0x52 dancing)
	4 : 0x54, # charging - use ability ID (0x54)
	6 : 46, # defending
	28 : 0x08, # haste - useHeight1 (14 for flying sprites)
	29 : 0x0a, # slow - useHeight2 (16 for flying sprites)
	14 : 4, # cursed
	0 : 66, # blank
}

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
	
	# TODO get vfx_ids for items, reactions (support and movement don't have vfx)
	
	# weapon/shield shp frame vertical offsets and palettes
	entry_size = 2
	num_entries = 0x90
	weapon_graphic_palettes_1.resize(num_entries) # 0xF0 - WEP1 Palette, 0x0F - WEP2 Palette
	weapon_graphic_palettes_2.resize(num_entries) # 0xF0 - WEP1 Palette, 0x0F - WEP2 Palette
	weapon_frames_vertical_offsets.resize(num_entries)
	data_bytes = battle_bytes.slice(weapon_graphic_data_start, weapon_graphic_data_start + (num_entries * entry_size))
	for id: int in num_entries:
		weapon_graphic_palettes_1[id] = (data_bytes.decode_u8(id * entry_size) & 0xf0) >> 4
		weapon_graphic_palettes_2[id] = data_bytes.decode_u8(id * entry_size) & 0x0f
		weapon_frames_vertical_offsets[id] = data_bytes.decode_u8((id * entry_size) + 1) * 8
	
	# WEP and EFF subframe sizes
	entry_size = 8 # two uint32
	num_entries = 16
	shp_subframe_sizes.resize(num_entries)
	data_bytes = battle_bytes.slice(shp_subframe_sizes_start, shp_subframe_sizes_start + (num_entries * entry_size))
	for id: int in num_entries:
		shp_subframe_sizes[id] = Vector2(data_bytes.decode_u32(id * entry_size), data_bytes.decode_u32((id * entry_size) + 4)) * 8
	
	# being targeted frame ids
	entry_size = 1
	num_entries = 12
	targeted_front_frame_id.resize(num_entries)
	targeted_back_frame_id.resize(num_entries)
	data_bytes = battle_bytes.slice(targeted_front_frame_id_start, targeted_front_frame_id_start + (num_entries * entry_size * 2)) # *2 to get both front and back tables at once
	for id: int in num_entries:
		targeted_front_frame_id[id] = data_bytes.decode_u8(id * entry_size)
		targeted_back_frame_id[id] = data_bytes.decode_u8((id * entry_size) + (targeted_back_frame_id_start - targeted_front_frame_id_start))
	
	# spritesheet shp, seq, flying, height data
	entry_size = 4
	num_entries = RomReader.NUM_SPRITESHEETS
	spritesheet_shp_id.resize(num_entries) # Type 1, 2, cyoko, mon, other, ruka, arute, kanzen
	spritesheet_seq_id.resize(num_entries) # Type 1, 2, cyoko, mon, other, ruka, arute, kanzen
	spritesheet_flying.resize(num_entries) # bool
	spritesheet_graphic_height.resize(num_entries) # pixels
	data_bytes = battle_bytes.slice(spritesheet_data_start, spritesheet_data_start + (num_entries * entry_size))
	for idx: int in num_entries:
		spritesheet_shp_id[idx] = data_bytes.decode_u8(idx * entry_size)
		spritesheet_seq_id[idx] = data_bytes.decode_u8((idx * entry_size) + 1)
		spritesheet_flying[idx] = data_bytes.decode_u8((idx * entry_size) + 2)
		spritesheet_graphic_height[idx] = data_bytes.decode_u8((idx * entry_size) + 3)
	
	
	# animation layer prioity table
	entry_size = 16
	num_entries = 0x1b
	animation_layer_priorities.resize(num_entries)
	data_bytes = battle_bytes.slice(animation_layer_priorities_start, animation_layer_priorities_start + (num_entries * entry_size))
	for idx: int in num_entries:
		animation_layer_priorities[idx].w = data_bytes.decode_u32(idx * entry_size)
		animation_layer_priorities[idx].x = data_bytes.decode_u32((idx * entry_size) + 4)
		animation_layer_priorities[idx].y = data_bytes.decode_u32((idx * entry_size) + 8)
		animation_layer_priorities[idx].z = data_bytes.decode_u32((idx * entry_size) + 12)
	
	_load_battle_bin_sprite_data()
	
	# ai status prioity table
	entry_size = 2
	num_entries = 40
	ai_status_priorities.resize(num_entries)
	data_bytes = battle_bytes.slice(ai_status_priority_start, ai_status_priority_start + (num_entries * entry_size))
	for idx: int in num_entries:
		ai_status_priorities[idx] = data_bytes.decode_s16(idx * entry_size)
	
	
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
		RomReader.spr_id_file_idxs[sprite_id] = RomReader.file_records[spritesheet_file_name].type_index

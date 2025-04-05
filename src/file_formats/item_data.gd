class_name ItemData

# https://ffhacktics.com/wiki/Item_Data

var name: String = "Item name"
var id: int = 0
var item_graphic_id: int = 0
var item_palette_id: int = 0
var min_level: int = 0
var slot_type: SlotType
var item_type: ItemType = ItemType.FISTS
var price: int = 100
var shop_availability_start: int = 0

var wep_frame_v_offset: int = 0
var wep_frame_palette: int = 0

enum SlotType {
	WEAPON = 0x80,
	SHIELD = 0x40,
	HEADGEAR = 0x20,
	ARMOR = 0x10,
	ACCESSORY = 0x08,
	RARE = 0x02,
	}

enum ItemType {
	FISTS = 0,
	KNIFE = 1,
	NINJA_BLADE,
	SWORD,
	KNIGHT_SWORD,
	KATANA,
	AXE,
	ROD,
	STAFF,
	FLAIL,
	GUN,
	CROSSBOW,
	BOW,
	INSTRUMENT,
	BOOK,
	SPEAR,
	POLE,
	BAG,
	CLOTH,
	SHIELD,
	HELMET,
	HAT,
	HAIR_ADORNMENT,
	ARMOR,
	CLOTHING,
	ROBE,
	SHOES,
	ARMGUARD,
	RING,
	ARMLET,
	CLOAK,
	PERFUME,
	SHURIKEN,
	BALL,
	ITEM,
	}

# In SCUS data tables
func _init(idx: int = 0) -> void:
	name = RomReader.fft_text.item_names[idx]
	id = idx
	item_type = RomReader.scus_data.item_types[idx]
	slot_type = RomReader.scus_data.item_slot_types[idx]
	
	item_graphic_id = RomReader.scus_data.item_sprite_ids[idx]
	item_palette_id = RomReader.scus_data.item_palettes[idx]
	min_level = RomReader.scus_data.item_min_levels[idx]
	price = RomReader.scus_data.item_prices[idx]
	shop_availability_start = RomReader.scus_data.item_shop_availability[idx]
	
	if idx < 0x90: # weapons and shields
		wep_frame_palette = RomReader.battle_bin_data.weapon_graphic_palettes_1[idx] # TODO handle different palettes for wep1.shp and wep2.shp
		wep_frame_v_offset = RomReader.battle_bin_data.weapon_frames_vertical_offsets[idx]
	
	#if idx >= 1:
		#item_type = RomReader.scus_data.item_types[idx - 1]
	#else:
		#item_type = ItemType.FISTS
	
	# TODO rest of item data

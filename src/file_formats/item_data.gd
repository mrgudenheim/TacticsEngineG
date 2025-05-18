class_name ItemData
extends Resource

# https://ffhacktics.com/wiki/Item_Data

@export var name: String = "Item name"
var id: int = 0
@export var item_graphic_id: int = 0
@export var item_palette_id: int = 0
@export var min_level: int = 0
@export var slot_type: SlotType = SlotType.NONE
@export var is_rare: bool = false
@export var item_type: ItemType = ItemType.FISTS
var item_attribute_id: int = 0 # https://ffhacktics.com/wiki/Item_Attribute stat modifiers, always/start/immune statuses, elemental interaction
@export var price: int = 100
@export var shop_availability_start: int = 0

var wep_frame_v_offset: int = 0
@export var wep_frame_palette: int = 0

# weapon data
@export var range: int = 1
@export var weapon_formula_id: int = 1
@export var weapon_power: int = 1
@export var weapon_evade: int = 0
@export var weapon_element: Utilities.ElementalTypes = Utilities.ElementalTypes.NONE
@export var weapon_inflict_status_spell_id: int = 0
@export var weapon_targeting_strategy: TargetingStrategy
@export var is_dual_wieldable: bool = false
@export var is_two_handable: bool = false
@export var is_throwable: bool = false
@export var takes_both_hands: bool = false

# shield data
@export var shield_physical_evade: int = 0
@export var shield_magical_evade: int = 0

# accessory data
@export var accessory_physical_evade: int = 0
@export var accessory_magical_evade: int = 0

# armour/helm data
@export var hp_modifier: int = 0
@export var mp_modifier: int = 0

# attribute data
@export var pa_modifier: int = 0
@export var ma_modifier: int = 0
@export var sp_modifier: int = 0
@export var move_modifier: int = 0
@export var jump_modifier: int = 0
@export var status_always: Array[StatusEffect] = []
@export var status_immune: Array[StatusEffect] = []
@export var status_start: Array[StatusEffect] = []
@export var elemental_absorb: Array[Utilities.ElementalTypes] = [] # 1 byte of bitflags, elemental types
@export var elemental_cancel: Array[Utilities.ElementalTypes] = [] # 1 byte of bitflags, elemental types
@export var elemental_half: Array[Utilities.ElementalTypes] = [] # 1 byte of bitflags, elemental types
@export var elemental_weakness: Array[Utilities.ElementalTypes] = [] # 1 byte of bitflags, elemental types
@export var elemental_strengthen: Array[Utilities.ElementalTypes] = [] # 1 byte of bitflags, elemental types

# chemist item data
@export var consumable_formula_id: int = 0
@export var consumable_item_z: int = 0
@export var consumable_inflict_status_id: int = 0

@export var actions_granted: Array[Action] = []

enum SlotType {
	WEAPON = 0x80,
	SHIELD = 0x40,
	HEADGEAR = 0x20,
	ARMOR = 0x10,
	ACCESSORY = 0x08,
	NONE = 0x04,
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
	CONSUMABLE_ITEM,
	}

# In SCUS data tables
func _init(idx: int = 0) -> void:
	name = RomReader.fft_text.item_names[idx]
	id = idx
	item_type = RomReader.scus_data.item_types[idx]
	slot_type = RomReader.scus_data.item_slot_types[idx] & 0xfc # skip rare flag
	is_rare = RomReader.scus_data.item_slot_types[idx] & 0x02 == 0x02 # rare flag
	
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
	
	set_item_attributes(RomReader.scus_data.item_attributes[RomReader.scus_data.item_attributes_id[idx]])
	
	var sub_index: int = idx
	# weapon data
	if idx < 0x80:
		range = RomReader.scus_data.weapon_range[idx]
		weapon_formula_id = RomReader.scus_data.weapon_formula_id[idx]
		weapon_power = RomReader.scus_data.weapon_power[idx]
		weapon_evade = RomReader.scus_data.weapon_evade[idx]
		weapon_element = RomReader.scus_data.weapon_element[idx]
		weapon_inflict_status_spell_id = RomReader.scus_data.weapon_inflict_status_cast_id[idx]
		#weapon_targeting_strategy =  # TODO weapon targeting types based on weapon_flags
		is_dual_wieldable = RomReader.scus_data.weapon_flags[idx] & 0x08 == 0x08
		is_two_handable = RomReader.scus_data.weapon_flags[idx] & 0x04 == 0x04
		is_throwable = RomReader.scus_data.weapon_flags[idx] & 0x02 == 0x02
		takes_both_hands = RomReader.scus_data.weapon_flags[idx] & 0x01 == 0x01
		
	elif idx < 0x90: # shield data
		sub_index = idx - 0x80
		shield_physical_evade = RomReader.scus_data.shield_physical_evade[sub_index]
		shield_magical_evade = RomReader.scus_data.shield_magical_evade[sub_index]
	elif idx < 0xd0: # armour/helm data
		sub_index = idx - 0x90
		hp_modifier = RomReader.scus_data.armour_hp_modifier[sub_index]
		mp_modifier = RomReader.scus_data.armour_mp_modifier[sub_index]
	elif idx < 0xf0: # accessory data
		sub_index = idx - 0xd0
		accessory_physical_evade = RomReader.scus_data.accessory_physical_evade[sub_index]
		accessory_magical_evade = RomReader.scus_data.accessory_magical_evade[sub_index]
	elif idx < 0xfe: # chemist item data
		sub_index = idx - 0xf0
		consumable_formula_id = RomReader.scus_data.chem_item_formula_id[sub_index]
		consumable_item_z = RomReader.scus_data.chem_item_z[sub_index]
		consumable_inflict_status_id = RomReader.scus_data.chem_item_inflict_status_id[sub_index]


func set_item_attributes(item_attribute: ScusData.ItemAttribute) -> void:
	pa_modifier = item_attribute.pa_modifier
	ma_modifier = item_attribute.ma_modifier
	sp_modifier = item_attribute.sp_modifier
	move_modifier = item_attribute.move_modifier
	jump_modifier = item_attribute.jump_modifier
	status_always = item_attribute.status_always
	status_immune = item_attribute.status_immune
	status_start = item_attribute.status_start
	elemental_absorb = Utilities.get_elemental_types_array([item_attribute.elemental_absorb])
	elemental_cancel = Utilities.get_elemental_types_array([item_attribute.elemental_cancel])
	elemental_half = Utilities.get_elemental_types_array([item_attribute.elemental_half])
	elemental_weakness = Utilities.get_elemental_types_array([item_attribute.elemental_weakness])
	elemental_strengthen = Utilities.get_elemental_types_array([item_attribute.elemental_strengthen])

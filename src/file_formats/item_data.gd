class_name ItemData

var name: String = "Item name"
var sprite_id: int = 0
var palette_id: int = 0
var min_level: int = 0
var slot_type
var item_type
var price: int = 100
var shop_availability_start: int = 0

enum SlotType {
	WEAPON = 0x80,
	SHIELD = 0x40,
	HEADGEAR = 0x20,
	ARMOR = 0x10,
	ACCESSORY = 0x08,
	RARE = 0x02,
	}

enum ItemType {
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
	THROWING,
	BOMB,
	ITEM,
	}

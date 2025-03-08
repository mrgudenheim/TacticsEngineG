class_name AbilityData

# https://ffhacktics.com/wiki/Ability_Data
# https://ffhacktics.com/wiki/BATTLE.BIN_Data_Tables#Animation_.26_Display_Related_Data

enum AbilityType {
	NONE,
	NORMAL,
	ITEM,
	THROWING,
	JUMPING,
	AIM,
	MATH_SKILL,
	REACTION,
	SUPPORT,
	MOVEMENT,
	UNKNOWN1,
	UNKNOWN2,
	UNKNOWN3,
	UNKNOWN4,
	UNKNOWN5,
	UNKNOWN6,
	}

var id: int = 0
var name: String = "ability name"
var spell_quote: String = "spell quote"
var jp_cost: int = 0
var chance_to_learn: float = 100 # percent
var ability_type: AbilityType = AbilityType.NORMAL

var formula # TODO store Callable?
var formula_id: int = 0
var formula_x: int = 0
var formula_y: int = 0
var targeting_range: int = 1
var effect_radius: int = 1
var vertical_tolerance: int = 2
var inflict_status_id: int = 0
var ticks_charge_time: int = 0
var mp_cost: int = 0

var animation_charging_set_id: int # BATTLE.BIN offset="2ce10" - table of animations IDs used by Ability ID - byte 1
var animation_start_id: int
var animation_charging_id: int
var animation_executing_id: int # BATTLE.BIN offset="2ce10" - table of animations IDs used by Ability ID - byte 2
var animation_text_id: int # BATTLE.BIN offset="2ce10" - table of animations IDs used by Ability ID - byte 3
var effect_text: String = "ability effect"

var vfx_data: VisualEffectData # BATTLE.BIN offset="14F3F0" - table of Effect IDs used by Ability ID
var vfx_id: int = 0


func _init(new_id: int = 0) -> void:	
	id = new_id
	
	name = RomReader.fft_text.ability_names[id]
	spell_quote = RomReader.fft_text.spell_quotes[id]
	
	
	animation_charging_set_id = RomReader.battle_bin_data.ability_animation_charging_set_ids[new_id]
	animation_start_id = RomReader.battle_bin_data.ability_animation_start_ids[animation_charging_set_id] * 2
	animation_charging_id = RomReader.battle_bin_data.ability_animation_charging_ids[animation_charging_set_id] * 2
	animation_executing_id = RomReader.battle_bin_data.ability_animation_executing_ids[new_id] * 2
	animation_text_id = RomReader.battle_bin_data.ability_animation_text_ids[new_id]
	effect_text = RomReader.fft_text.battle_effect_text[animation_text_id]
	vfx_id = RomReader.battle_bin_data.ability_effect_ids[new_id]
	
	jp_cost = RomReader.scus_data.jp_costs[new_id]
	chance_to_learn = RomReader.scus_data.chance_to_learn[new_id]
	ability_type = RomReader.scus_data.ability_types[new_id]
	formula_id = RomReader.scus_data.formula_id[new_id]
	formula_x = RomReader.scus_data.formula_x[new_id]
	formula_y = RomReader.scus_data.formula_y[new_id]
	targeting_range = RomReader.scus_data.ranges[new_id]
	effect_radius = RomReader.scus_data.effect_radius[new_id]
	vertical_tolerance = RomReader.scus_data.vertical_tolerance[new_id]
	inflict_status_id = RomReader.scus_data.inflict_status_id[new_id]
	ticks_charge_time = RomReader.scus_data.ct[new_id]
	
	
	
	if animation_executing_id == 0:
		animation_executing_id = 0x3e * 2 # TODO look up based on equiped weapon and target relative height
		# use RomReader.battle_bin_data.weapon_animation_ids

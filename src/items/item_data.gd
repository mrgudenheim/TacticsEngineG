class_name ItemData
extends Resource

# https://ffhacktics.com/wiki/Item_Data

@export var name: String = "Item name"
@export var item_idx: int = 0
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
# ROM data for debug mostly, equivalent data is stored in weapon_attack_action
var max_range: int = 1
var weapon_formula_id: int = 1
var weapon_power: int = 1
var weapon_evade: int = 0
var weapon_element: Action.ElementTypes = Action.ElementTypes.NONE
var weapon_inflict_status_spell_id: int = 0
var weapon_is_striking: bool = true
var weapon_is_lunging: bool = false
var weapon_is_direct: bool = false
var weapon_is_arc: bool = false
#@export var weapon_targeting_strategy: TargetingStrategy

@export var weapon_attack_action: Action
@export var is_dual_wieldable: bool = false
@export var is_two_handable: bool = false
@export var is_throwable: bool = false
@export var takes_both_hands: bool = false

#@export var weapon_add_status_chance: int = 100
#@export var weapon_add_statuses: Array[StatusEffect] = []
#@export var weapon_other_effect_chance: int = 100
#@export var weapon_other_effects: Array = [] # TODO create data structure for other effects

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
var stat_modifiers: Dictionary[UnitData.StatType, Modifier] = {}
@export var pa_modifier: int = 0
@export var ma_modifier: int = 0
@export var sp_modifier: int = 0
@export var move_modifier: int = 0
@export var jump_modifier: int = 0

@export var status_always: PackedInt32Array = []
@export var status_immune: PackedInt32Array = []
@export var status_start: PackedInt32Array = []

@export var elemental_absorb: Array[Action.ElementTypes] = [] # 1 byte of bitflags, elemental types
@export var elemental_cancel: Array[Action.ElementTypes] = [] # 1 byte of bitflags, elemental types
@export var elemental_half: Array[Action.ElementTypes] = [] # 1 byte of bitflags, elemental types
@export var elemental_weakness: Array[Action.ElementTypes] = [] # 1 byte of bitflags, elemental types
@export var elemental_strengthen: Array[Action.ElementTypes] = [] # 1 byte of bitflags, elemental types

# chemist item data
@export var consumable_formula_id: int = 0
@export var consumable_item_z: int = 0
@export var consumable_inflict_status_id: int = 0

#@export var actions_granted: Array[Action] = []

@export var evade_datas: Array[EvadeData] = []

@export var passive_effect: PassiveEffect = PassiveEffect.new() # TODO item move element affinities, stat modifiers, and status arrays to passive_effect

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
	item_idx = idx
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
		max_range = RomReader.scus_data.weapon_range[idx]
		weapon_formula_id = RomReader.scus_data.weapon_formula_id[idx]
		weapon_power = RomReader.scus_data.weapon_power[idx]
		weapon_evade = RomReader.scus_data.weapon_evade[idx]
		evade_datas.append(EvadeData.new(weapon_evade, EvadeData.EvadeSource.WEAPON, EvadeData.EvadeType.PHYSICAL))
		
		weapon_element = RomReader.scus_data.weapon_element[idx]
		weapon_inflict_status_spell_id = RomReader.scus_data.weapon_inflict_status_cast_id[idx]
		
		# weapon targeting types based on weapon_flags
		weapon_is_striking = RomReader.scus_data.weapon_flags[idx] & 0x80 == 0x80
		weapon_is_lunging = RomReader.scus_data.weapon_flags[idx] & 0x40 == 0x40
		weapon_is_direct = RomReader.scus_data.weapon_flags[idx] & 0x20 == 0x20
		weapon_is_arc = RomReader.scus_data.weapon_flags[idx] & 0x10 == 0x10
		
		is_dual_wieldable = RomReader.scus_data.weapon_flags[idx] & 0x08 == 0x08
		is_two_handable = RomReader.scus_data.weapon_flags[idx] & 0x04 == 0x04
		is_throwable = RomReader.scus_data.weapon_flags[idx] & 0x02 == 0x02
		takes_both_hands = RomReader.scus_data.weapon_flags[idx] & 0x01 == 0x01
		
		# make attack action
		weapon_attack_action = Action.new()
		weapon_attack_action.target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
		
		weapon_attack_action.target_effects[0].base_power_formula.values[0] = weapon_power
		weapon_attack_action.element = weapon_element
		weapon_attack_action.use_weapon_animation = true
		
		weapon_attack_action.action_name = "Attack (" + name + ")"
		weapon_attack_action.display_action_name = false
		weapon_attack_action.min_targeting_range = 0
		weapon_attack_action.max_targeting_range = max_range
		weapon_attack_action.area_of_effect_range = 0
		weapon_attack_action.has_vertical_tolerance_from_user = true
		weapon_attack_action.cant_target_self = true
		weapon_attack_action.applicable_evasion = EvadeData.EvadeType.PHYSICAL # TODO Guns have NONE, formula_id = 03 or 07 
		weapon_attack_action.blocked_by_golem = true
		weapon_attack_action.trigger_counter_flood = true
		weapon_attack_action.trigger_counter_grasp = true
		weapon_attack_action.trigger_types.append(TriggeredAction.TriggerType.PHYSICAL)
		weapon_attack_action.trigger_types.append(TriggeredAction.TriggerType.COUNTER_FLOOD)
		weapon_attack_action.trigger_types.append(TriggeredAction.TriggerType.MIMIC)
		
		weapon_attack_action.targeting_type = Action.TargetingTypes.RANGE
		# weapon_attack_action.targeting_strategy = Utilities.targeting_strategies[Utilities.TargetingTypes.RANGE] # set weapon targeting strategy to TargetingRange by default
		
		match item_type:
			ItemType.BOW, ItemType.CROSSBOW, ItemType.GUN, ItemType.INSTRUMENT, ItemType.BOOK:
				weapon_attack_action.min_targeting_range = 3
		
		match item_type:
			ItemType.FISTS:
				weapon_attack_action.target_effects[0].base_power_formula.formula = FormulaData.Formulas.PA_BRAVExPA
			ItemType.KNIFE, ItemType.NINJA_BLADE, ItemType.BOW, ItemType.SHURIKEN:
				weapon_attack_action.target_effects[0].base_power_formula.formula = FormulaData.Formulas.AVG_PA_SPxV1
			ItemType.SWORD, ItemType.ROD, ItemType.CROSSBOW, ItemType.SPEAR:
				weapon_attack_action.target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxV1
			ItemType.KNIGHT_SWORD, ItemType.KATANA:
				weapon_attack_action.target_effects[0].base_power_formula.formula = FormulaData.Formulas.PA_BRAVExV1
			ItemType.AXE, ItemType.FLAIL, ItemType.BAG:
				weapon_attack_action.target_effects[0].base_power_formula.formula = FormulaData.Formulas.RANDOM_PAxV1
			ItemType.STAFF, ItemType.POLE:
				weapon_attack_action.target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			ItemType.GUN:
				weapon_attack_action.target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1xV1
				weapon_attack_action.has_vertical_tolerance_from_user = false
			ItemType.INSTRUMENT, ItemType.BOOK, ItemType.CLOTH:
				weapon_attack_action.target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
		
		weapon_attack_action.description = "Attack Base Damage = " + FormulaData.formula_descriptions[weapon_attack_action.target_effects[0].base_power_formula.formula]
		weapon_attack_action.status_chance = 19 # https://ffhacktics.com/wiki/Weapon_Damage_Calculation
		
		match weapon_formula_id:
			4: # TODO proc ability for Formula 04 (magic gun)
				weapon_attack_action.applicable_evasion = EvadeData.EvadeType.NONE
				weapon_attack_action.target_effects.clear()
				var secondary_action_ids: PackedInt32Array = []
				match weapon_element:
					Action.ElementTypes.FIRE:
						secondary_action_ids = [0x10, 0x11, 0x12]
					Action.ElementTypes.LIGHTNING:
						secondary_action_ids = [0x14, 0x15, 0x16]
					Action.ElementTypes.ICE:
						secondary_action_ids = [0x18, 0x19, 0x1a]
				
				weapon_attack_action.secondary_actions_chances = [60, 30, 10]
				weapon_attack_action.secondary_action_list_type = Action.StatusListType.RANDOM
				
				for secondary_action_idx: int in secondary_action_ids.size():
					var new_secondary_action: Action = RomReader.abilities[secondary_action_ids[secondary_action_idx]].ability_action.duplicate(true) # abilities need to be initialized before items
					#new_secondary_action.area_of_effect_range = 0
					#new_secondary_action.target_effects[0].base_power_formula.formula = FormulaData.Formulas.WPxV1
					#new_secondary_action.mp_cost = 0
					var chance: int = weapon_attack_action.secondary_actions_chances[secondary_action_idx]
					weapon_attack_action.secondary_actions.append(new_secondary_action)
					weapon_attack_action.secondary_actions2.append(Action.SecondaryAction.new(new_secondary_action.action_idx, chance))
				
				# TODO damage formula is WP (instead of MA) * ability Y
				# TODO magic gun should probably use totally new Actions?, with WP*V1 formula, EvadeType.NONE, no costs, animation_ids = 0, etc., but where V1 and vfx are from the original action
			6:
				weapon_attack_action.target_effects[0].transfer_to_user = true # absorb hp
			7:
				weapon_attack_action.applicable_evasion = EvadeData.EvadeType.NONE
				weapon_attack_action.target_effects[0].base_power_formula.reverse_sign = false # positive action power is healing when false
		
		if weapon_formula_id == 2: # proc ability for Formula 02
			weapon_attack_action.secondary_actions.append(RomReader.abilities[weapon_inflict_status_spell_id].ability_action)
			weapon_attack_action.status_chance = 19
			weapon_attack_action.secondary_actions_chances = [19]
			weapon_attack_action.secondary_actions2.append(Action.SecondaryAction.new(RomReader.abilities[weapon_inflict_status_spell_id].ability_action.action_idx, 19))
		else: # inflict status data
			weapon_attack_action.inflict_status_id = weapon_inflict_status_spell_id
			var inflict_status: ScusData.InflictStatus = RomReader.scus_data.inflict_statuses[weapon_inflict_status_spell_id]
			weapon_attack_action.target_status_list = inflict_status.status_list
			weapon_attack_action.will_remove_status = inflict_status.will_cancel
			weapon_attack_action.status_chance = 19
			
			weapon_attack_action.target_status_list_type = Action.StatusListType.ALL
			if inflict_status.is_random:
				weapon_attack_action.target_status_list_type = Action.StatusListType.RANDOM
			elif inflict_status.is_separate:
				weapon_attack_action.target_status_list_type = Action.StatusListType.EACH
				weapon_attack_action.status_chance = roundi(weapon_attack_action.status_chance * 0.24)
		
		if weapon_is_striking:
			weapon_attack_action.max_targeting_range = 1
			weapon_attack_action.vertical_tolerance = 2.5 # TODO striking can hit 3 lower https://ffhacktics.com/wiki/Strike/Lunge_Routine
		elif weapon_is_lunging:
			weapon_attack_action.max_targeting_range = 2
			weapon_attack_action.vertical_tolerance = 3.5 # TODO lunging can hit 4 lower https://ffhacktics.com/wiki/Strike/Lunge_Routine
			weapon_attack_action.targeting_linear = true
			weapon_attack_action.targeting_los = true
		elif weapon_is_direct:
			weapon_attack_action.targeting_los = true
		
		var default_statuses_prevents_weapon_attacks: PackedInt32Array = [
			1, # crystal
			2, # dead
			8, # petrify
			13, # blood suck
			15, # treasure
			21, # chicken
			22, # frog
			30, # Stop
			37, # dont act
		]
		weapon_attack_action.status_prevents_use_any.append_array(default_statuses_prevents_weapon_attacks) # Don't Act, chicken, frog, blood suck status prevents weapon attack
		
		#weapon_attack_action.animation_executing_id = RomReader.battle_bin_data.weapon_animation_ids[item_type].y * 2
		emit_changed()
		
		
	elif idx < 0x90: # shield data
		sub_index = idx - 0x80
		shield_physical_evade = RomReader.scus_data.shield_physical_evade[sub_index]
		shield_magical_evade = RomReader.scus_data.shield_magical_evade[sub_index]
		
		evade_datas.append(EvadeData.new(shield_physical_evade, EvadeData.EvadeSource.SHIELD, EvadeData.EvadeType.PHYSICAL))
		evade_datas.append(EvadeData.new(shield_magical_evade, EvadeData.EvadeSource.SHIELD, EvadeData.EvadeType.MAGICAL))
	elif idx < 0xd0: # armour/helm data
		sub_index = idx - 0x90
		hp_modifier = RomReader.scus_data.armour_hp_modifier[sub_index]
		mp_modifier = RomReader.scus_data.armour_mp_modifier[sub_index]
		stat_modifiers[UnitData.StatType.HP_MAX] = Modifier.new(hp_modifier)
		stat_modifiers[UnitData.StatType.MP_MAX] = Modifier.new(mp_modifier)
		
	elif idx < 0xf0: # accessory data
		sub_index = idx - 0xd0
		accessory_physical_evade = RomReader.scus_data.accessory_physical_evade[sub_index]
		accessory_magical_evade = RomReader.scus_data.accessory_magical_evade[sub_index]
		
		evade_datas.append(EvadeData.new(accessory_physical_evade, EvadeData.EvadeSource.ACCESSORY, EvadeData.EvadeType.PHYSICAL))
		evade_datas.append(EvadeData.new(accessory_magical_evade, EvadeData.EvadeSource.ACCESSORY, EvadeData.EvadeType.MAGICAL))
	elif idx < 0xfe: # chemist item data
		sub_index = idx - 0xf0
		consumable_formula_id = RomReader.scus_data.chem_item_formula_id[sub_index]
		consumable_item_z = RomReader.scus_data.chem_item_z[sub_index]
		consumable_inflict_status_id = RomReader.scus_data.chem_item_inflict_status_id[sub_index]
	
	# remove empty modifiers
	for key: UnitData.StatType in stat_modifiers.keys():
		if stat_modifiers[key].value == 0:
			stat_modifiers.erase(key)
	
	emit_changed()


func set_item_attributes(item_attribute: ScusData.ItemAttribute) -> void:
	pa_modifier = item_attribute.pa_modifier
	ma_modifier = item_attribute.ma_modifier
	sp_modifier = item_attribute.sp_modifier
	move_modifier = item_attribute.move_modifier
	jump_modifier = item_attribute.jump_modifier
	
	stat_modifiers[UnitData.StatType.PHYSICAL_ATTACK] = Modifier.new(item_attribute.pa_modifier)
	stat_modifiers[UnitData.StatType.MAGIC_ATTACK] = Modifier.new(item_attribute.ma_modifier)
	stat_modifiers[UnitData.StatType.SPEED] = Modifier.new(item_attribute.sp_modifier)
	stat_modifiers[UnitData.StatType.MOVE] = Modifier.new(item_attribute.move_modifier)
	stat_modifiers[UnitData.StatType.JUMP] = Modifier.new(item_attribute.jump_modifier)
	
	status_always = item_attribute.status_always
	status_immune = item_attribute.status_immune
	status_start = item_attribute.status_start
	elemental_absorb = Action.get_element_types_array([item_attribute.elemental_absorb])
	elemental_cancel = Action.get_element_types_array([item_attribute.elemental_cancel])
	elemental_half = Action.get_element_types_array([item_attribute.elemental_half])
	elemental_weakness = Action.get_element_types_array([item_attribute.elemental_weakness])
	elemental_strengthen = Action.get_element_types_array([item_attribute.elemental_strengthen])

	emit_changed()

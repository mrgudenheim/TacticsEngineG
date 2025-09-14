class_name Action
extends Resource

static var current_id: int = 0

@export var action_id: int = 0
@export var action_idx: int = 0
@export var action_name: String = "Action Name"
@export var description: String = "Action description"
@export var quote: String = "Action quote"
@export var display_action_name: bool = true

@export var useable_strategy: UseableStrategy
@export var targeting_type: TargetingTypes = TargetingTypes.RANGE
var targeting_strategy: TargetingStrategy:
	get:
		return Utilities.targeting_strategies[targeting_type]
@export var use_type: UseTypes = UseTypes.NORMAL
var use_strategy: UseStrategy:
	get:
		return Utilities.use_strategies[use_type]

@export var move_points_cost: int = 0
@export var action_points_cost: int = 1

@export var mp_cost: int = 0

var formula_id: int = 0
var formula_x: int = 0
var formula_y: int = 0
@export var min_targeting_range: int = 0
@export var max_targeting_range: int = 4
@export var area_of_effect_range: int = 0
@export var vertical_tolerance: float = 2
var inflict_status_id: int = 0
@export var ticks_charge_time: int = 0

@export var has_vertical_tolerance_from_user: bool = false # vertical fixed / linear range
@export var use_weapon_range: bool = false
@export var use_weapon_targeting: bool = false
@export var use_weapon_damage: bool = false
@export var use_weapon_animation: bool = false
@export var auto_target: bool = false
@export var cant_target_self: bool = false
@export var cant_hit_enimies: bool = false
@export var cant_hit_allies: bool = false
@export var cant_hit_user: bool = false
@export var targeting_top_down: bool = false
@export var cant_follow_target: bool = true
@export var random_fire: bool = false
@export var targeting_linear: bool = false
@export var targeting_los: bool = false # stop at obstacle
@export var aoe_has_vertical_tolerance: bool = true # vertical tolerance
@export var aoe_vertical_tolerance: float = 2
@export var aoe_targeting_three_directions: bool = false
@export var aoe_targeting_linear: bool = false
@export var aoe_targeting_los: bool = false # stop at obstacle

@export var target_effects: Array[ActionEffect] = []
@export var user_effects: Array[ActionEffect] = []

#@export var is_evadable: bool = false
@export var applicable_evasion: EvadeData.EvadeType = EvadeData.EvadeType.PHYSICAL
@export var is_reflectable: bool = false
@export var is_math_usable: bool = false
@export var is_mimicable: bool = false
@export var blocked_by_golem: bool = false
@export var repeat_use: bool = false # performing
@export var vfx_on_empty: bool = false

@export var allow_triggered_actions: bool = true
@export var trigger_counter_flood: bool = false
@export var trigger_counter_magic: bool = false
@export var trigger_counter_grasp: bool = false

@export var can_target: bool = true

@export var element: ElementTypes = ElementTypes.NONE

@export var base_hit_formula: FormulaData = FormulaData.new(FormulaData.Formulas.V1, [100, 0], FormulaData.FaithModifier.NONE, FormulaData.FaithModifier.NONE, false, false, false)

@export var healing_damages_undead: bool = false
# @export var ignores_statuses: Array[int] = []
@export var ignores_statuses: PackedInt32Array = []

# inflict status data
@export var target_status_list: PackedInt32Array = []
@export var status_chance: int = 100
@export var will_remove_status: bool = false
@export var target_status_list_type: StatusListType = StatusListType.EACH
var all_status: bool = false
var random_status: bool = false
var separate_status: bool = false

@export var status_prevents_use_any: Array[int] = [] # silence, dont move, dont act, etc.
@export var required_equipment_type: Array[ItemData.ItemType] = [] # sword, gun, etc.
@export var required_equipment_idx: PackedInt32Array = [] # materia_blade, etc.
@export var required_target_job_id: Array[int] = [] # dragon, etc.
@export var required_target_status_id: Array[int] = [] # undead

# animation data
@export var animation_start_id: int = 0
@export var animation_charging_id: int = 0
@export var animation_executing_id: int = 0

@export var vfx_id: int = 0
var vfx_data: VisualEffectData

class SecondaryAction:
	var action_idx: int
	var chance: int
	
	func _init(new_action_idx: int, new_chance: int) -> void:
		action_idx = new_action_idx
		chance = new_chance

@export var secondary_actions: Array[Action] = [] # skip right to applying ActionEffects to targets, but can use new FormulaData
@export var secondary_actions_chances: PackedInt32Array = [100]
@export var secondary_action_list_type: StatusListType = StatusListType.EACH
var secondary_actions2: Array[SecondaryAction] = []

@export var set_target_animation_on_hit: bool = true
@export var ends_turn: bool = false

@export var hit_chance_modified_by_passive: bool = false
@export var power_modified_by_passive: bool = true

@export var trigger_types: Array[TriggeredAction.TriggerType] = []

enum ActionType {
	HP_DAMAGE,
	HP_RECOVERY,
	MP_DAMAGE,
	MP_RECOVERY,
	STATUS_CHANGE,
}

enum ElementTypes {
	NONE = 0x00,
	DARK = 0x01,
	HOLY = 0x02,
	WATER = 0x04,
	EARTH = 0x08,
	WIND = 0x10,
	ICE = 0x20,
	LIGHTNING = 0x40,
	FIRE = 0x80,
}

enum StatusListType {
	ALL,
	EACH,
	RANDOM,
}

enum ActionRelativePosition {
	FRONT,
	SIDE,
	BACK,
}

enum TargetingTypes {
	RANGE,
	MOVE,
}

enum UseTypes {
	NORMAL,
	MOVE,
}

func _init(new_idx: int = -1):
	action_id = current_id
	current_id += 1

	if new_idx < 0 or new_idx >= RomReader.actions.size():
		if new_idx >= RomReader.actions.size():
			push_warning("Action index (" + str(new_idx) + ") is beyond bounds. Setting action_idx to end of array: " + str(RomReader.actions.size()))
		
		action_idx = RomReader.actions.size()
		RomReader.actions.append(self)
	else:
		action_idx = new_idx
		RomReader.actions[action_idx] = self
		
	emit_changed()


func _to_string() -> String:
	return action_name


func is_usable(action_instance: ActionInstance) -> bool:
	var action_is_usable: bool = false
	if useable_strategy == null: # default usable check
		var user_has_enough_move_points: bool = action_instance.user.move_points_remaining >= action_instance.action.move_points_cost
		var user_has_enough_action_points: bool = action_instance.user.action_points_remaining >= action_instance.action.action_points_cost
		var user_has_enough_mp: bool = action_instance.user.mp_current >= action_instance.action.mp_cost
		var user_has_equipment_type: bool = required_equipment_type.is_empty() or required_equipment_type.has(action_instance.user.primary_weapon.item_type) # TODO check all unit.equip_slots, not just primary_weapon
		var user_has_equipment: bool = false
		if required_equipment_idx.is_empty():
			user_has_equipment = true
		else:
			for equipment_slot: UnitData.EquipmentSlot in action_instance.user.equip_slots:
				if required_equipment_idx.has(equipment_slot.item_idx): # TODO allow actions that require combination of items
					user_has_equipment = true
					break
		
		var action_not_prevented_by_status: bool = not action_instance.action.status_prevents_use_any.any(func(status_id: int): return action_instance.user.current_status_ids.has(status_id))
		
		action_is_usable = (user_has_enough_move_points 
				and user_has_enough_action_points 
				and user_has_enough_mp
				and action_not_prevented_by_status
				and user_has_equipment_type
				and user_has_equipment)
	else: # custom usable check
		action_is_usable = useable_strategy.is_usable(action_instance)
		
	return action_is_usable


func start_targeting(action_instance: ActionInstance) -> void:
	if targeting_strategy != null:
		targeting_strategy.start_targeting(action_instance)


func stop_targeting(action_instance: ActionInstance) -> void:
	if targeting_strategy != null:
		targeting_strategy.stop_targeting(action_instance)


func use(action_instance: ActionInstance) -> void:
	if use_strategy == null: # default use
		await apply_standard(action_instance)
	else:
		await use_strategy.use(action_instance)


func get_total_hit_chance(user: UnitData, target: UnitData, evade_direction: EvadeData.Directions) -> int:
	var base_hit_chance: float = base_hit_formula.get_result(user, target, element)
	var modified_hit_chance: float = base_hit_chance
	if hit_chance_modified_by_passive:
		for status: StatusEffect in user.current_statuses:
			modified_hit_chance = status.passive_effect.hit_chance_modifier_user.apply(modified_hit_chance)
		for status: StatusEffect in target.current_statuses:
			modified_hit_chance = status.passive_effect.hit_chance_modifier_targeted.apply(modified_hit_chance)
	
	#var evade_direction: EvadeData.EvadeDirections = get_evade_direction(user, target)
	var evade_values: PackedInt32Array = get_evade_values(target, evade_direction)
	
	var target_total_evade_factor: float = 1.0
	if applicable_evasion != EvadeData.EvadeType.NONE:
		# TODO loop over all EvadeData.EvadeSource possibilites?
		var job_evade_factor: float = max(0.0, 1 - (target.get_evade(EvadeData.EvadeSource.JOB, applicable_evasion, evade_direction) / 100.0)) # job/class evade factor - only front facing?
		var shield_evade_factor: float = max(0.0, 1 - (target.get_evade(EvadeData.EvadeSource.SHIELD, applicable_evasion, evade_direction) / 100.0)) # shield evade factor - only front and side facing?
		var accessory_factor: float = max(0.0, 1 - (target.get_evade(EvadeData.EvadeSource.ACCESSORY, applicable_evasion, evade_direction) / 100.0)) # accessory evade factor
		var weapon_evade_factor: float = max(0.0, 1 - (target.get_evade(EvadeData.EvadeSource.WEAPON, applicable_evasion, evade_direction) / 100.0)) # TODO weapon evade factor - only front and side facing? and only with "Weapon Guard" ability
	
		target_total_evade_factor = job_evade_factor * shield_evade_factor * accessory_factor * weapon_evade_factor
		target_total_evade_factor = max(0, target_total_evade_factor) # prevent negative evasion
	
	var total_hit_chance: int = roundi(modified_hit_chance * target_total_evade_factor)
	
	return roundi(total_hit_chance)


func get_evade_direction(user: UnitData, target: UnitData) -> EvadeData.Directions:
	var relative_position: Vector2i = user.tile_position.location - target.tile_position.location
	var relative_facing_position: Vector2i = relative_position
	if target.facing == UnitData.Facings.NORTH:
		pass # relative position is already correct for North facing
	elif target.facing == UnitData.Facings.EAST:
		relative_facing_position = Vector2i(-relative_position.y, relative_position.x)
	elif target.facing == UnitData.Facings.SOUTH:
		relative_facing_position = -relative_position
	elif target.facing == UnitData.Facings.WEST:
		relative_facing_position = Vector2i(relative_position.y, -relative_position.x)
	
	# check target facing, check x>y
	var evade_direction: EvadeData.Directions = EvadeData.Directions.FRONT
	if relative_facing_position.y < 0:
		evade_direction = EvadeData.Directions.BACK
		if abs(relative_facing_position.x) >= abs(relative_facing_position.y):
			evade_direction = EvadeData.Directions.SIDE
	elif abs(relative_facing_position.x) > abs(relative_facing_position.y):
		evade_direction = EvadeData.Directions.SIDE
	
	return evade_direction


func get_evade_values(target: UnitData, evade_direction: EvadeData.Directions) -> PackedInt32Array:
	var evade_values: PackedInt32Array = []
	for evade_source: EvadeData.EvadeSource in EvadeData.EvadeSource.keys().size():
		var evade_value: int = target.get_evade(evade_source, applicable_evasion, evade_direction)
		evade_values.append(evade_value)
	
	return evade_values


func animate_evade(target_unit: UnitData, evade_direction: EvadeData.Directions, user_pos: Vector2i):
	var target_original_facing = target_unit.facing_vector
	
	var dir_to_target: Vector2i = user_pos - target_unit.tile_position.location
	var temp_facing: Vector3 = Vector3(dir_to_target.x, 0, dir_to_target.y).normalized()
	target_unit.update_unit_facing(temp_facing)
	
	var evade_anim_id: int = -1
	var sum_of_weight: int = 0
	var evade_values: PackedInt32Array = get_evade_values(target_unit, evade_direction)
	for evade_source_value: int in evade_values:
		sum_of_weight += evade_source_value
	
	if sum_of_weight <= 0: # missed due to action base hit chance
		await target_unit.animate_evade(EvadeData.animation_ids[0])
	else:
		var rnd: int = randi_range(0, sum_of_weight)
		for evade_source_idx: int in evade_values.size():
			var evade_source_value: int = evade_values[evade_source_idx]
			if rnd < evade_source_value:
				await target_unit.animate_evade(EvadeData.animation_ids[evade_source_idx])
				break
			rnd -= evade_source_value
	
	target_unit.update_unit_facing(target_original_facing)


func apply_standard(action_instance: ActionInstance) -> void:
	var target_units: Array[UnitData] = action_instance.get_target_units(action_instance.submitted_targets)
	
	if action_instance.allow_triggering_actions:
		for target: UnitData in target_units:
			for connection in target.targeted_pre_action.get_connections():
				await connection["callable"].call(action_instance, target)
	

	# look up animation based on weapon type and vertical angle to target
	var mod_animation_executing_id: int = animation_executing_id
	if not action_instance.submitted_targets.is_empty():
		if animation_executing_id == 0 and use_weapon_animation:
			mod_animation_executing_id = RomReader.battle_bin_data.weapon_animation_ids[action_instance.user.primary_weapon.item_type].y * 2
			var angle_to_target: float = ((action_instance.submitted_targets[0].height_mid - action_instance.user.tile_position.height_mid) 
					/ (action_instance.submitted_targets[0].location - action_instance.user.tile_position.location).length())
			if angle_to_target > 0.51:
				mod_animation_executing_id += -2
			elif angle_to_target < -0.51:
				mod_animation_executing_id += 2
	
	await action_instance.user.animate_start_action(animation_start_id, animation_charging_id)
	
	action_instance.user.animate_execute_action(mod_animation_executing_id)
	
	await action_instance.user.get_tree().create_timer(0.2).timeout # TODO delay should be based on effect/vfx data? 
	
	# TODO show vfx, including rock, arrow, bolt...
	
	var vfx_completed: bool = true
	var vfx_locations: Array[Node3D] = []
	# apply effects to targets
	for target_unit: UnitData in target_units:
		if vfx_data != null:
			#vfx_data.vfx_completed.connect(func(): vfx_completed = true, CONNECT_ONE_SHOT)
			vfx_locations.append(show_vfx(action_instance, target_unit.tile_position.get_world_position()))
		var evade_direction: EvadeData.Directions = get_evade_direction(action_instance.user, target_unit)
		var total_hit_chance: int = get_total_hit_chance(action_instance.user, target_unit, evade_direction)
		var hit_success: bool = randi_range(0, 99) < total_hit_chance
		if hit_success:
			for effect: ActionEffect in target_effects:
				var effect_value: int = roundi(effect.base_power_formula.get_result(action_instance.user, target_unit, element))
				if power_modified_by_passive:
					for status: StatusEffect in action_instance.user.current_statuses:
						effect_value = status.passive_effect.power_modifier_user.apply(effect_value)
					for status: StatusEffect in target_unit.current_statuses:
						effect_value = status.passive_effect.power_modifier_targeted.apply(effect_value)
				
				effect.apply(action_instance.user, target_unit, effect_value)
				
				if set_target_animation_on_hit and [UnitData.StatType.HP, UnitData.StatType.MP].has(effect.effect_stat_type) and effect_value < 0:
					target_unit.animate_take_hit(vfx_data)
				elif set_target_animation_on_hit and [UnitData.StatType.HP, UnitData.StatType.MP].has(effect.effect_stat_type) and effect_value > 0:
					target_unit.animate_recieve_heal(vfx_data)
			
			# apply status
			await apply_status(target_unit, target_status_list, target_status_list_type)
			
			# TODO apply secondary action
			if secondary_action_list_type == StatusListType.RANDOM:
				var sum_weights: int = 0
				for secondary_action: SecondaryAction in secondary_actions2:
					sum_weights += secondary_action.chance
				var rng: int = randi_range(0, sum_weights)
				for secondary_action: SecondaryAction in secondary_actions2:
					if rng < secondary_action.chance:
						var secondary_action_instance: ActionInstance = action_instance.duplicate()
						secondary_action_instance.action = RomReader.actions[secondary_action.action_idx]
						await secondary_action_instance.use() # TODO do not use unit animations, don't check for hit again (when using magic gun)
						break
					else:
						rng -= secondary_action.chance
		else:
			animate_evade(target_unit, evade_direction, action_instance.user.tile_position.location)
			
			target_unit.show_popup_text("Missed!") # TODO or "Guarded"
			#push_warning(action_name + " missed")
	
	# apply effects to user
	for effect: ActionEffect in user_effects:
		var effect_value: int = roundi(effect.base_power_formula.get_result(action_instance.user, action_instance.user, element))
		effect.apply(action_instance.user, action_instance.user, effect_value)
	
	# wait for applying effect animation
	action_instance.user.global_battle_manager.game_state_label.text = "Waiting for " + action_name + " vfx" 
	if vfx_data != null and target_units.size() > 0:
		while vfx_locations.any(func(vfx_location): return vfx_location != null): # wait until vfx is completed
			await action_instance.user.get_tree().process_frame
	else:
		await action_instance.user.get_tree().create_timer(0.5).timeout # TODO show based on vfx timing data? (attacks use vfx 0xFFFF?)
	for target_unit: UnitData in target_units:
		target_unit.return_to_idle_from_hit()
	vfx_locations.clear()
	
	# pay costs
	action_instance.user.mp_current -= action_instance.action.mp_cost

	if action_instance.allow_triggering_actions:
		for target: UnitData in target_units:
			for connection in target.targeted_post_action.get_connections():
				await connection["callable"].call(target, action_instance)

	action_instance.clear() # clear all highlighting and target data
	
	if ends_turn:
		action_instance.user.is_ending_turn = true
		#action_instance.user.end_turn()
	
	action_instance.action_completed.emit(action_instance.battle_manager)


func apply_status(unit: UnitData, status_list: Array[int], status_list_type: StatusListType) -> void:
	if status_list_type == StatusListType.ALL:
		var status_success: bool = randi_range(0, 99) < status_chance
		if status_success:
			for status_id: int in status_list:
				if will_remove_status and unit.current_statuses.any(func(status: StatusEffect): status.status_id == status_id):
					unit.remove_status_id(status_id)
					unit.show_popup_text(RomReader.status_effects[status_id].status_effect_name) # TODO different text for removing status
				elif not will_remove_status:
					unit.show_popup_text(RomReader.status_effects[status_id].status_effect_name)
					await unit.add_status(RomReader.status_effects[status_id].duplicate())
	elif status_list_type == StatusListType.EACH:
		for status_id: int in status_list:
			var status_success: bool = randi_range(0, 99) < status_chance
			if status_success:
				if will_remove_status and unit.current_statuses.any(func(status: StatusEffect): status.status_id == status_id):
					unit.remove_status_id(status_id)
					unit.show_popup_text(RomReader.status_effects[status_id].status_effect_name) # TODO different text for removing status
				elif not will_remove_status:
					unit.show_popup_text(RomReader.status_effects[status_id].status_effect_name)
					await unit.add_status(RomReader.status_effects[status_id].duplicate())
	elif status_list_type == StatusListType.RANDOM:
		var status_success: bool = randi_range(0, 99) < status_chance
		if status_success:
			if will_remove_status:
				var removable_status_list: Array[int] = status_list.filter(func(status_id: int): return unit.current_status_ids.has(status_id))
				if not removable_status_list.is_empty():
					var status_id: int = removable_status_list.pick_random()
					unit.remove_status_id(status_id)
					unit.show_popup_text(RomReader.status_effects[status_id].status_effect_name) # TODO different text for removing status
			elif not will_remove_status:
				var addable_status_list: Array[int] = status_list.filter(func(status_id: int): return not unit.current_status_ids.has(status_id))
				if not addable_status_list.is_empty():
					var status_id: int = addable_status_list.pick_random()
					unit.show_popup_text(RomReader.status_effects[status_id].status_effect_name)
					await unit.add_status(RomReader.status_effects[status_id].duplicate())


func show_vfx(action_instance: ActionInstance, position: Vector3) -> Node3D:
	if not is_instance_valid(vfx_data):
		return
	
	var new_vfx_location: Node3D = Node3D.new()
	new_vfx_location.position = position
	#new_vfx_location.position.y += 2 # TODO set position dependent on ability vfx data
	new_vfx_location.name = "VfxLocation"
	action_instance.user.get_parent().add_child(new_vfx_location)
	
	if not vfx_data.is_initialized:
		vfx_data.init_from_file()
	
	vfx_data.display_vfx(new_vfx_location)
	return new_vfx_location


# TODO set action type directly for each action? maybe as part of action processing per target to check values after formula processing and passive effect modifications
func get_action_types() -> Array[ActionType]:
	var action_types: Array[ActionType] = []
	
	for effect: ActionEffect in target_effects:
		if effect.type == ActionEffect.EffectType.UNIT_STAT:
			if effect.effect_stat_type == UnitData.StatType.HP:
				if effect.base_power_formula.values[0] > 0:
					action_types.append(ActionType.HP_RECOVERY)
				elif effect.base_power_formula.values[0] < 0:
					action_types.append(ActionType.HP_DAMAGE)
			if effect.effect_stat_type == UnitData.StatType.MP:
				if effect.base_power_formula.values[0] > 0:
					action_types.append(ActionType.MP_RECOVERY)
				elif effect.base_power_formula.values[0] < 0:
					action_types.append(ActionType.MP_DAMAGE)
		if not target_status_list.is_empty():
			action_types.append(ActionType.STATUS_CHANGE)
	
	return action_types


func set_data_from_formula_id(new_formula_id: int, x: int = 0, y: int = 0) -> void:
	formula_id = new_formula_id
	ignores_statuses.append_array([26, 27]) # protect and shell
	# https://ffhacktics.com/wiki/Target_XA_affecting_Statuses_(Physical)
	# https://ffhacktics.com/wiki/Target%27s_Status_Affecting_XA_(Magical)
	# https://ffhacktics.com/wiki/Evasion_Changes_due_to_Statuses
	# evade also affected by transparent, concentrate, dark or confuse, on user
	
	match formula_id:
		0, 1, 5:
			use_weapon_damage = true
			status_chance = 19
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken
			ignores_statuses.remove_at(0)
		2:
			use_weapon_damage = true
			secondary_actions.append(RomReader.abilities[inflict_status_id].ability_action)
			status_chance = 19
			secondary_actions_chances = [19]
			secondary_actions2.append(SecondaryAction.new(RomReader.abilities[inflict_status_id].ability_action.action_idx, status_chance))
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken
			ignores_statuses.remove_at(0)
		3: # weapon_power * weapon_power
			applicable_evasion = EvadeData.EvadeType.NONE
			use_weapon_damage = true
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken
			ignores_statuses.remove_at(0)
		4:
			applicable_evasion = EvadeData.EvadeType.NONE
			var secondary_action_ids: PackedInt32Array = []
			match element:
				ElementTypes.FIRE:
					secondary_action_ids = [0x10, 0x11, 0x12]
				ElementTypes.LIGHTNING:
					secondary_action_ids = [0x14, 0x15, 0x16]
				ElementTypes.ICE:
					secondary_action_ids = [0x18, 0x19, 0x1a]
			
			secondary_actions_chances = [60, 30, 10]
			secondary_action_list_type = StatusListType.RANDOM
			
			for secondary_action_idx: int in secondary_action_ids.size():
				var new_action: Action = RomReader.abilities[secondary_action_ids[secondary_action_idx]].ability_action.duplicate(true) # abilities need to be initialized before items
				new_action.area_of_effect_range = 0
				new_action.target_effects[0].base_power_formula.formula = FormulaData.Formulas.WPxV1
				new_action.mp_cost = 0
				var chance: int = secondary_actions_chances[secondary_action_idx]
				secondary_actions.append(new_action)
				secondary_actions2.append(SecondaryAction.new(new_action.action_idx, chance))
			
			# TODO damage formula is WP (instead of MA) * ability Y
			# TODO magic gun should probably use totally new Actions?, with WP*V1 formula, EvadeType.NONE, no costs, animation_ids = 0, etc., but where V1 and vfx are from the original action
			# TODO math skills, charge skills, etc. behave kind of similarly with using partial data from other actions
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken
			ignores_statuses.remove_at(1)
		6:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].transfer_to_user = true # absorb hp
			use_weapon_damage = true
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken
			ignores_statuses.remove_at(0)
		7:
			applicable_evasion = EvadeData.EvadeType.NONE
			use_weapon_damage = true
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.reverse_sign = false # heal
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken
			ignores_statuses.remove_at(0)
		8:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			status_chance = 19
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			target_effects[0].base_power_formula.values[0] = formula_y
			target_effects[0].base_power_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			target_effects[0].base_power_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken
			ignores_statuses.remove_at(1)
		9:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			status_chance = 19
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.is_modified_by_element = true
			base_hit_formula.is_modified_by_zodiac = true

			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.values[0] = formula_y / 100.0
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x0a:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.is_modified_by_element = true
			base_hit_formula.is_modified_by_zodiac = true
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x0b:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.is_modified_by_element = true
			base_hit_formula.is_modified_by_zodiac = true
		0x0c:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			target_effects[0].base_power_formula.values[0] = formula_y
			target_effects[0].base_power_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			target_effects[0].base_power_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			target_effects[0].base_power_formula.reverse_sign = false
		0x0d:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.is_modified_by_element = true
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.values[0] = formula_y / 100.0
			target_effects[0].base_power_formula.reverse_sign = false
		0x0e:
			applicable_evasion = EvadeData.EvadeType.MAGICAL # Does this use magic evade?
			
			# TODO apply status first? if target is immune to status, no damage
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.is_modified_by_element = true
			base_hit_formula.is_modified_by_zodiac = true
			
			status_chance = 100
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.values[0] = formula_y
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x0f:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.is_modified_by_element = true
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.MP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_MPxV1
			target_effects[0].base_power_formula.values[0] = formula_y / 100.0
			target_effects[0].transfer_to_user = true
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x10:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.is_modified_by_element = true
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.values[0] = formula_y / 100.0
			target_effects[0].transfer_to_user = true
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x11:
			pass
		0x12:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.is_modified_by_element = true
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.CT))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = 100
			target_effects[0].set_value = true
		0x13:
			pass
		0x14:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			# TODO set Golem
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.is_modified_by_element = true
			base_hit_formula.is_modified_by_zodiac = true
		0x15:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.is_modified_by_element = true
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.CT))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = 00
			target_effects[0].set_value = true
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x16:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.is_modified_by_element = true
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.MP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_CURRENT_MP_minus_V1
			target_effects[0].base_power_formula.values[0] = 0
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x17:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.is_modified_by_element = true
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_CURRENT_HP_minus_V1
			target_effects[0].base_power_formula.values[0] = 1
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x18, 0x19:
			pass
		0x1a:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_y
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.is_modified_by_element = true
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.PHYSICAL_ATTACK)) # TODO MAGICAL_ATTACK or SPEED dependent on ability ID?
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = formula_x
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x1b:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.is_modified_by_element = true
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.MP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_MPxV1
			target_effects[0].base_power_formula.values[0] = formula_y
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x1c:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.V1
			base_hit_formula.values[0] = formula_x
			
			# TODO song effects based on ability ID
		0x1d:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.V1
			base_hit_formula.values[0] = formula_x
			
			# TODO dance effects based on ability ID
		0x1e:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MA_plus_V1xMA_div_2
			target_effects[0].base_power_formula.values[0] = formula_y
			# TODO random number of hits within AoE
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken
			ignores_statuses.remove_at(1)
		0x1f:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MA_plus_V1xMA_div_2
			target_effects[0].base_power_formula.values[0] = formula_y
			target_effects[0].base_power_formula.user_faith_modifier = FormulaData.FaithModifier.UNFAITH
			target_effects[0].base_power_formula.target_faith_modifier = FormulaData.FaithModifier.UNFAITH
			# TODO random number of hits within AoE
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken
			ignores_statuses.remove_at(1)
		0x20:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			target_effects[0].base_power_formula.values[0] = formula_y
			# TODO chance to decrease inventory
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken
			ignores_statuses.remove_at(1)
		0x21:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.MP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			target_effects[0].base_power_formula.values[0] = formula_y
			# TODO chance to decrease inventory
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken
			ignores_statuses.remove_at(1)
		0x22:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			# TODO chance to decrease inventory
		0x23:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			target_effects[0].base_power_formula.values[0] = formula_y
			target_effects[0].base_power_formula.reverse_sign = false # heal
			# TODO chance to decrease inventory
		0x24:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PA_plus_V1xMA_div_2
			target_effects[0].base_power_formula.values[0] = formula_y
			# TODO usable based on terrain?
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken
			ignores_statuses.remove_at(1)
		0x25:
			base_hit_formula.formula = FormulaData.Formulas.PA_plus_WP_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true

			target_effects.append(ActionEffect.new(ActionEffect.EffectType.REMOVE_EQUIPMENT))
			# TODO set equipement slod id based on ability id?
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken, hit chance
			ignores_statuses.remove_at(0)
			hit_chance_modified_by_passive = true
		0x26:
			base_hit_formula.formula = FormulaData.Formulas.SP_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true

			target_effects.append(ActionEffect.new(ActionEffect.EffectType.REMOVE_EQUIPMENT))
			target_effects[0].transfer_to_user = true
			# TODO set equipement slod id based on ability id?
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken, hit chance
			ignores_statuses.remove_at(0)
			hit_chance_modified_by_passive = true
		0x27:
			base_hit_formula.formula = FormulaData.Formulas.SP_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.LVLxSPxV1
			target_effects[0].base_power_formula.values[0] = 1
			# TODO add to user currency? user_effects.append(ActionEffect.new(ActionEffect.EffectType.CURRENCY))
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken, hit chance
			ignores_statuses.remove_at(0)
			hit_chance_modified_by_passive = true
		0x28:
			base_hit_formula.formula = FormulaData.Formulas.SP_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.EXP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MIN_TARGET_EXP_or_SP_plus_V1
			target_effects[0].base_power_formula.values[0] = formula_y
			target_effects[0].transfer_to_user = true
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken, hit chance
			ignores_statuses.remove_at(0)
			hit_chance_modified_by_passive = true
		0x29:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			# TODO hit chance based on gender
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
		0x2a:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.BRAVE))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = formula_y
			target_effects[0].base_power_formula.reverse_sign = false
			# TODO set effects based on ability id
		0x2b:
			base_hit_formula.formula = FormulaData.Formulas.PA_plus_V1
			base_hit_formula.values[0] = formula_y
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.SPEED))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = formula_x
			# TODO set effects based on ability id
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken, hit chance
			ignores_statuses.remove_at(0)
			hit_chance_modified_by_passive = true
		0x2c:
			base_hit_formula.formula = FormulaData.Formulas.PA_plus_V1
			base_hit_formula.values[0] = formula_y
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.MP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = formula_y / 100.0
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken, hit chance
			ignores_statuses.remove_at(0)
			hit_chance_modified_by_passive = true
		0x2d:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxWP_plus_V1
			target_effects[0].base_power_formula.values[0] = formula_y
			
			
			status_chance = 100
			target_status_list_type = StatusListType.RANDOM
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken
			ignores_statuses.remove_at(0)
		0x2e:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxWPxV1
			target_effects[0].base_power_formula.values[0] = 1
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.REMOVE_EQUIPMENT))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = 1
			# TODO set equipement slod id based on ability id?
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken
			ignores_statuses.remove_at(0)
		0x2f:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.MP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxWPxV1
			target_effects[0].base_power_formula.values[0] = 1
			target_effects[0].transfer_to_user = true
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken
			ignores_statuses.remove_at(0)
		0x30:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxWPxV1
			target_effects[0].base_power_formula.values[0] = 1
			target_effects[0].transfer_to_user = true
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken
			ignores_statuses.remove_at(0)
		0x31:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxPA_plus_V1_div_2
			target_effects[0].base_power_formula.values[0] = formula_y
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken
			ignores_statuses.remove_at(0)
		0x32:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.RANDOM_V1xPAx3_plus_V2_div_2
			target_effects[0].base_power_formula.values[0] = formula_x
			target_effects[0].base_power_formula.values[1] = formula_y
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken
			ignores_statuses.remove_at(0)
		0x33:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.PA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
		0x34:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxV1
			target_effects[0].base_power_formula.values[0] = formula_y
			target_effects[0].base_power_formula.reverse_sign = false
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.MP))
			target_effects[1].base_power_formula.formula = FormulaData.Formulas.PAxV1
			target_effects[1].base_power_formula.values[0] = formula_y / 2.0
			target_effects[1].base_power_formula.reverse_sign = false
		0x35:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.PA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.values[0] = formula_y
			target_effects[0].base_power_formula.reverse_sign = false
		0x36:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.PHYSICAL_ATTACK))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = formula_y
			target_effects[0].base_power_formula.reverse_sign = false
		0x37:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.RANDOM_V1xPA
			target_effects[0].base_power_formula.values[0] = formula_y
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken
			ignores_statuses.remove_at(0)
		0x38:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			status_chance = 100
		0x39:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.SPEED))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = formula_y
			target_effects[0].base_power_formula.reverse_sign = false
		0x3a:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.BRAVE))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = formula_y
			target_effects[0].base_power_formula.reverse_sign = false
		0x3b:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.BRAVE))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = formula_x
			target_effects[0].base_power_formula.reverse_sign = false
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.SPEED)) # TODO set type based on ability id
			target_effects[1].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[1].base_power_formula.values[0] = formula_y
			target_effects[1].base_power_formula.reverse_sign = false
			
		0x3c:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.values[0] = 2.0 / 5.0
			target_effects[0].base_power_formula.reverse_sign = false
			
			user_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP)) # TODO this should be per target
			user_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			user_effects[0].base_power_formula.values[0] = 1.0 / 5.0
		0x3d:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x3e:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_CURRENT_HP_minus_V1
			target_effects[0].base_power_formula.values[0] = 1
		0x3f:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.SP_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken, hit chance
			ignores_statuses.remove_at(0)
			hit_chance_modified_by_passive = true
		0x40:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.SP_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
			# TODO only hit undead? or chosen status?
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken, hit chance
			ignores_statuses.remove_at(0)
			hit_chance_modified_by_passive = true
		0x41:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x42:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxV1
			target_effects[0].base_power_formula.values[0] = formula_y
			
			user_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			user_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxV1
			user_effects[0].base_power_formula.values[0] = formula_y / formula_x
		0x43:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.USER_MISSING_HPxV1
			target_effects[0].base_power_formula.values[0] = 1
		0x44:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_CURRENT_MP_minus_V1
			target_effects[0].base_power_formula.values[0] = 0
		0x45:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MISSING_HPxV1
			target_effects[0].base_power_formula.values[0] = 1
		0x46:
			pass
		0x47:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			status_chance = 100
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.values[0] = formula_y / 100.0
		0x48:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = formula_x * 10 # maybe should be handled in Item initialization?
			target_effects[0].base_power_formula.reverse_sign = false # heal
		0x49:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.MP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = formula_x * 10 # maybe should be handled in Item initialization?
			target_effects[0].base_power_formula.reverse_sign = false # heal
		0x4a:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			#target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			#target_effects[0].base_power_formula.formula = FormulaData.Formulas.UNMODIFIED
			#target_effects[0].base_power_formula.value_01 = formula_x * 10 # maybe should be handled in Item initialization?
			#target_effects[0].base_power_formula.reverse_sign = false # heal
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.values[0] = 1 # maybe should be handled in Item initialization?
			target_effects[0].base_power_formula.reverse_sign = false # heal
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.MP))
			target_effects[1].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_MPxV1
			target_effects[1].base_power_formula.values[0] = 1 # maybe should be handled in Item initialization?
			target_effects[1].base_power_formula.reverse_sign = false # heal
		0x4b:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			status_chance = 100
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.RANDOM_V1_V2
			target_effects[0].base_power_formula.values[0] = 1
			target_effects[0].base_power_formula.values[1] = 9
			target_effects[0].base_power_formula.reverse_sign = false # heal
		0x4c:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			target_effects[0].base_power_formula.values[0] = formula_y
			target_effects[0].base_power_formula.reverse_sign = false # heal
		0x4d:
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.values[0] = formula_y / 100.0
			target_effects[0].transfer_to_user = true
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken, hit chance
			ignores_statuses.remove_at(0)
			hit_chance_modified_by_passive = true
		0x4e:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			target_effects[0].base_power_formula.values[0] = formula_y
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken
			ignores_statuses.remove_at(1)
		0x4f:
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.USER_MISSING_HPxV1
			target_effects[0].base_power_formula.values[0] = 1
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken, hit chance
			ignores_statuses.remove_at(0)
			hit_chance_modified_by_passive = true
			power_modified_by_passive = false
		0x50:
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken, hit chance
			ignores_statuses.remove_at(0)
			hit_chance_modified_by_passive = true
		0x51:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_element = true # TODO only Strengthen element?
			base_hit_formula.is_modified_by_zodiac = true
		0x52:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			status_chance = 100
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.USER_MISSING_HPxV1
			target_effects[0].base_power_formula.values[0] = 1
			
			user_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			user_effects[0].base_power_formula.formula = FormulaData.Formulas.USER_CURRENT_HP_minus_V1
			user_effects[0].base_power_formula.values[0] = 0
		0x53:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.values[0] = formula_y / 100.0
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x54:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.MP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MAxV1
			target_effects[0].base_power_formula.values[0] = formula_y
			target_effects[0].base_power_formula.reverse_sign = true
		0x55:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.PHYSICAL_ATTACK))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = formula_y
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x56:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.MAGIC_ATTACK))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = formula_y
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x57:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.LEVEL))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = 1
			target_effects[0].base_power_formula.reverse_sign = false # add
		0x58:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_element = true # TODO element Strengthen only
			base_hit_formula.is_modified_by_zodiac = true
			
			# TODO set MORBOL
		0x59:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.LEVEL))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = 1
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x5a:
			status_chance = 100
			# TODO miss if target is not Dragon type
		0x5b:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			status_chance = 100
			# TODO miss if target is not Dragon type
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.TARGET_MAX_HPxV1
			target_effects[0].base_power_formula.values[0] = formula_y
		0x5c:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.BRAVE))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = formula_x
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.SPEED)) # TODO set type based on ability id
			target_effects[1].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[1].base_power_formula.values[0] = formula_y
			target_effects[1].base_power_formula.reverse_sign = false
			
			# TODO miss if target is not Dragon type
		0x5d:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.CT))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = 100
			target_effects[0].set_value = true
			
			# TODO miss if target is not Dragon type
		0x5e:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			status_chance = 19
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MA_plus_V1xMA_div_2
			target_effects[0].base_power_formula.values[0] = formula_y
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken
			ignores_statuses.remove_at(1)
			# TODO x+1 hits at random target in AoE
		0x5f:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MA_plus_V1xMA_div_2
			target_effects[0].base_power_formula.values[0] = formula_y
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken
			ignores_statuses.remove_at(1)
		0x60:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.MA_plus_V1xMA_div_2
			target_effects[0].base_power_formula.values[0] = formula_y
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken
			ignores_statuses.remove_at(1)
		0x61:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.user_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.target_faith_modifier = FormulaData.FaithModifier.FAITH
			base_hit_formula.is_modified_by_element = true
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.BRAVE))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = formula_y
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
			hit_chance_modified_by_passive = true
		0x62:
			applicable_evasion = EvadeData.EvadeType.MAGICAL
			
			base_hit_formula.formula = FormulaData.Formulas.MA_plus_V1
			base_hit_formula.values[0] = formula_x
			base_hit_formula.is_modified_by_zodiac = true
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.BRAVE))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.V1
			target_effects[0].base_power_formula.values[0] = formula_y
			
			# ignores_statuses.erase(27) # affected by shell, frog, chicken, hit chance
			ignores_statuses.remove_at(1)
		0x63:
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxWPxV1 # TODO SPxWP
			target_effects[0].base_power_formula.values[0] = 1
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken
			ignores_statuses.remove_at(0)
		0x64:
			applicable_evasion = EvadeData.EvadeType.NONE
			
			target_effects.append(ActionEffect.new(ActionEffect.EffectType.UNIT_STAT, UnitData.StatType.HP))
			target_effects[0].base_power_formula.formula = FormulaData.Formulas.PAxWPxV1
			target_effects[0].base_power_formula.values[0] = 1 # TODO 1.5 if spear, PAxBRAVE if unarmed, else 1
			
			# ignores_statuses.erase(26) # affected by protect, sleeping, charging, frog, chicken
			ignores_statuses.remove_at(0)
	
	emit_changed()

func to_json() -> String:
	var properties_to_exclude: PackedStringArray = [
		"RefCounted",
		"Resource",
		"resource_local_to_scene",
		"resource_path",
		"resource_name",
		"resource_scene_unique_id",
		"script",
	]
	return Utilities.object_properties_to_json(self, properties_to_exclude)


static func create_from_json(json_string: String) -> Action:
	var property_dict: Dictionary = JSON.parse_string(json_string)
	var new_action: Action = create_from_dictonary(property_dict)
	
	return new_action


static func create_from_dictonary(property_dict: Dictionary) -> Action:
	var new_action: Action = Action.new()
	for property_name in property_dict.keys():
		if ["target_effects", "user_effects"].has(property_name):
			var new_effects: Array[ActionEffect] = []
			for effect in property_dict[property_name]:
				var new_action_effect: ActionEffect = ActionEffect.create_from_dictionary(effect)
				new_effects.append(new_action_effect)
			new_action.set(property_name, new_effects)
		elif property_name == "base_hit_formula":
			var new_formula_data: FormulaData = FormulaData.create_from_dictionary(property_dict[property_name])
			new_action.set(property_name, new_formula_data)
		elif ["action_id", "action_idx"].has(property_name):
			if property_dict[property_name] >= 0: # auto generate action_id if < 0
				new_action.set(property_name, property_dict[property_name])
				# TODO overwrite other Action at index
		else:
			new_action.set(property_name, property_dict[property_name])

	new_action.emit_changed()
	return new_action


static func get_element_types_array(element_bitflags: PackedByteArray) -> Array[ElementTypes]:
	var elemental_types: Array[ElementTypes] = []
	
	for byte_idx: int in element_bitflags.size():
		for bit_idx: int in range(7, -1, -1):
			var byte: int = element_bitflags.decode_u8(byte_idx)
			if byte & (2 ** bit_idx) != 0:
				var element_index: int = (7 - bit_idx) + (byte_idx * 8)
				elemental_types.append(element_index)
	
	return elemental_types

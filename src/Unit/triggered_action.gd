class_name TriggeredAction
extends Resource

enum TriggerTiming {
	MOVED,
	TARGETTED_PRE_ACTION,
	TARGETTED_POST_ACTION,
	TURN_START,
	TURN_END,
}

enum TargetingTypes {
	ACTION,
	SELF,
	INITIATOR,
	MIMIC,
	REFLECT,
}

enum TriggerType {
	PHYSICAL, # Counter Grasp
	COUNTER_MAGIC,
	COUNTER_FLOOD,
	REFLECTABLE,
	MIMIC,
}

@export var name: String = "[Triggered Action]"
@export var action_idx: int = -1 # -1 is attack_action, -2 is iniating action
@export var trigger: TriggerTiming = TriggerTiming.TARGETTED_POST_ACTION
@export var targeting: TargetingTypes = TargetingTypes.SELF
@export var trigger_chance_formula: FormulaData = FormulaData.new(
	FormulaData.Formulas.BRAVExV1, [1.0],
	FormulaData.FaithModifier.NONE, FormulaData.FaithModifier.NONE, 
	false, false,
	false
)
@export var allow_triggering_actions: bool = false
@export var deduct_action_points: bool = false

# requirements to trigger - user data
@export var required_status_id: PackedInt32Array = [] # will not trigger if unit does not have any of these flags (can trigger if empty)
@export var user_stat_thresholds: Dictionary[UnitData.StatType, int] = {} # will only trigger if each of user's stat (modified_value) is >= the threshold - ex. MP >= 0

# requirements to trigger - action data
@export var only_trigger_if_usable: bool = true
@export var allow_valid_targets_only: bool = true

# requirements to trigger - initiator action data
@export var required_trigger_type: Array[TriggerType] = [] # will not trigger if action does not have any of these flags (can trigger if empty)
@export var action_mp_cost_threshold: int = 0 # will not trigger if action mp cost is not >= this value
@export var requries_hit: int = 0 # 0 - does not require anything specific, 1 - require hit, 2 - require miss, 3+ - require specific evade type? will only trigger if action successfully hit this unit
@export var required_action_type: Array[Action.ActionType] = [] # will not trigger if action does not have any of these flags
@export var action_hp_damage_threshold: int = 0 # will only trigger if HP damage caused by action is >= this value
@export var excessive_hp_recovery_threshold: int = 0 # will only trigger if HP recovered by action would exceed units max by this value


# assorted data
class TriggeredActionInstance:
	var user: UnitData
	var tiles_moved: int = 0
	var initiating_action_instance: ActionInstance


func connect_trigger(unit: UnitData) -> void:
	match trigger:
		TriggerTiming.MOVED:
			unit.completed_move.connect(moved_trigger)
		TriggerTiming.TARGETTED_PRE_ACTION:
			unit.targeted_pre_action.connect(action_trigger)
		TriggerTiming.TARGETTED_POST_ACTION:
			unit.targeted_post_action.connect(action_trigger)
		TriggerTiming.TURN_START:
			unit.turn_ended.connect(self_trigger)
		TriggerTiming.TURN_END:
			unit.turn_ended.connect(self_trigger)


func moved_trigger(user: UnitData, moved_tiles: int) -> void:	
	var new_triggered_action_data: TriggeredActionInstance = TriggeredActionInstance.new()
	new_triggered_action_data.user = user
	new_triggered_action_data.tiles_moved = moved_tiles
	await process_triggered_action(new_triggered_action_data)


func action_trigger(user: UnitData, action_instance_targeted_by: ActionInstance) -> void:
	var new_triggered_action_data: TriggeredActionInstance = TriggeredActionInstance.new()
	new_triggered_action_data.user = user
	new_triggered_action_data.initiating_action_instance = action_instance_targeted_by
	await process_triggered_action(new_triggered_action_data)


func self_trigger(user: UnitData) -> void:	
	var new_triggered_action_data: TriggeredActionInstance = TriggeredActionInstance.new()
	new_triggered_action_data.user = user
	await process_triggered_action(new_triggered_action_data)


func process_triggered_action(triggered_action_data: TriggeredActionInstance) -> void:
	var user = triggered_action_data.user
	if not Utilities.has_any_elements(user.current_status_ids, required_status_id):
		return
	
	for stat_type: UnitData.StatType in user_stat_thresholds.keys():
		if user.stats[stat_type].modified_value < user_stat_thresholds[stat_type]:
			return

	var needs_initiator: bool = (action_idx == -2
			or not required_trigger_type.is_empty()
			or action_mp_cost_threshold != 0
			or requries_hit != 0
			or not required_action_type.is_empty()
			or action_hp_damage_threshold != 0
			or excessive_hp_recovery_threshold != 0)


	var initiator_data: ActionInstance = triggered_action_data.initiating_action_instance
	var has_initiator_data: bool = initiator_data != null

	if needs_initiator:
		if not has_initiator_data:
			push_error("Trigger needs iniating action data but does not have it")
			return

		if not Utilities.has_any_elements(initiator_data.action.trigger_types, required_trigger_type):
			return
		
		if not initiator_data.action.mp_cost >= action_mp_cost_threshold:
			return
		
		# TODO store if action hit, miss, guarded?, evade type source?, element nullified?
		# if not action_instance? hit_type == requries_hit:
		# 	return

		# TODO store action types?
		if not Utilities.has_any_elements(initiator_data.action.get_action_types(), required_action_type):
			return
		
		# TODO store hp damage done
		# if action_hp_damage < action_hp_damage_threshold:
		# 	return

		# TODO check excessive hp recovered
		# if excessive_hp_recovery_threshold != 0:
		# 	var excess_hp = action_hp_recovered + user.stats[UnitData.StatType.HP].modified_value - user.stats[UnitData.StatType.HP_MAX].modified_value
		# 	if excess_hp < excessive_hp_recovery_threshold:
		# 		return
	
	var is_triggered = check_if_triggered(triggered_action_data.user, triggered_action_data.initiating_action_instance.user)
	if not is_triggered:
		return
	
	var new_action_instance: ActionInstance = get_action_instance(triggered_action_data)
	if only_trigger_if_usable:
		if not new_action_instance.is_usable():
			return

	var action_valid_targets: Array[TerrainTile] = new_action_instance.action.targeting_strategy.get_potential_targets(new_action_instance)
	if allow_valid_targets_only:
		if not action_valid_targets.has(triggered_action_data.initiating_action_instance.user.tile_position):
			return
	
	match targeting:
		TargetingTypes.ACTION:
			await new_action_instance.start_targeting() # TODO await targeting selection of triggered action
		TargetingTypes.SELF:
			var target_tile: TerrainTile = triggered_action_data.user.tile_position
			new_action_instance.submitted_targets = new_action_instance.action.targeting_strategy.get_aoe_targets(new_action_instance, target_tile)
			await new_action_instance.queue_use()
		TargetingTypes.INITIATOR:
			var target_tile: TerrainTile = triggered_action_data.initiating_action_instance.user.tile_position
			new_action_instance.submitted_targets = new_action_instance.action.targeting_strategy.get_aoe_targets(new_action_instance, target_tile)
			await new_action_instance.queue_use()
		_:
			push_warning("Invalid targeting type for triggered action: " + new_action_instance.action.action_name)


func check_if_triggered(user: UnitData, target: UnitData, element: Action.ElementTypes = Action.ElementTypes.NONE) -> bool:
	var is_triggered: bool = false
	var trigger_chance: float = trigger_chance_formula.get_result(user, target, element)
	is_triggered = randi() % 100 < trigger_chance

	return is_triggered


func get_action_instance(triggered_action_data: TriggeredActionInstance) -> ActionInstance:
	var action: Action = get_action(triggered_action_data)
	var new_action_instance: ActionInstance = ActionInstance.new(action, triggered_action_data.user, triggered_action_data.user.global_battle_manager)
	new_action_instance.allow_triggering_actions = allow_triggering_actions
	new_action_instance.deduct_action_points = deduct_action_points

	return new_action_instance


func get_action(triggered_action_data: TriggeredActionInstance) -> Action:
	var action: Action = triggered_action_data.user.attack_action
	if action_idx >=0 and action_idx < RomReader.actions.size():
		action = RomReader.actions[action_idx]
	elif action_idx == -1: # special case to use weapon attack
		action = triggered_action_data.user.attack_action
	elif action_idx == -1: # special case to use initiator action
		action = triggered_action_data.initiating_action_instance.action
	else:
		push_error("Action idx: " + str(action_idx) + " not in valid range of actions (" + str(RomReader.actions.size() - 1) + "). Using weapon attack.")
	
	return action


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

func to_csv_row(delimeter: String = "|") -> String:
	var properties_to_exclude: PackedStringArray = [
		"RefCounted",
		"Resource",
		"resource_local_to_scene",
		"resource_path",
		"resource_name",
		"resource_scene_unique_id",
		"script",
	]
	var property_dict: Dictionary = Utilities.object_properties_to_dictionary(self, properties_to_exclude)
	var entries: String = delimeter.join(property_dict.values())
	return entries


func get_csv_headers(delimeter: String = "|") -> String:
	var properties_to_exclude: PackedStringArray = [
		"RefCounted",
		"Resource",
		"resource_local_to_scene",
		"resource_path",
		"resource_name",
		"resource_scene_unique_id",
		"script",
	]
	var property_dict: Dictionary = Utilities.object_properties_to_dictionary(self, properties_to_exclude)
	var headers: String = delimeter.join(property_dict.keys())
	return headers

static func create_from_json(json_string: String) -> TriggeredAction:
	var property_dict: Dictionary = JSON.parse_string(json_string)
	var new_triggered_action: TriggeredAction = create_from_dictonary(property_dict)
	
	return new_triggered_action


static func create_from_dictonary(property_dict: Dictionary) -> TriggeredAction:
	var new_triggered_action: TriggeredAction = TriggeredAction.new()
	for property_name in property_dict.keys():
		if property_name == "trigger_chance_formula":
			var new_formula_data: FormulaData = FormulaData.create_from_dictionary(property_dict[property_name])
			new_triggered_action.set(property_name, new_formula_data)
		elif property_name == "user_stat_thresholds":
			var new_dictionary: Dictionary[UnitData.StatType, int] = {}
			var json_dict: Dictionary = property_dict[property_name]
			for key: String in json_dict.keys():
				new_dictionary[key.to_int()] = roundi(json_dict[key])
			
			new_triggered_action.set(property_name, new_dictionary)
		else:
			new_triggered_action.set(property_name, property_dict[property_name])

	new_triggered_action.emit_changed()
	return new_triggered_action

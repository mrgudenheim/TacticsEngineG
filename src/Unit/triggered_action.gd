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
}

enum TriggerType {
	NONE,
	BASIC, # Counter Grasp
	COUNTER_MAGIC,
	COUNTER_FLOOD,
	REFLECTABLE,
}

enum ActionType {
	ALL,
	HP_DAMAGE,
	HP_RECOVERY,
	MP_DAMAGE,
	MP_RECOVERY,
	STATUS_CHANGE,
}

@export var action_idx: int = -1
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

# requirements to trigger
@export var react_flags: Array[TriggerType] = [TriggerType.NONE] # will not trigger if action does not have any of these flags
@export var action_mp_cost_threshold: int = 0 # will not trigger if action mp cost is not >= this value
@export var is_hit: bool = false # will only trigger if action successfully hit this unit
@export var action_type: Array[ActionType] = [] # will not trigger if action does not have any of these flags
@export var current_status_id: PackedInt32Array = [] # will not trigger if unit does not have any of these flags
@export var only_trigger_if_usable: bool = true
@export var allow_valid_targets_only: bool = true
@export var user_mp_threshold: int = 0 # will only trigger if user's current MP is >= this value
@export var user_stat_thresholds: Dictionary[UnitData.StatType, int] = {} # will only trigger if each of user's stat (modified_value) is >= the threshold - ex. MP >= 0
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
			unit.targeted_pre_action.connect(targetted_trigger)
		TriggerTiming.TARGETTED_POST_ACTION:
			unit.targeted_post_action.connect(targetted_trigger)
		TriggerTiming.TURN_START:
			unit.turn_ended.connect(turn_trigger)
		TriggerTiming.TURN_END:
			unit.turn_ended.connect(turn_trigger)


func moved_trigger(user: UnitData, moved_tiles: int) -> void:	
	var new_triggered_action_data: TriggeredActionInstance = TriggeredActionInstance.new()
	new_triggered_action_data.user = user
	new_triggered_action_data.tiles_moved = moved_tiles
	await process_triggered_action(new_triggered_action_data)


func targetted_trigger(user: UnitData, action_instance_targeted_by: ActionInstance) -> void:
	var new_triggered_action_data: TriggeredActionInstance = TriggeredActionInstance.new()
	new_triggered_action_data.user = user
	new_triggered_action_data.initiating_action_instance = action_instance_targeted_by
	await process_triggered_action(new_triggered_action_data)


func turn_trigger(user: UnitData) -> void:	
	var new_triggered_action_data: TriggeredActionInstance = TriggeredActionInstance.new()
	new_triggered_action_data.user = user
	await process_triggered_action(new_triggered_action_data)


func process_triggered_action(triggered_action_data: TriggeredActionInstance) -> void:
	var is_triggered = check_if_triggered(triggered_action_data.user, triggered_action_data.initiating_action_instance.user)
	if not is_triggered:
		return
	
	var new_action_instance: ActionInstance = get_action_instance(triggered_action_data.user)
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
			push_warning("Invalid targeting type for triggered: " + new_action_instance.action.action_name)
	
	await new_action_instance.queue_use()

func check_if_triggered(user: UnitData, target: UnitData, element: Action.ElementTypes = Action.ElementTypes.NONE) -> bool:
	var is_triggered: bool = false
	var trigger_chance: float = trigger_chance_formula.get_result(user, target, element)
	is_triggered = randi() % 100 < trigger_chance

	return is_triggered


func get_action_instance(user: UnitData) -> ActionInstance:
	var action: Action = get_action(user)
	var new_action_instance: ActionInstance = ActionInstance.new(action, user, user.global_battle_manager)
	new_action_instance.allow_triggering_actions = allow_triggering_actions
	new_action_instance.deduct_action_points = deduct_action_points

	return new_action_instance


func get_action(user: UnitData) -> Action:
	var action: Action = user.attack_action
	if action_idx >=0 and action_idx < RomReader.actions.size():
		action = RomReader.actions[action_idx]
	elif action_idx == -1: # special case to use weapon attack
		action = user.attack_action
	else:
		push_error("Action idx: " + str(action_idx) + " not in valid range of actions (" + str(RomReader.actions.size() - 1) + "). Using weapon attack.")
	
	return action

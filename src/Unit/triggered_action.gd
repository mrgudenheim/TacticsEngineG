class_name TriggeredAction
extends Resource

enum TriggerTiming {
	MOVED,
	TARGETTED_PRE_ACTION,
	TARGETTED_POST_ACTION,
	LOST_HP,
	STATUS_CHANGED,
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
@export var action_hp_damage_threshold: int = 0 # will only trigger if HP damage caused by action is >= this value
@export var excessive_hp_recovery_threshold: int = 0 # will only trigger if HP recovered by action would exceed units max by this value

func connect_trigger(unit: UnitData) -> void:
	match trigger:
		TriggerTiming.MOVED:
			unit.completed_move.connect(move_trigger_action)
		TriggerTiming.TARGETTED_PRE_ACTION:
			unit.targeted_pre_action.connect(targetted_trigger_action)
		TriggerTiming.TARGETTED_POST_ACTION:
			unit.targeted_post_action.connect(targetted_trigger_action)
		TriggerTiming.LOST_HP:
			unit.completed_move.connect(move_trigger_action)
		TriggerTiming.STATUS_CHANGED:
			unit.completed_move.connect(move_trigger_action)


func move_trigger_action(user: UnitData, moved_tiles: int) -> void:	
	var is_triggered = check_if_triggered(user, user)
	if not is_triggered:
		return
	
	var new_action_instance: ActionInstance = get_action_instance(user)
	if only_trigger_if_usable:
		if not new_action_instance.is_usable():
			return

	# TODO allow targeting other than self
	new_action_instance.submitted_targets = new_action_instance.action.targeting_strategy.get_aoe_targets(new_action_instance, user.tile_position)
	
	await new_action_instance.queue_use()


func targetted_trigger_action(user: UnitData, action_instance_targeted_by: ActionInstance) -> void:
	var is_triggered = check_if_triggered(user, action_instance_targeted_by.user)
	if not is_triggered:
		return
	
	var new_action_instance: ActionInstance = get_action_instance(user)
	if not new_action_instance.is_usable():
			return

	var action_valid_targets: Array[TerrainTile] = new_action_instance.action.targeting_strategy.get_potential_targets(new_action_instance)
	if allow_valid_targets_only:
		if not action_valid_targets.has(action_instance_targeted_by.user.tile_position):
			return
	# TODO allow targeting other than attacker
	new_action_instance.submitted_targets = new_action_instance.action.targeting_strategy.get_aoe_targets(new_action_instance, action_instance_targeted_by.user.tile_position)
	
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

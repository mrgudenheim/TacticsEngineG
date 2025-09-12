class_name TriggeredAction
extends Resource

enum TriggerType {
	MOVED,
	TARGETTED_PRE_ACTION,
	TARGETTED_POST_ACTION,
	LOST_HP,
	STATUS_CHANGED,
}

@export var action_idx: int = -1
@export var trigger: TriggerType = TriggerType.TARGETTED_POST_ACTION
@export var trigger_chance_formula: FormulaData = FormulaData.new(
	FormulaData.Formulas.BRAVExV1, [1.0],
	FormulaData.FaithModifier.NONE, FormulaData.FaithModifier.NONE, 
	false, false,
	false
)
@export var allow_triggering_actions: bool = false
@export var deduct_action_points: bool = false
@export var allow_valid_targets_only: bool = true


func connect_trigger(unit: UnitData) -> void:
	match trigger:
		TriggerType.MOVED:
			unit.completed_move.connect(move_trigger_action)
		TriggerType.TARGETTED_PRE_ACTION:
			unit.targeted_pre_action.connect(targetted_trigger_action)
		TriggerType.TARGETTED_POST_ACTION:
			unit.targeted_post_action.connect(targetted_trigger_action)
		TriggerType.LOST_HP:
			unit.completed_move.connect(move_trigger_action)
		TriggerType.STATUS_CHANGED:
			unit.completed_move.connect(move_trigger_action)


func move_trigger_action(user: UnitData, moved_tiles: int) -> void:
	var is_triggered = check_if_triggered(user, user)
	if not is_triggered:
		return
	
	var new_action_instance: ActionInstance = get_action_instance(user)
	# TODO allow targeting other than self
	new_action_instance.submitted_targets = new_action_instance.action.targeting_strategy.get_aoe_targets(new_action_instance, user.tile_position)
	
	await new_action_instance.queue_use()


func targetted_trigger_action(user: UnitData, action_instance_targeted_by: ActionInstance) -> void:
	var is_triggered = check_if_triggered(user, action_instance_targeted_by.user)
	if not is_triggered:
		return
	
	var new_action_instance: ActionInstance = get_action_instance(user)
	
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

#https://ffhacktics.com/wiki/BATTLE.BIN_Routines#AI_Calculations

#https://ffhacktics.com/wiki/AI_Ability_Use_Decisions
#https://ffhacktics.com/wiki/Evaluate_Cancel_Status_Ability_(0019881c)
#https://ffhacktics.com/wiki/Find_Peril_Most_Unit_(00198b04)

class_name UnitAi
extends Resource

var wait_action_instance: ActionInstance
@export var strategy: Strategy = Strategy.END_TURN
var only_end_activation: bool = true
var choose_random_action: bool = false
var choose_best_action: bool = false

@export var action_delay: float = 0.5

var action_eval_data: Array = []

enum Strategy {
	END_TURN,
	RANDOM,
	BEST,
}

func choose_action(unit: UnitData) -> void:
	wait_action_instance = unit.actions_data[unit.wait_action]
	
	if strategy == Strategy.END_TURN:
		await wait_for_delay(unit)
		wait_action_instance.start_targeting()
		await wait_action_instance.action_completed
		return
	
	var eligible_actions: Array[ActionInstance] = unit.actions_data.values().filter(func(action_instance: ActionInstance): return action_instance.is_usable() and not action_instance.potential_targets.is_empty())
	if eligible_actions.size() > 1:
		eligible_actions.erase(wait_action_instance) # don't choose to wait if another action is eligible
	else:
		await wait_for_delay(unit)
		wait_action_instance.start_targeting()
		await wait_action_instance.action_completed
		return
	
	if strategy == Strategy.RANDOM:
		var chosen_action: ActionInstance = eligible_actions.pick_random()
		chosen_action.show_potential_targets() # TODO fix move targeting when updating paths/pathfinding is takes longer than delay (large maps with 10+ units)
		chosen_action.start_targeting()
		if chosen_action.action.auto_target:
			await chosen_action.action_completed
		else:
			await wait_for_delay(unit)
			var random_target: TerrainTile = chosen_action.potential_targets.pick_random()
			var simulated_input: InputEvent = InputEventMouseMotion.new()
			chosen_action.tile_hovered.emit(random_target, chosen_action, simulated_input)
			await wait_for_delay(unit)
			var simulated_input_action: InputEventAction = InputEventAction.new()
			simulated_input_action.action = "primary_action"
			simulated_input_action.pressed = true
			chosen_action.tile_hovered.emit(random_target, chosen_action, simulated_input_action)
		
		
		pass # TODO implement ai choosing random action
	elif strategy == Strategy.BEST:
		pass # TODO implement ai choosing 'best' action


func wait_for_delay(unit: UnitData) -> void:
	await unit.get_tree().create_timer(action_delay).timeout

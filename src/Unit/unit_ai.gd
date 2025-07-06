#https://ffhacktics.com/wiki/BATTLE.BIN_Routines#AI_Calculations

#https://ffhacktics.com/wiki/AI_Ability_Use_Decisions
#https://ffhacktics.com/wiki/Evaluate_Cancel_Status_Ability_(0019881c)
#https://ffhacktics.com/wiki/Find_Peril_Most_Unit_(00198b04)

class_name UnitAi
extends Resource

var wait_action_instance: ActionInstance
var strategy: Strategy = Strategy.END_TURN
var only_end_activation: bool = true
var choose_random_action: bool = false
var choose_best_action: bool = false

var action_delay: float = 2.0

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
	
	var eligible_actions: Array[ActionInstance] = unit.actions_data.keys().filter(func(action_instance: ActionInstance): return action_instance.is_usable())
	if eligible_actions.size() > 1:
		eligible_actions.erase(wait_action_instance) # don't choose to wait if another action is eligible
	else:
		await wait_for_delay(unit)
		wait_action_instance.start_targeting()
		await wait_action_instance.action_completed
		return
	
	if strategy == Strategy.RANDOM:
		pass # TODO implement ai choosing random action
	elif strategy == Strategy.BEST:
		pass # TODO implement ai choosing 'best' action


func wait_for_delay(unit: UnitData) -> void:
	await unit.get_tree().create_timer(action_delay)

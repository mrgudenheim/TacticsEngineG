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
	
	if not unit.paths_set:
		await unit.paths_updated
	
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
		await action_random_target(unit, chosen_action)
	elif strategy == Strategy.BEST: # TODO implement better ai choosing 'best' action
		var non_move_actions: Array[ActionInstance] = eligible_actions.duplicate()
		non_move_actions.remove_at(0) # TODO evaluate move separately
		
		var move_action_instance: ActionInstance = unit.actions_data[unit.move_action]
		if move_action_instance.is_usable() and not move_action_instance.potential_targets.is_empty():
			await action_random_target(unit, move_action_instance)
			return
		
		var best_action: ActionInstance
		var best_target: TerrainTile
		var best_ai_score: int = 0
		
		var simulated_input: InputEvent = InputEventMouseMotion.new()
		var action_best_targets: Dictionary[ActionInstance, TerrainTile] = {}
		var action_scores: Dictionary[ActionInstance, int] = {}
		for action_instance: ActionInstance in non_move_actions:
			for potential_target: TerrainTile in action_instance.potential_targets: # TODO handle ai score for auto targeting
				#action_instance.tile_hovered.emit(potential_target, action_instance, simulated_input) # set preview targets
				action_instance.action.targeting_strategy.target_tile(potential_target, action_instance, simulated_input)
				var potential_ai_score: int = action_instance.get_ai_score()
				
				if potential_ai_score > best_ai_score:
					best_ai_score = potential_ai_score
					best_action = action_instance
					best_target = potential_target
				
				if action_scores.keys().has(action_instance):
					if action_scores[action_instance] < potential_ai_score:
						action_scores[action_instance] = potential_ai_score
						action_best_targets[action_instance] = potential_target
				else:
					action_best_targets[action_instance] = potential_target
					action_scores[action_instance] = potential_ai_score
			
			action_instance.stop_targeting()
		
		if best_action == null:
			wait_action_instance.start_targeting()
			await wait_action_instance.action_completed
		else:
			var chosen_action: ActionInstance = best_action
			#chosen_action.show_potential_targets() # TODO fix move targeting when updating paths/pathfinding is takes longer than delay (large maps with 10+ units)
			chosen_action.start_targeting()
			if chosen_action.action.auto_target:
				await chosen_action.action_completed
			else:
				await wait_for_delay(unit)
				chosen_action.tile_hovered.emit(best_target, chosen_action, simulated_input)
				await wait_for_delay(unit)
				if not chosen_action.preview_targets.is_empty(): # TODO fix why move does not have targets sometimes
					var simulated_input_action: InputEventAction = InputEventAction.new()
					simulated_input_action.action = "primary_action"
					simulated_input_action.pressed = true
					chosen_action.tile_hovered.emit(best_target, chosen_action, simulated_input_action)
				else: # wait if no targets
					chosen_action.stop_targeting()
					wait_action_instance.start_targeting()
					await wait_action_instance.action_completed


func action_random_target(unit: UnitData, chosen_action: ActionInstance) -> void:
	#chosen_action.show_potential_targets() # TODO fix move targeting when updating paths/pathfinding is takes longer than delay (large maps with 10+ units)
	chosen_action.start_targeting()
	if chosen_action.action.auto_target:
		await chosen_action.action_completed
	else:
		await wait_for_delay(unit)
		var random_target: TerrainTile = chosen_action.potential_targets.pick_random()
		var simulated_input: InputEvent = InputEventMouseMotion.new()
		chosen_action.tile_hovered.emit(random_target, chosen_action, simulated_input)
		await wait_for_delay(unit)
		if not chosen_action.preview_targets.is_empty(): # TODO fix why move does not have targets sometimes
			var simulated_input_action: InputEventAction = InputEventAction.new()
			simulated_input_action.action = "primary_action"
			simulated_input_action.pressed = true
			chosen_action.tile_hovered.emit(random_target, chosen_action, simulated_input_action)
		else: # wait if no targets
			chosen_action.stop_targeting()
			wait_action_instance.start_targeting()
			await wait_action_instance.action_completed


func wait_for_delay(unit: UnitData) -> void:
	await unit.get_tree().create_timer(action_delay).timeout

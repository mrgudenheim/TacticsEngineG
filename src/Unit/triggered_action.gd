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
    false, false
)


func connect_trigger(unit: UnitData) -> void:
    match trigger:
        TriggerType.MOVED:
            unit.completed_move.connect(move_trigger_action)
        TriggerType.TARGETTED_PRE_ACTION:
            unit.completed_move.connect(move_trigger_action)
        TriggerType.TARGETTED_POST_ACTION:
            unit.completed_move.connect(move_trigger_action)
        TriggerType.LOST_HP:
            unit.completed_move.connect(move_trigger_action)
        TriggerType.STATUS_CHANGED:
            unit.completed_move.connect(move_trigger_action)


func move_trigger_action(user: UnitData, moved_tiles: int) -> void:
    var is_triggered = check_if_triggered(user, user)
    if not is_triggered:
        return
    
    var new_action_instance: ActionInstance = ActionInstance.new(RomReader.actions[action_idx], user, user.global_battle_manager)
    new_action_instance.submitted_targets = [user.tile_position]
    
    await new_action_instance.use()


func check_if_triggered(user: UnitData, target: UnitData, element: Action.ElementTypes = Action.ElementTypes.NONE) -> bool:
    var is_triggered: bool = false
    var trigger_chance: float = trigger_chance_formula.get_result(user, target, element)
    is_triggered = randi() % 100 < trigger_chance

    return is_triggered
class_name TriggeredAction
extends Resource

@export var action_idx: int = -1
@export var trigger: TriggerType = TriggerType.TARGETTED_POST_ACTION

enum TriggerType {
    MOVED,
    TARGETTED_PRE_ACTION,
    TARGETTED_POST_ACTION,
    LOST_HP,
    STATUS_CHANGED,
}


func connect_trigger(unit: UnitData) -> void:
    match trigger:
        TriggerType.MOVED:
            unit.completed_move.connect(move_trigger_action)


func move_trigger_action(unit: UnitData, moved_tiles: int) -> void:
    var new_action_instance: ActionInstance = ActionInstance.new(RomReader.actions[action_idx], unit, unit.global_battle_manager)
    new_action_instance.submitted_targets = [unit.tile_position]
    
    new_action_instance.use()
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


func connect_trigger() -> void:
    pass

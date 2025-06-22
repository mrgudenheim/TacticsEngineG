class_name ActionPreview
extends Control

@export var label: Label
@export var unit: UnitData

func _process(delta: float) -> void:
	if is_instance_valid(BattleManager.main_camera):
		var camera_right: Vector3 = BattleManager.main_camera.basis * Vector3.RIGHT
		position = BattleManager.main_camera.unproject_position(unit.char_body.position + (Vector3.UP * 1.0) + (camera_right * 0.0))

class_name UnitUi
extends Control

@export var unit: UnitData
@export var unit_char_body: CharacterBody3D
@export var offset: Vector2 = Vector2.DOWN

func _process(delta: float) -> void:
	if is_instance_valid(BattleManager.main_camera):
		var camera_right: Vector3 = BattleManager.main_camera.basis * Vector3.RIGHT
		position = BattleManager.main_camera.unproject_position(unit_char_body.position + (Vector3.UP * offset.y) + (camera_right * offset.x))

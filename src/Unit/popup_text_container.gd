class_name PopupTextContainer
extends Control

@export var popup_text: PackedScene

@export var unit: UnitData
@export var unit_char_body: CharacterBody3D
@export var fade_time: float = 2.0

func _process(delta: float) -> void:
	if is_instance_valid(BattleManager.main_camera):
		var camera_right: Vector3 = BattleManager.main_camera.basis * Vector3.RIGHT
		get_parent_control().position = BattleManager.main_camera.unproject_position(unit_char_body.position + (Vector3.UP * 1.0) + (camera_right * 0.0))


func show_popup_text(text: String) -> void:
	var new_text: Label = popup_text.instantiate()
	new_text.text = text
	add_child(new_text)
	
	await get_tree().create_timer(fade_time).timeout.connect(func(): new_text.queue_free())

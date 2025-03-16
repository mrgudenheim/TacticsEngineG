class_name PreviewSubViewportContainer
extends SubViewportContainer

@export var camera_control: ViewportControl
@export var subviewport: SubViewport

func _on_mouse_entered() -> void:
	camera_control.set_process_input(true)


func _on_mouse_exited() -> void:
	camera_control.set_process_input(false)

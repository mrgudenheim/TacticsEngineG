extends TextureRect

@export var camera_controller: SubviewportCamera3dController
#@export var subviewport: SubViewport


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	camera_controller.set_process_input(true)


func _on_mouse_exited() -> void:
	camera_controller.set_process_input(false)

extends TextureRect

@export var camera: Camera3D
#@export var subviewport: SubViewport
var pan_speed: float = 1

var zoom_in_max: int = 0.25
var zoom_out_max: int = 10

var is_dragging: bool = false

var pan_bounds_x: Vector2 = Vector2(-4.5, 4.5)
var pan_bounds_y: Vector2 = Vector2(-4.5, 4.5)


func _input(event: InputEvent) -> void:
	push_warning(event)
	
	if event.is_action_pressed(&"pan"):
		is_dragging = true
	elif event.is_action_released(&"pan"):
		is_dragging = false
	elif event.is_action_pressed(&"zoom_in", false, true):  # Wheel Up Event
		zoom_camera(1)
	elif event.is_action_pressed(&"zoom_out", false, true):  # Wheel Down Event
		zoom_camera(-1)
	
	# pan camera
	if event is InputEventMouseMotion:
		if is_dragging:
			camera.position.x += -event.relative.x * camera.size * pan_speed * get_process_delta_time() * 0.3
			camera.position.y += event.relative.y * camera.size * pan_speed * get_process_delta_time() * 0.3
	else:
		var dir := Input.get_vector(&"camera_left", &"camera_right", &"camera_up", &"camera_down")
		if dir != Vector2.ZERO: # and !_has_selection_tool():
			camera.position.x += dir.x * camera.size * pan_speed * get_process_delta_time()
			camera.position.y += -dir.y * camera.size * pan_speed * get_process_delta_time()
	
	camera.position.x = clamp(camera.position.x, pan_bounds_x.x, pan_bounds_x.y)
	camera.position.y = clamp(camera.position.y, pan_bounds_y.x, pan_bounds_y.y)


func zoom_camera(dir: float) -> void:
	var zoom_margin: float = camera.size * (-dir / 5)
	var new_size: float = camera.size + zoom_margin
	if new_size > zoom_in_max && new_size < zoom_out_max:
		var tween := create_tween().set_parallel()
		tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		tween.tween_property(camera, "size", new_size, 0.05)
		#tween.tween_property(self, "offset", new_offset, 0.05)


func reset() -> void:
	camera.position = Vector3(0, 0.5, 2.5)
	camera.size = 2

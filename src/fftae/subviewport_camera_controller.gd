extends TextureRect

@export var camera: Camera3D
#@export var subviewport: SubViewport
var pan_speed: float = 1

var zoom_in_max: int = 0.25
var zoom_out_max: int = 10

var is_dragging: bool = false

var pan_distance_max: float = 4.5

var pan_bounds_min: Vector3
var pan_bounds_max: Vector3


func _ready() -> void:
	mouse_entered.connect(_on_mouse_enter)
	mouse_exited.connect(_on_mouse_exit)
	
	set_process_input(false)
	
	var pan_length: float = pan_distance_max * sqrt(2)/2
	pan_bounds_min = Vector3(2.5 - pan_length, -pan_distance_max, 2.5 - pan_length)
	pan_bounds_max = Vector3(2.5 + pan_length, pan_distance_max, 2.5 + pan_length)


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
			var dir: Vector2 = event.relative * camera.size * pan_speed * get_process_delta_time() * 0.3
			camera.translate_object_local(Vector3(-dir.x, dir.y, 0))
	else:
		var dir := Input.get_vector(&"camera_left", &"camera_right", &"camera_up", &"camera_down")
		if dir != Vector2.ZERO:
			dir = dir  * camera.size * pan_speed * get_process_delta_time()
			camera.translate_object_local(Vector3(dir.x, -dir.y, 0))
	
	camera.position = camera.position.clamp(pan_bounds_min, pan_bounds_max)


func _on_mouse_enter() -> void:
	set_process_input(true)


func _on_mouse_exit() -> void:
	set_process_input(false)
	is_dragging = false


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

extends Node2D

@export var sprite: Sprite2D

signal zoom_changed
signal offset_changed

const CAMERA_SPEED_RATE := 15.0

var smooth_zoom: bool = true
var integer_zoom: bool = true

var zoom := Vector2(3, 3):
	set(value):
		zoom = value
		zoom_changed.emit()
		_update_viewport_transform()
var camera_angle := 0.0
var offset := Vector2.ZERO:
	set(value):
		offset = value
		offset_changed.emit()
		_update_viewport_transform()
var camera_screen_center := Vector2.ZERO
var zoom_in_max := Vector2(500, 500)
var zoom_out_max := Vector2(0.01, 0.01)
var viewport_container: SubViewportContainer
#var transparent_checker: ColorRect
var mouse_pos := Vector2.ZERO
var drag := false
#var rotation_slider: ValueSlider
#var zoom_slider: ValueSlider
var should_tween := true

@onready var viewport := get_viewport()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	viewport.size_changed.connect(_update_viewport_transform)
	#Global.project_switched.connect(_project_switched)
	if not DisplayServer.is_touchscreen_available():
		set_process_input(false)
	#if index == Cameras.MAIN:
		#rotation_slider = Global.top_menu_container.get_node("%RotationSlider")
		#rotation_slider.value_changed.connect(_rotation_slider_value_changed)
		#zoom_slider = Global.top_menu_container.get_node("%ZoomSlider")
		#zoom_slider.value_changed.connect(_zoom_slider_value_changed)
	#zoom_changed.connect(_zoom_changed)
	#rotation_changed.connect(_rotation_changed)
	viewport_container = get_parent().get_parent()
	#transparent_checker = get_parent().get_node("TransparentChecker")
	#update_transparent_checker_offset()


func _input(event: InputEvent) -> void:
	get_window().gui_release_focus()
	#print(str(event) + ": input over custom panel")
	#if !global.can_draw:
		#drag = false
		#return
	mouse_pos = viewport_container.get_local_mouse_position()
	if event.is_action_pressed(&"pan"):
		drag = true
	elif event.is_action_released(&"pan"):
		drag = false
	elif event.is_action_pressed(&"zoom_in", false, true):  # Wheel Up Event
		zoom_camera(1)
	elif event.is_action_pressed(&"zoom_out", false, true):  # Wheel Down Event
		zoom_camera(-1)

	elif event is InputEventMagnifyGesture:  # Zoom gesture on touchscreens
		if event.factor >= 1:  # Zoom in
			zoom_camera(1)
		else:  # Zoom out
			zoom_camera(-1)
	elif event is InputEventPanGesture:
		# Pan gesture on touchscreens
		offset = offset + event.delta.rotated(camera_angle) * 7.0 / zoom
	elif event is InputEventMouseMotion:
		if drag:
			offset = offset - event.relative.rotated(camera_angle) / zoom
	else:
		var dir := Input.get_vector(&"camera_left", &"camera_right", &"camera_up", &"camera_down")
		if dir != Vector2.ZERO: # and !_has_selection_tool():
			offset += (dir.rotated(camera_angle) / zoom) * CAMERA_SPEED_RATE


func zoom_camera(dir: int) -> void:
	var viewport_size := viewport_container.size
	if smooth_zoom:
		var zoom_margin := zoom * dir / 5
		var new_zoom := zoom + zoom_margin
		if integer_zoom:
			new_zoom = (zoom + Vector2.ONE * dir).floor()
		if new_zoom < zoom_in_max && new_zoom > zoom_out_max:
			var new_offset := (
				offset
				+ (
					(-0.5 * viewport_size + mouse_pos).rotated(camera_angle)
					* (Vector2.ONE / zoom - Vector2.ONE / new_zoom)
				)
			)
			var tween := create_tween().set_parallel()
			tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
			tween.tween_property(self, "zoom", new_zoom, 0.05)
			tween.tween_property(self, "offset", new_offset, 0.05)
	else:
		var prev_zoom := zoom
		var zoom_margin := zoom * dir / 10
		if integer_zoom:
			zoom_margin = (Vector2.ONE * dir).floor()
		if zoom + zoom_margin <= zoom_in_max:
			zoom += zoom_margin
		if zoom < zoom_out_max:
			if integer_zoom:
				zoom = Vector2.ONE
			else:
				zoom = zoom_out_max
		offset = (
			offset
			+ (
				(-0.5 * viewport_size + mouse_pos).rotated(camera_angle)
				* (Vector2.ONE / prev_zoom - Vector2.ONE / zoom)
			)
		)


func zoom_100() -> void:
	zoom = Vector2.ONE
	#offset = current_project.size / 2


## Updates the viewport's canvas transform, which is the area of the canvas that is
## currently visible. Called every time the camera's zoom, rotation or origin changes.
func _update_viewport_transform() -> void:
	if not is_instance_valid(viewport):
		return
	var zoom_scale := Vector2.ONE / zoom
	var viewport_size := get_viewport_rect().size
	var screen_offset := viewport_size * 0.5 * zoom_scale
	screen_offset = screen_offset.rotated(camera_angle)
	var screen_rect := Rect2(-screen_offset, viewport_size * zoom_scale)
	
	if not is_instance_valid(sprite.texture):
		return
	
	# limit viewport to relevant area
	var sprite_size: Vector2i = sprite.texture.get_size()
	var factor := 2 # 2 limits center of camera to edge of sprite. smaller gives a little margin 
	if (offset.x > sprite_size.x / factor):
		offset.x = sprite_size.x  / factor
	elif (offset.x < -sprite_size.x / factor):
		offset.x = -sprite_size.x / factor
	if (offset.y > sprite_size.y / factor):
		offset.y = sprite_size.y / factor
	elif (offset.y < -sprite_size.y / factor):
		offset.y = -sprite_size.y / factor
		#screen_rect.position = Vector2i(sprite.texture.get_size().x, screen_rect.position.y)	
	
	screen_rect.position += offset
	
	#print(screen_rect.position)
	var xform := Transform2D(camera_angle, zoom_scale, 0, screen_rect.position)
	camera_screen_center = xform * (viewport_size * 0.5)
	viewport.canvas_transform = xform.affine_inverse()

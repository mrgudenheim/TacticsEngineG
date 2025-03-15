class_name UnitControllerRT
extends Node3D

signal velocity_set(direction: Vector3)
signal camera_facing_changed()

const SPEED: float = 5.0

const ROTATE_INTERVAL: float = 90.0 # degrees
const ROTATE_SPEED: float = 300.0 # degrees / sec
#const ROTATION_DURATION: float = 0.1 # seconds
const JUMP_VELOCITY: float = 4.5

enum Directions {
	NORTHWEST,
	NORTHEAST,
	SOUTHWEST,
	SOUTHEAST,
	}

const CameraFacingVectors: Dictionary[Directions, Vector3] = {
	Directions.NORTHWEST: Vector3.LEFT + Vector3.FORWARD,
	Directions.NORTHEAST: Vector3.RIGHT + Vector3.FORWARD,
	Directions.SOUTHWEST: Vector3.LEFT + Vector3.BACK,
	Directions.SOUTHEAST: Vector3.RIGHT + Vector3.BACK,
	}


var is_rotating: bool = false
var unit: UnitData

@export var phantom_camera: PhantomCamera3D
static var camera_facing: Directions = Directions.NORTHWEST


func _physics_process(delta: float) -> void:
	if not is_instance_valid(unit):
		return
	
	# Add the gravity.
	if not unit.char_body.is_on_floor():
		unit.char_body.velocity += unit.char_body.get_gravity() * delta
	
	if not unit.can_move:
		return
	
	if MapViewer.main_camera.get_viewport().is_input_handled() == true:
		return
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	var direction := (unit.char_body.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		unit.char_body.velocity.x = direction.x * SPEED
		unit.char_body.velocity.z = direction.z * SPEED
	else:
		unit.char_body.velocity.x = move_toward(unit.char_body.velocity.x, 0, SPEED)
		unit.char_body.velocity.z = move_toward(unit.char_body.velocity.z, 0, SPEED)
	
	if unit.char_body.velocity * Vector3(1, 0, 1) != Vector3.ZERO:
		velocity_set.emit(direction)
	unit.char_body.move_and_slide()
	
	if Input.is_action_just_pressed("secondary_action") and unit.char_body.is_on_floor():
		# https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html
		# get 3d click location based on raycast
		var space_state := get_world_3d().direct_space_state
		var cam: Camera3D = MapViewer.main_camera
		var mousepos: Vector2 = get_viewport().get_mouse_position()

		var origin: Vector3 = cam.project_ray_origin(mousepos)
		var end: Vector3 = origin + cam.project_ray_normal(mousepos) * 1000
		var query := PhysicsRayQueryParameters3D.create(origin, end)
		#query.collide_with_areas = true

		var result: Dictionary = space_state.intersect_ray(query)
		if not result.is_empty():
			unit.use_ability(result["position"])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"camera_rotate_left", true):
		rotate_camera(-1)
	elif event.is_action_pressed(&"camera_rotate_right", true):
		rotate_camera(1)
	# Handle jump
	elif Input.is_action_just_pressed("ui_accept") and unit.char_body.is_on_floor() and unit.can_move:
		unit.char_body.velocity.y = JUMP_VELOCITY
	#elif Input.is_action_just_pressed("primary_action") and is_on_floor() and unit.can_move:
		#push_warning("primary_action_clicked")
		#unit.use_ability()


func rotate_camera(dir: int) -> void:
	if is_rotating:
		return
	
	is_rotating = true
	var new_rotation: Vector3 = Vector3.ZERO
	var offset: float = dir * ROTATE_INTERVAL
	
	var new_x = unit.char_body.rotation_degrees.x
	var new_y = roundi(unit.char_body.rotation_degrees.y) + offset
	var new_z = unit.char_body.rotation_degrees.z
	#unit.char_body.rotation_degrees = Vector3(new_x, new_y, new_z)
	
	new_rotation = Vector3(-26.54, new_y, new_z)
	var tween: Tween = create_tween()
	tween.tween_method(rotate_phantom_camera, MapViewer.main_camera.rotation_degrees, new_rotation, ROTATE_INTERVAL / ROTATE_SPEED)
	await tween.finished
	
	push_warning(str(camera_facing))
	is_rotating = false


func rotate_phantom_camera(new_rotation_degress: Vector3) -> void:
	phantom_camera.set_third_person_rotation_degrees(new_rotation_degress)
	unit.char_body.rotation_degrees = Vector3(0, new_rotation_degress.y, 0)
	
	var camera_angle: float = MapViewer.main_camera.rotation_degrees.y
	#var target_angle = fposmod(new_rotation_degress.y, 360)
	var camera_angle_pos = fposmod(camera_angle, 360)
		
	var new_camera_facing: Directions = Directions.NORTHEAST
	if camera_angle_pos < 90:
		new_camera_facing = Directions.NORTHWEST
	elif camera_angle_pos < 180:
		new_camera_facing = Directions.SOUTHWEST
	elif camera_angle_pos < 270:
		new_camera_facing = Directions.SOUTHEAST
	elif camera_angle_pos < 360:
		new_camera_facing = Directions.NORTHEAST
	
	if new_camera_facing != camera_facing:
		camera_facing = new_camera_facing
		camera_facing_changed.emit()
		get_tree().call_group("Units", "update_animation_facing", CameraFacingVectors[camera_facing])

class_name UnitControllerRT
extends CharacterBody3D

signal velocity_set(direction: Vector3)
signal camera_facing_changed()

const SPEED: float = 5.0

const ROTATE_INTERVAL: float = 90.0 # degrees
const ROTATE_SPEED: float = 300.0 # degrees / sec
#const ROTATION_DURATION: float = 0.1 # seconds
const JUMP_VELOCITY: float = 4.5

@export var phantom_camera: PhantomCamera3D
var camera_facing: Facings = Facings.NORTHWEST

enum Facings {
	NORTHWEST,
	NORTHEAST,
	SOUTHWEST,
	SOUTHEAST,
	}

const CameraFacingVectors: Dictionary[Facings, Vector3] = {
	Facings.NORTHWEST: Vector3.LEFT + Vector3.FORWARD,
	Facings.NORTHEAST: Vector3.RIGHT + Vector3.FORWARD,
	Facings.SOUTHWEST: Vector3.LEFT + Vector3.BACK,
	Facings.SOUTHEAST: Vector3.RIGHT + Vector3.BACK,
	}


var is_rotating: bool = false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if velocity * Vector3(1, 0, 1) != Vector3.ZERO:
		velocity_set.emit(direction)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"camera_rotate_left", true):
		rotate_camera(-1)
	elif event.is_action_pressed(&"camera_rotate_right", true):
		rotate_camera(1)
	# Handle jump.
	elif Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY


func rotate_camera(dir: int) -> void:
	if is_rotating:
		return
	
	is_rotating = true
	var new_rotation: Vector3 = Vector3.ZERO
	var offset: float = dir * ROTATE_INTERVAL
	
	var new_x = self.rotation_degrees.x
	var new_y = roundi(self.rotation_degrees.y) + offset
	var new_z = self.rotation_degrees.z
	#self.rotation_degrees = Vector3(new_x, new_y, new_z)
	
	new_rotation = Vector3(-26.54, new_y, new_z)
	var tween: Tween = create_tween()
	tween.tween_method(rotate_phantom_camera, MapViewer.main_camera.rotation_degrees, new_rotation, ROTATE_INTERVAL / ROTATE_SPEED)
	await tween.finished
	
	push_warning(str(camera_facing))
	is_rotating = false


func rotate_phantom_camera(new_rotation_degress: Vector3) -> void:
	phantom_camera.set_third_person_rotation_degrees(new_rotation_degress)
	self.rotation_degrees = Vector3(0, new_rotation_degress.y, 0)
	
	var camera_angle: float = MapViewer.main_camera.rotation_degrees.y
	#var target_angle = fposmod(new_rotation_degress.y, 360)
	var camera_angle_pos = fposmod(camera_angle, 360)
		
	var new_camera_facing: Facings = Facings.NORTHEAST
	if camera_angle_pos < 90:
		new_camera_facing = Facings.NORTHWEST
	elif camera_angle_pos < 180:
		new_camera_facing = Facings.SOUTHWEST
	elif camera_angle_pos < 270:
		new_camera_facing = Facings.SOUTHEAST
	elif camera_angle_pos < 360:
		new_camera_facing = Facings.NORTHEAST
	
	if new_camera_facing != camera_facing:
		camera_facing = new_camera_facing
		camera_facing_changed.emit()

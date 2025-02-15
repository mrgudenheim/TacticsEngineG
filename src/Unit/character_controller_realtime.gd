extends CharacterBody3D

const SPEED: float = 5.0

const ROTATE_INTERVAL: float = 45.0 # degrees
const ROTATE_SPEED: float = 300.0 # degrees / sec
#const ROTATION_DURATION: float = 0.1 # seconds
const JUMP_VELOCITY: float = 4.5

@export var camera_pivot: Node3D
@export var phantom_camera: PhantomCamera3D

var is_rotating: bool = false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

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

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"camera_rotate_left", true):
		rotate_camera(-1)
	elif event.is_action_pressed(&"camera_rotate_right", true):
		rotate_camera(1)


func rotate_camera(dir: int) -> void:
	if is_rotating:
		return
	
	is_rotating = true
	var new_rotation: Vector3 = Vector3.ZERO
	var offset: float = dir * ROTATE_INTERVAL
	
	var new_x = self.rotation_degrees.x
	var new_y = self.rotation_degrees.y + offset
	var new_z = self.rotation_degrees.z
	self.rotation_degrees = Vector3(new_x, new_y, new_z)
	
	await phantom_camera.tween_third_person_rotation_degrees(Vector3(-26.54, new_y, new_z), ROTATE_INTERVAL / ROTATE_SPEED)
	is_rotating = false

extends CharacterBody3D

const SPEED = 5.0

const ROTATE_SPEED = 15.0
const JUMP_VELOCITY = 4.5

@export var camera_pivot: Node3D
@export var phantom_camera: PhantomCamera3D

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
	var new_rotation: Vector3 = Vector3.ZERO
	var offset: float = dir * ROTATE_SPEED
	
	var new_x = self.rotation_degrees.x
	var new_y = self.rotation_degrees.y + offset
	var new_z = self.rotation_degrees.z
	self.rotation_degrees = Vector3(new_x, new_y, new_z)
	
	#var new_x = camera_pivot.rotation_degrees.x
	#var new_y = camera_pivot.rotation_degrees.y + offset
	#var new_z = camera_pivot.rotation_degrees.z
	#camera_pivot.rotation_degrees = Vector3(new_x, new_y, new_z)
	
	#var tween: Tween = create_tween()
	#phantom_camera.tween
	phantom_camera.set_third_person_rotation_degrees(Vector3(-26.54, new_y, new_z))
	

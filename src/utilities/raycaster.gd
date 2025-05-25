extends RayCast3D

func _ready() -> void:
	enabled = false

func raycast(from_position: Vector3, to_position: Vector3) -> Object:
	position = from_position
	target_position = to_position
	force_raycast_update()
	
	return get_collider()

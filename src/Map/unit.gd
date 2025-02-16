class_name UnitData
extends Node3D

@export var controller: UnitControllerRT

var map_position: Vector2i
var facing: Facings = Facings.NORTH

enum Facings {
	NORTH,
	EAST,
	SOUTH,
	WEST,
	}

const FacingVectors: Dictionary = {
	Facings.NORTH: Vector3.FORWARD,
	Facings.EAST: Vector3.RIGHT,
	Facings.SOUTH: Vector3.BACK,
	Facings.WEST: Vector3.LEFT,
	}

func _ready() -> void:
	controller.velocity_set.connect(update_facing)


func update_facing(dir: Vector3) -> void:
	var angle_deg: float = rad_to_deg(atan2(dir.z, dir.x)) + 45 + 90
	if angle_deg < 90:
		facing = Facings.NORTH
	elif angle_deg < 180:
		facing = Facings.EAST
	elif angle_deg < 270:
		facing = Facings.SOUTH
	elif angle_deg < 360:
		facing = Facings.WEST

class_name UnitData
extends Node3D

# https://ffhacktics.com/wiki/Miscellaneous_Unit_Data

@export var controller: UnitControllerRT
@export var animation_manager: UnitAnimationManager

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

var is_in_air: bool = false

func _ready() -> void:
	controller.velocity_set.connect(update_unit_facing)
	controller.camera_facing_changed.connect(update_animation_facing)
	RomReader.rom_loaded.connect(initialize_unit)
	
	add_to_group("Units")


func initialize_unit() -> void:
	animation_manager.unit_debug_menu.anim_id_spin.value = 6


func _process(delta: float) -> void:
	if not RomReader.is_ready:
		return
	
	if controller.velocity.y != 0 and is_in_air == false:
		is_in_air = true
		
		var mid_jump_animation: int = 62 # front facing mid jump animation
		if animation_manager.is_back_facing:
			mid_jump_animation += 1
		animation_manager.unit_debug_menu.anim_id_spin.value = mid_jump_animation
	elif controller.velocity.y == 0 and is_in_air == true:
		is_in_air = false
		
		var idle_animation: int = 6 # front facing mid jump animation
		if animation_manager.is_back_facing:
			idle_animation += 1
		animation_manager.unit_debug_menu.anim_id_spin.value = idle_animation


func update_unit_facing(dir: Vector3) -> void:
	var angle_deg: float = rad_to_deg(atan2(dir.z, dir.x)) + 45 + 90
	var new_facing: Facings = Facings.NORTH
	if angle_deg < 90:
		new_facing = Facings.NORTH
	elif angle_deg < 180:
		new_facing = Facings.EAST
	elif angle_deg < 270:
		new_facing = Facings.SOUTH
	elif angle_deg < 360:
		new_facing = Facings.WEST
	
	if new_facing != facing:
		facing = new_facing
		update_animation_facing()


func update_animation_facing() -> void:
	var unt_facing_vector: Vector3 = FacingVectors[facing]
	var camear_facing_vector: Vector3 = controller.CameraFacingVectors[controller.camera_facing]
	#var facing_difference: Vector3 = camear_facing_vector - unt_facing_vectorwad
	
	var unit_facing_angle = fposmod(rad_to_deg(atan2(unt_facing_vector.z, unt_facing_vector.x)), 360)
	var camera_facing_angle = fposmod(rad_to_deg(atan2(-camear_facing_vector.z, -camear_facing_vector.x)), 360)
	var facing_difference_angle = fposmod(camera_facing_angle - unit_facing_angle, 360)
		
	#push_warning("Difference: " + str(facing_difference) + ", UnitFacing: " + str(unt_facing_vector) + ", CameraFacing: " + str(camear_facing_vector))
	push_warning("Difference: " + str(facing_difference_angle) + ", UnitFacing: " + str(unit_facing_angle) + ", CameraFacing: " + str(camera_facing_angle))
	#push_warning(rad_to_deg(atan2(facing_difference.z, facing_difference.x)))
	
	var new_is_right_facing: bool = false
	var new_is_back_facing: bool = false
	if facing_difference_angle < 90:
		new_is_right_facing = true
		new_is_back_facing = false
	elif facing_difference_angle < 180:
		new_is_right_facing = true
		new_is_back_facing = true
	elif facing_difference_angle < 270:
		new_is_right_facing = false
		new_is_back_facing = true
	elif facing_difference_angle < 360:
		new_is_right_facing = false
		new_is_back_facing = false
	
	if (animation_manager.is_right_facing != new_is_right_facing
			or animation_manager.is_back_facing != new_is_back_facing):
		animation_manager.is_right_facing = new_is_right_facing
		
		if animation_manager.is_back_facing != new_is_back_facing:
			animation_manager.is_back_facing = new_is_back_facing
			if new_is_back_facing == true:
				animation_manager.unit_debug_menu.anim_id_spin.value += 1
			else:
				animation_manager.unit_debug_menu.anim_id_spin.value -= 1
		else:
			animation_manager._on_animation_changed()


func toggle_debug_menu() -> void:
	animation_manager.unit_debug_menu.visible = not animation_manager.unit_debug_menu.visible


func hide_debug_menu() -> void:
	animation_manager.unit_debug_menu.visible = false

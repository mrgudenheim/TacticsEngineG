class_name UnitData
extends Node3D

# https://ffhacktics.com/wiki/Miscellaneous_Unit_Data

signal ability_set(id: int)

@export var controller: UnitControllerRT
@export var animation_manager: UnitAnimationManager

@export var particle_vfx: CPUParticles3D

var can_move: bool = true

var map_position: Vector2i
var facing: Facings = Facings.NORTH
var is_back_facing: bool = false
var facing_vector: Vector3 = Vector3.FORWARD:
	get:
		return FacingVectors[facing]

enum Facings {
	NORTH,
	EAST,
	SOUTH,
	WEST,
	}

const FacingVectors: Dictionary[Facings, Vector3] = {
	Facings.NORTH: Vector3.FORWARD,
	Facings.EAST: Vector3.RIGHT,
	Facings.SOUTH: Vector3.BACK,
	Facings.WEST: Vector3.LEFT,
	}

var is_in_air: bool = false

var ability_id: int = 0
var ability_data: AbilityData
var idle_animation_id: int = 6


func _ready() -> void:
	controller.velocity_set.connect(update_unit_facing)
	controller.camera_facing_changed.connect(update_animation_facing)
	RomReader.rom_loaded.connect(initialize_unit)
	
	add_to_group("Units")


func initialize_unit() -> void:
	animation_manager.unit_debug_menu.anim_id_spin.value = idle_animation_id
	
	# 1 cure
	# 0xc8 blood suck
	# 0x9b stasis sword
	set_ability(0x9b)


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


func use_ability() -> void:
	can_move = false
	push_warning("using: " + ability_data.name)
	#push_warning("Animations: " + str(PackedInt32Array([ability_data.animation_start_id, ability_data.animation_charging_id, ability_data.animation_executing_id])))
	if ability_data.animation_start_id != 0:
		animation_manager.unit_debug_menu.anim_id_spin.value = ability_data.animation_start_id + int(is_back_facing)
		await animation_manager.animation_completed
	if ability_data.animation_charging_id != 0:
		animation_manager.unit_debug_menu.anim_id_spin.value = ability_data.animation_charging_id + int(is_back_facing)
		await get_tree().create_timer(0.1 + (ability_data.ticks_charge_time * 0.1)).timeout
	if ability_data.animation_executing_id != 0:
		animation_manager.unit_debug_menu.anim_id_spin.value = ability_data.animation_executing_id + int(is_back_facing)
		await animation_manager.animation_completed
	
	animation_manager.unit_debug_menu.anim_id_spin.value = idle_animation_id  + int(is_back_facing)
	can_move = true


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
	#is_back_facing: bool = false
	if facing_difference_angle < 90:
		new_is_right_facing = true
		is_back_facing = false
	elif facing_difference_angle < 180:
		new_is_right_facing = true
		is_back_facing = true
	elif facing_difference_angle < 270:
		new_is_right_facing = false
		is_back_facing = true
	elif facing_difference_angle < 360:
		new_is_right_facing = false
		is_back_facing = false
	
	if (animation_manager.is_right_facing != new_is_right_facing
			or animation_manager.is_back_facing != is_back_facing):
		animation_manager.is_right_facing = new_is_right_facing
		
		if animation_manager.is_back_facing != is_back_facing:
			animation_manager.is_back_facing = is_back_facing
			if is_back_facing == true:
				animation_manager.unit_debug_menu.anim_id_spin.value += 1
			else:
				animation_manager.unit_debug_menu.anim_id_spin.value -= 1
		else:
			animation_manager._on_animation_changed()


func toggle_debug_menu() -> void:
	animation_manager.unit_debug_menu.visible = not animation_manager.unit_debug_menu.visible


func hide_debug_menu() -> void:
	animation_manager.unit_debug_menu.visible = false


func set_ability(new_ability_id: int) -> void:
	ability_id = new_ability_id
	ability_data = RomReader.abilities[new_ability_id]
	
	if not ability_data.vfx_data.is_initialized:
		ability_data.vfx_data.init_from_file()
	
	animation_manager.unit_debug_menu.sprite_viewer.texture = ImageTexture.create_from_image(ability_data.vfx_data.vfx_spr.spritesheet)
	particle_vfx.mesh = ability_data.vfx_data.get_frame_mesh(2, 0)
	
	ability_set.emit(new_ability_id)

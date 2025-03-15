class_name UnitData
extends Node3D

# https://ffhacktics.com/wiki/Miscellaneous_Unit_Data
# https://ffhacktics.com/wiki/Battle_Stats

signal ability_assigned(id: int)
signal ability_completed()
signal primary_weapon_assigned(idx: int)
signal image_changed(new_image: ImageTexture)
signal knocked_out(unit: UnitData)

var is_player_controlled: bool = false

@export var char_body: CharacterBody3D
@export var animation_manager: UnitAnimationManager
@export var debug_menu: UnitDebugMenu

@export var unit_nickname: String = "Unit Nickname"
@export var job_nickname: String = "Job Nickname"

var character_id: int = 0
var unit_index_formation: int = 0
var job_id: int = 0
var sprite_palette_id: int = 0
var team_id: int = 0
var player_control: bool = true

var immortal: bool = false
var immune_knockback: bool = false
var game_over_trigger: bool = false
var type_id = 0 # male, female, monster
var death_counter: int = 3
var zodiac = "Ares"

var innate_ability_ids: PackedInt32Array = []
var skillsets: Array = []
var reaction_abilities: Array = []
var support_ability: Array = []
var movement_ability: Array = []

var primary_weapon: ItemData
var equipment: PackedInt32Array = []

var unit_exp: int = 0
var level: int = 0

var brave_base: int = 70
var brave_current: int = 70 # min 0, max 100
var faith_base: int = 70
var faith_current: int = 70 # min 0, max 100

var ct_current: int = 0
var ct_max: int = 100

var hp_base: int = 100
var hp_max: int = 100
var hp_current: int = 70
var mp_base: int = 100
var mp_max: int = 100
var mp_current: int = 70

var physical_power_base: int = 5
var physical_power_current: int = 5
var magical_power_base: int = 5
var magical_power_current: int = 5
var speed_base: int = 5
var speed_current: int = 5
var move_base: int = 5
var move_current: int = 5
var jump_base: int = 5
var jump_current: int = 5

var innate_statuses: Array = []
var immune_status_types: Array = []
var current_statuses: Array = [] # Status may have a corresponding CT countdown?

var learned_abilities: Array = []
var job_levels
var job_jp

var charging_abilities_ids: PackedInt32Array = []
var charging_abilities_remaining_ct: PackedInt32Array = [] # TODO this should be tracked per ability?
var sprite_id: int = 0
var portrait_palette_id: int = 0
var unit_id: int = 0
var special_job_skillset_id: int = 0



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
var idle_walk_animation_id: int = 6
var taking_damage_animation_id: int = 0x32
var knocked_out_animation_id: int = 0x34

func _ready() -> void:
	if not RomReader.is_ready:
		RomReader.rom_loaded.connect(initialize_unit)
	
	add_to_group("Units")


func initialize_unit() -> void:
	debug_menu.populate_options()
	
	set_sprite_file("RAMUZA.SPR")
	
	# 1 cure
	# 0xc8 blood suck
	# 0x9b stasis sword
	set_ability(0x9b)
	set_primary_weapon(1)


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not char_body.is_on_floor():
		char_body.velocity += char_body.get_gravity() * delta
	
	if not is_player_controlled:
		char_body.move_and_slide()


func _process(delta: float) -> void:
	if not RomReader.is_ready:
		return
	
	if char_body.velocity.y != 0 and is_in_air == false:
		is_in_air = true
		
		var mid_jump_animation: int = 62 # front facing mid jump animation
		if animation_manager.is_back_facing:
			mid_jump_animation += 1
		debug_menu.anim_id_spin.value = mid_jump_animation
	elif char_body.velocity.y == 0 and is_in_air == true:
		is_in_air = false
		
		var idle_animation: int = 6 # front facing idle walk animation
		if animation_manager.is_back_facing:
			idle_animation += 1
		debug_menu.anim_id_spin.value = idle_animation


func use_attack() -> void:
	can_move = false
	push_warning("using attack: " + primary_weapon.name)
	#push_warning("Animations: " + str(PackedInt32Array([ability_data.animation_start_id, ability_data.animation_charging_id, ability_data.animation_executing_id])))
	#if ability_data.animation_start_id != 0:
		#debug_menu.anim_id_spin.value = ability_data.animation_start_id + int(is_back_facing)
		#await animation_manager.animation_completed
	#
	#if ability_data.animation_charging_id != 0:
		#debug_menu.anim_id_spin.value = ability_data.animation_charging_id + int(is_back_facing)
		#await get_tree().create_timer(0.1 + (ability_data.ticks_charge_time * 0.1)).timeout
	
		#animation_executing_id = 0x3e * 2 # TODO look up based on equiped weapon and target relative height
		#animation_manager.unit_debug_menu.anim_id_spin.value = 0x3e * 2 # TODO look up based on equiped weapon and target relative height
	
	# execute atttack
	debug_menu.anim_id_spin.value = (RomReader.battle_bin_data.weapon_animation_ids[primary_weapon.item_type].y * 2) + int(is_back_facing) # TODO lookup based on target relative height
	
	# TODO implement proper timeout for abilities that execute using an infinite loop animation
	# this implementation can overwrite can_move when in the middle of another ability
	get_tree().create_timer(2).timeout.connect(func() -> void: can_move = true) 
		
	await animation_manager.animation_completed

	#ability_completed.emit()
	animation_manager.reset_sprites()
	debug_menu.anim_id_spin.value = idle_animation_id  + int(is_back_facing)
	can_move = true


func use_ability(pos: Vector3) -> void:
	can_move = false
	push_warning("using: " + ability_data.name)
	#push_warning("Animations: " + str(PackedInt32Array([ability_data.animation_start_id, ability_data.animation_charging_id, ability_data.animation_executing_id])))
	if ability_data.animation_start_id != 0:
		debug_menu.anim_id_spin.value = ability_data.animation_start_id + int(is_back_facing)
		await animation_manager.animation_completed
	
	if ability_data.animation_charging_id != 0:
		debug_menu.anim_id_spin.value = ability_data.animation_charging_id + int(is_back_facing)
		await get_tree().create_timer(0.1 + (ability_data.ticks_charge_time * 0.1)).timeout
	
	#if ability_data.animation_executing_id != 0:
	if ability_data.animation_executing_id == 0:
		#animation_executing_id = 0x3e * 2 # TODO look up based on equiped weapon and target relative height
		#animation_manager.unit_debug_menu.anim_id_spin.value = 0x3e * 2 # TODO look up based on equiped weapon and target relative height
		debug_menu.anim_id_spin.value = (RomReader.battle_bin_data.weapon_animation_ids[primary_weapon.item_type].y * 2) + int(is_back_facing) # TODO lookup based on target relative height
	else:
		debug_menu.anim_id_spin.value = ability_data.animation_executing_id + int(is_back_facing)
		
	var new_vfx_location: Node3D = Node3D.new()
	new_vfx_location.position = pos
	new_vfx_location.position.y += 3.2 # TODO set position dependent on ability vfx data
	new_vfx_location.name = "VfxLocation"
	get_parent().add_child(new_vfx_location)
	ability_data.display_vfx(new_vfx_location)
	
	# TODO implement proper timeout for abilities that execute using an infinite loop animation
	# this implementation can overwrite can_move when in the middle of another ability
	get_tree().create_timer(2).timeout.connect(func() -> void: can_move = true) 
		
	await animation_manager.animation_completed

	ability_completed.emit()
	animation_manager.reset_sprites()
	debug_menu.anim_id_spin.value = idle_animation_id  + int(is_back_facing)
	can_move = true


func process_targeted() -> void:
	if UnitControllerRT.unit == self:
		return
	
	# set being targeted frame
	var targeted_frame_index: int = RomReader.battle_bin_data.targeted_front_frame_id[animation_manager.global_spr.seq_id]
	if is_back_facing:
		targeted_frame_index = RomReader.battle_bin_data.targeted_back_frame_id[animation_manager.global_spr.seq_id]
	
	#animation_manager.global_animation_ptr_id = 0
	debug_menu.anim_id_spin.value = 0
	var assembled_image: Image = animation_manager.global_shp.get_assembled_frame(targeted_frame_index, animation_manager.global_spr.spritesheet, 0, 
		0, 0, 0)
	animation_manager.unit_sprites_manager.sprite_primary.texture = ImageTexture.create_from_image(assembled_image)
	
	await get_tree().create_timer(0.2).timeout
	
	# take damage animation
	#animation_manager.global_animation_ptr_id = taking_damage_animation_id
	debug_menu.anim_id_spin.value = taking_damage_animation_id
	
	# show result / damage numbers
	
	# TODO await ability.vfx_completed? Or does ability_completed just need to wait to post numbers? aka WaitWeaponSheathe1/2 opcode?
	await UnitControllerRT.unit.ability_completed
	# show death animation
	#animation_manager.global_animation_ptr_id = knocked_out_animation_id
	debug_menu.anim_id_spin.value = knocked_out_animation_id
	idle_animation_id = knocked_out_animation_id
	
	knocked_out.emit(self)


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
		update_animation_facing(UnitControllerRT.CameraFacingVectors[UnitControllerRT.camera_facing])


func update_animation_facing(camera_facing_vector: Vector3) -> void:
	var unit_facing_vector: Vector3 = FacingVectors[facing]
	#var camera_facing_vector: Vector3 = UnitControllerRT.CameraFacingVectors[controller.camera_facing]
	#var facing_difference: Vector3 = camera_facing_vector - unt_facing_vectorwad
	
	var unit_facing_angle = fposmod(rad_to_deg(atan2(unit_facing_vector.z, unit_facing_vector.x)), 360)
	var camera_facing_angle = fposmod(rad_to_deg(atan2(-camera_facing_vector.z, -camera_facing_vector.x)), 360)
	var facing_difference_angle = fposmod(camera_facing_angle - unit_facing_angle, 360)
		
	#push_warning("Difference: " + str(facing_difference) + ", UnitFacing: " + str(unit_facing_vector) + ", CameraFacing: " + str(camera_facing_vector))
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
				debug_menu.anim_id_spin.value += 1
			else:
				debug_menu.anim_id_spin.value -= 1
		else:
			animation_manager._on_animation_changed()


func toggle_debug_menu() -> void:
	debug_menu.visible = not debug_menu.visible


func hide_debug_menu() -> void:
	debug_menu.visible = false


func set_ability(new_ability_id: int) -> void:
	ability_id = new_ability_id
	ability_data = RomReader.abilities[new_ability_id]
	
	if not ability_data.vfx_data.is_initialized:
		ability_data.vfx_data.init_from_file()
	
	image_changed.emit(ImageTexture.create_from_image(ability_data.vfx_data.vfx_spr.spritesheet))
	#debug_menu.sprite_viewer.texture = ImageTexture.create_from_image(ability_data.vfx_data.vfx_spr.spritesheet)
	ability_assigned.emit(new_ability_id)


func set_primary_weapon(new_weapon_id: int) -> void:
	primary_weapon = RomReader.items[new_weapon_id]
	primary_weapon_assigned.emit(new_weapon_id)


func set_sprite(sprite_id: int) -> void:
	debug_menu.sprite_options.select(sprite_id)
	debug_menu.sprite_options.item_selected.emit(debug_menu.sprite_options.selected)
	debug_menu.anim_id_spin.value = idle_animation_id


func set_sprite_file(sprite_file_name: String) -> void:
	debug_menu.sprite_options.select(RomReader.file_records[sprite_file_name].type_index)
	debug_menu.sprite_options.item_selected.emit(debug_menu.sprite_options.selected)
	debug_menu.anim_id_spin.value = idle_animation_id


func _on_character_body_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if Input.is_action_just_pressed("secondary_action") and UnitControllerRT.unit.char_body.is_on_floor():
		UnitControllerRT.unit.use_ability(char_body.position)
		process_targeted()

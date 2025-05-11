class_name UnitData
extends Node3D

# https://ffhacktics.com/wiki/Miscellaneous_Unit_Data
# https://ffhacktics.com/wiki/Battle_Stats

signal ability_assigned(id: int)
signal ability_completed()
signal primary_weapon_assigned(idx: int)
signal image_changed(new_image: ImageTexture)
signal knocked_out(unit: UnitData)
signal spritesheet_changed(new_spritesheet: ImageTexture)
signal reached_tile()
signal completed_move()

var is_player_controlled: bool = false
var is_active: bool = false

@export var char_body: CharacterBody3D
@export var animation_manager: UnitAnimationManager
@export var debug_menu: UnitDebugMenu

@export var unit_nickname: String = "Unit Nickname"
@export var job_nickname: String = "Job Nickname"

var character_id: int = 0
var unit_index_formation: int = 0
var job_id: int = 0
var job_data: JobData
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
var jump_current: int = 3

var innate_statuses: Array = []
var immune_status_types: Array = []
var current_statuses: Array = [] # Status may have a corresponding CT countdown?

var learned_abilities: Array = []
var job_levels
var job_jp

var charging_abilities_ids: PackedInt32Array = []
var charging_abilities_remaining_ct: PackedInt32Array = [] # TODO this should be tracked per ability?
var sprite_id: int = 0
var sprite_file_idx = 0
var portrait_palette_id: int = 0
var unit_id: int = 0
var special_job_skillset_id: int = 0

var can_move: bool = true

var map_position: Vector2i
var tile_position: TerrainTile
var map_paths: Dictionary[TerrainTile, TerrainTile]
var path_costs: Dictionary[TerrainTile, float]
@export var tile_highlights: Node3D
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
	Facings.NORTH: Vector3.BACK,
	Facings.EAST: Vector3.RIGHT,
	Facings.SOUTH: Vector3.FORWARD,
	Facings.WEST: Vector3.LEFT,
	}

var is_in_air: bool = false
var is_moving: bool = false

var ability_id: int = 0
var ability_data: AbilityData

var idle_animation_id: int = 6 # set based on status (critical, knocked out, etc.)
var current_animation_id_fwd: int = 6 # set based on current action
# constants?
var idle_walk_animation_id: int = 6
var walk_to_animation_id: int = 0x18
var taking_damage_animation_id: int = 0x32
var knocked_out_animation_id: int = 0x34
var mid_jump_animation: int = 62

var submerged_depth: int = 0

func _ready() -> void:
	if not RomReader.is_ready:
		RomReader.rom_loaded.connect(initialize_unit)
	
	add_to_group("Units")


func initialize_unit() -> void:
	debug_menu.populate_options()
	
	animation_manager.wep_spr = RomReader.sprs[RomReader.file_records["WEP.SPR"].type_index]
	animation_manager.wep_shp = RomReader.shps[RomReader.file_records["WEP1.SHP"].type_index]
	animation_manager.wep_seq = RomReader.seqs[RomReader.file_records["WEP1.SEQ"].type_index]
	
	animation_manager.eff_spr = RomReader.sprs[RomReader.file_records["EFF.SPR"].type_index]
	animation_manager.eff_shp = RomReader.shps[RomReader.file_records["EFF1.SHP"].type_index]
	animation_manager.eff_seq = RomReader.seqs[RomReader.file_records["EFF1.SEQ"].type_index]
	
	animation_manager.unit_sprites_manager.sprite_effect.texture = animation_manager.eff_spr.create_frame_grid_texture(0, 0, 0, 0, 0)
	
	animation_manager.item_spr = RomReader.sprs[RomReader.file_records["ITEM.BIN"].type_index]
	
	animation_manager.unit_sprites_manager.sprite_item.texture = ImageTexture.create_from_image(RomReader.sprs[RomReader.file_records["ITEM.BIN"].type_index].spritesheet)
	
	animation_manager.other_spr = RomReader.sprs[RomReader.file_records["OTHER.SPR"].type_index]
	animation_manager.other_shp = RomReader.shps[RomReader.file_records["OTHER.SHP"].type_index]
	
	# 1 cure
	# 0xc8 blood suck
	# 0x9b stasis sword
	set_ability(0x9b)
	set_primary_weapon(1)
	set_sprite_by_file_idx(98) # RAMUZA.SPR # TODO use sprite_id?
	#set_sprite_by_file_name("RAMUZA.SPR")
	
	update_unit_facing(FacingVectors[Facings.SOUTH])


func _physics_process(delta: float) -> void:
	# FFTae (and all non-battles) don't use physics, so this can be turned off
	if not is_instance_valid(BattleManager.main_camera):
		set_physics_process(false)
		return
	
	# Add the gravity.
	if not char_body.is_on_floor():
		char_body.velocity += char_body.get_gravity() * delta
	
	var velocity_horizontal = char_body.velocity
	velocity_horizontal.y = 0
	if velocity_horizontal.length_squared() > 0.01:
		update_unit_facing(velocity_horizontal.normalized())
	char_body.move_and_slide()


func _process(_delta: float) -> void:
	if not RomReader.is_ready:
		return
	
	if char_body.velocity.y != 0 and is_in_air == false:
		is_in_air = true
		
		#var mid_jump_animation: int = 62 # front facing mid jump animation
		#if animation_manager.is_back_facing:
			#mid_jump_animation += 1
		current_animation_id_fwd = mid_jump_animation
		#debug_menu.anim_id_spin.value = mid_jump_animation
	elif char_body.velocity.y == 0 and is_in_air == true:
		is_in_air = false
		
		#var idle_animation: int = 6 # front facing idle walk animation
		#if animation_manager.is_back_facing:
			#idle_animation += 1
		current_animation_id_fwd = idle_animation_id
		#debug_menu.anim_id_spin.value = idle_animation
	
	set_base_animation_ptr_id(current_animation_id_fwd)


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
	#debug_menu.anim_id_spin.value = (RomReader.battle_bin_data.weapon_animation_ids[primary_weapon.item_type].y * 2) + int(is_back_facing) # TODO lookup based on target relative height
	current_animation_id_fwd = (RomReader.battle_bin_data.weapon_animation_ids[primary_weapon.item_type].y * 2) # TODO lookup based on target relative height
	set_base_animation_ptr_id(current_animation_id_fwd)
	
	# TODO implement proper timeout for abilities that execute using an infinite loop animation
	# this implementation can overwrite can_move when in the middle of another ability
	get_tree().create_timer(2).timeout.connect(func() -> void: can_move = true) 
		
	await animation_manager.animation_completed

	#ability_completed.emit()
	animation_manager.reset_sprites()
	#debug_menu.anim_id_spin.value = idle_animation_id  + int(is_back_facing)
	current_animation_id_fwd = idle_animation_id
	set_base_animation_ptr_id(current_animation_id_fwd)
	can_move = true


func use_ability(pos: Vector3) -> void:
	can_move = false
	push_warning("using: " + ability_data.name)
	#push_warning("Animations: " + str(PackedInt32Array([ability_data.animation_start_id, ability_data.animation_charging_id, ability_data.animation_executing_id])))
	if ability_data.animation_start_id != 0:
		#debug_menu.anim_id_spin.value = ability_data.animation_start_id + int(is_back_facing)
		current_animation_id_fwd = ability_data.animation_start_id
		set_base_animation_ptr_id(current_animation_id_fwd)
		await animation_manager.animation_completed
	
	if ability_data.animation_charging_id != 0:
		#debug_menu.anim_id_spin.value = ability_data.animation_charging_id + int(is_back_facing)
		current_animation_id_fwd = ability_data.animation_charging_id
		set_base_animation_ptr_id(current_animation_id_fwd)
		await get_tree().create_timer(0.1 + (ability_data.ticks_charge_time * 0.1)).timeout
	
	#if ability_data.animation_executing_id != 0:
	if ability_data.animation_executing_id == 0:
		#animation_executing_id = 0x3e * 2 # TODO look up based on equiped weapon and target relative height
		#animation_manager.unit_debug_menu.anim_id_spin.value = 0x3e * 2 # TODO look up based on equiped weapon and target relative height
		#debug_menu.anim_id_spin.value = (RomReader.battle_bin_data.weapon_animation_ids[primary_weapon.item_type].y * 2) + int(is_back_facing) # TODO lookup based on target relative height
		current_animation_id_fwd = (RomReader.battle_bin_data.weapon_animation_ids[primary_weapon.item_type].y * 2) # TODO lookup based on target relative height
		set_base_animation_ptr_id(current_animation_id_fwd)
	else:
		var ability_animation_executing_id = ability_data.animation_executing_id
		if ["RUKA.SEQ", "ARUTE.SEQ", "KANZEN.SEQ"].has(RomReader.sprs[sprite_file_idx].seq_name):
			ability_animation_executing_id = 0x2c * 2 # https://ffhacktics.com/wiki/Set_attack_animation_flags_and_facing_3
		#debug_menu.anim_id_spin.value = ability_animation_executing_id + int(is_back_facing)
		current_animation_id_fwd = ability_animation_executing_id
		set_base_animation_ptr_id(current_animation_id_fwd)
		
	var new_vfx_location: Node3D = Node3D.new()
	new_vfx_location.position = pos
	#new_vfx_location.position.y += 2 # TODO set position dependent on ability vfx data
	new_vfx_location.name = "VfxLocation"
	get_parent().add_child(new_vfx_location)
	ability_data.display_vfx(new_vfx_location)
	
	# TODO implement proper timeout for abilities that execute using an infinite loop animation
	# this implementation can overwrite can_move when in the middle of another ability
	get_tree().create_timer(2).timeout.connect(func() -> void: can_move = true) 
		
	await animation_manager.animation_completed

	ability_completed.emit()
	animation_manager.reset_sprites()
	#debug_menu.anim_id_spin.value = idle_animation_id  + int(is_back_facing)
	current_animation_id_fwd = idle_animation_id
	set_base_animation_ptr_id(current_animation_id_fwd)
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
	#debug_menu.anim_id_spin.value = taking_damage_animation_id
	current_animation_id_fwd = taking_damage_animation_id
	set_base_animation_ptr_id(current_animation_id_fwd)
	
	# show result / damage numbers
	
	# TODO await ability.vfx_completed? Or does ability_completed just need to wait to post numbers? aka WaitWeaponSheathe1/2 opcode?
	await UnitControllerRT.unit.ability_completed
	# show death animation
	#animation_manager.global_animation_ptr_id = knocked_out_animation_id
	#debug_menu.anim_id_spin.value = knocked_out_animation_id
	idle_animation_id = knocked_out_animation_id
	current_animation_id_fwd = idle_animation_id
	set_base_animation_ptr_id(current_animation_id_fwd)
	
	knocked_out.emit(self)


func set_base_animation_ptr_id(ptr_id: int) -> void:
	var new_ptr: int = ptr_id
	if is_back_facing:
		new_ptr = ptr_id + 1
	
	#if is_back_facing:
		#debug_menu.anim_id_spin.value = ptr_id + 1
		##animation_manager.global_animation_ptr_id = ptr_id + 1
	#else:
		#debug_menu.anim_id_spin.value = ptr_id
		##animation_manager.global_animation_ptr_id = ptr_id
	
	if animation_manager.global_animation_ptr_id != new_ptr:
		debug_menu.anim_id_spin.value = new_ptr
		#animation_manager.global_animation_ptr_id = new_ptr


func update_unit_facing(dir: Vector3) -> void:
	var angle_deg: float = rad_to_deg(atan2(dir.z, dir.x))
	angle_deg = fposmod(angle_deg, 359.99) + 45 # add 45 so EAST is just < 90 instead of < 45 and > 315
	angle_deg = fposmod(angle_deg, 359.99) # correction for values over 360 due to adding 45
	var new_facing: Facings = facing
	if angle_deg < 90:
		new_facing = Facings.EAST
	elif angle_deg < 180:
		new_facing = Facings.NORTH
	elif angle_deg < 270:
		new_facing = Facings.WEST
	elif angle_deg < 360:
		new_facing = Facings.SOUTH
	
	if new_facing != facing:
		var temp_facing = facing
		facing = new_facing
		update_animation_facing(UnitControllerRT.CameraFacingVectors[UnitControllerRT.camera_facing])


func update_animation_facing(camera_facing_vector: Vector3) -> void:
	var unit_facing_vector: Vector3 = FacingVectors[facing]
	#var camera_facing_vector: Vector3 = UnitControllerRT.CameraFacingVectors[controller.camera_facing]
	#var facing_difference: Vector3 = camera_facing_vector - unt_facing_vectorwad
	
	var unit_facing_angle = fposmod(rad_to_deg(atan2(unit_facing_vector.z, unit_facing_vector.x)), 359.99)
	var camera_facing_angle = fposmod(rad_to_deg(atan2(-camera_facing_vector.z, -camera_facing_vector.x)), 359.99)
	var facing_difference_angle = fposmod(camera_facing_angle - unit_facing_angle, 359.99)
		
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
		animation_manager.set_face_right(new_is_right_facing)
		
		if animation_manager.is_back_facing != is_back_facing:
			animation_manager.is_back_facing = is_back_facing
			if is_back_facing == true:
				debug_menu.anim_id_spin.value += 1
			else:
				debug_menu.anim_id_spin.value -= 1


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
	#animation_manager.weapon_id = new_weapon_id
	#var weapon_palette_id = RomReader.battle_bin_data.weapon_graphic_palettes_1[primary_weapon.id]
	animation_manager.unit_sprites_manager.sprite_weapon.texture = animation_manager.wep_spr.create_frame_grid_texture(
		primary_weapon.wep_frame_palette, 0, 0, primary_weapon.wep_frame_v_offset, 0, animation_manager.wep_shp.file_name)
	primary_weapon_assigned.emit(new_weapon_id)


func set_sprite_by_file_idx(new_sprite_file_idx: int) -> void:
	sprite_file_idx = new_sprite_file_idx
	var spr: Spr = RomReader.sprs[new_sprite_file_idx]
	if spr.file_name == "WEP.SPR":
		animation_manager.unit_sprites_manager.sprite_primary.vframes = 32
	else:
		animation_manager.unit_sprites_manager.sprite_primary.vframes = 16 + (16 * spr.sp2s.size())
	
	if RomReader.spr_file_name_to_id.has(spr.file_name):
		sprite_id = RomReader.spr_file_name_to_id[spr.file_name]
	debug_menu.sprite_options.select(new_sprite_file_idx)
	on_sprite_idx_selected(new_sprite_file_idx)
	update_spritesheet_grid_texture()
	
	debug_menu.anim_id_spin.value = idle_animation_id


func set_sprite_by_file_name(sprite_file_name: String) -> void:
	var new_sprite_file_idx: int = RomReader.file_records[sprite_file_name].type_index
	set_sprite_by_file_idx(new_sprite_file_idx)


func set_sprite_by_id(new_sprite_id: int) -> void:
	var new_sprite_file_idx = RomReader.spr_id_file_idxs[new_sprite_id]
	set_sprite_by_file_idx(new_sprite_file_idx)


func set_sprite_palette(new_palette_id: int) -> void:
	if new_palette_id == sprite_palette_id:
		return
	
	sprite_palette_id = new_palette_id
	update_spritesheet_grid_texture()


func set_submerged_depth(new_depth: int) -> void:
	if new_depth == submerged_depth:
		return
	
	submerged_depth = new_depth
	update_spritesheet_grid_texture()


func update_spritesheet_grid_texture() -> void:
	var new_spr: Spr = RomReader.sprs[sprite_file_idx]
	animation_manager.unit_sprites_manager.sprite_primary.texture = new_spr.create_frame_grid_texture(sprite_palette_id, 0, 0, 0, submerged_depth)


func on_sprite_idx_selected(index: int) -> void:
	var spr: Spr = RomReader.sprs[index]
	if not spr.is_initialized:
		spr.set_data()
		spr.set_spritesheet_data(RomReader.spr_file_name_to_id[spr.file_name])
	
	animation_manager.global_spr = spr
	
	var shp: Shp = RomReader.shps[RomReader.file_records[spr.shp_name].type_index]
	if not shp.is_initialized:
		shp.set_data_from_shp_bytes(RomReader.get_file_data(shp.file_name))
	
	var seq: Seq = RomReader.seqs[RomReader.file_records[spr.seq_name].type_index]
	if not seq.is_initialized:
		seq.set_data_from_seq_bytes(RomReader.get_file_data(seq.file_name))
	
	var animation_changed: bool = false
	if shp.file_name == "TYPE2.SHP":
		if animation_manager.wep_shp.file_name != "WEP2.SHP":
			animation_manager.wep_shp = RomReader.shps[RomReader.file_records["WEP2.SHP"].type_index]
			set_primary_weapon(primary_weapon.id) # get new texture based on wep2.shp
			animation_changed = true
		animation_manager.wep_seq = RomReader.seqs[RomReader.file_records["WEP2.SEQ"].type_index]
	
	if shp != animation_manager.global_shp or seq != animation_manager.global_seq:
		animation_changed = true
	
	animation_manager.global_spr = spr
	animation_manager.global_shp = shp
	animation_manager.global_seq = seq
	
	
	#spritesheet_changed.emit(animation_manager.unit_sprites_manager.sprite_item.texture) # TODO hook up to sprite for debug purposes
	#spritesheet_changed.emit(ImageTexture.create_from_image(spr.spritesheet)) # TODO hook up to sprite for debug purposes
	#spritesheet_changed.emit(animation_manager.unit_sprites_manager.sprite_weapon.texture) # TODO hook up to sprite for debug purposes
	if animation_changed:
		animation_manager._on_animation_changed()


## map_tiles is Dictionary[Vector2i, Array[TerrainTile]], returns path to every tile
func get_map_paths(map_tiles: Dictionary[Vector2i, Array], units: Array[UnitData], max_cost: int = 9999) -> Dictionary[TerrainTile, TerrainTile]:
	var start_tile: TerrainTile = tile_position
	#var start_tile: TerrainTile = map_tiles[map_position][0]
	#if map_tiles[map_position].size() > 1:
		#for potential_tile in map_tiles[map_position]:
			#
	var frontier: Array[TerrainTile] = [] # TODO use priority_queue for dijkstra's
	frontier.append(start_tile)
	var came_from: Dictionary[TerrainTile, TerrainTile] = {} # path A->B is stored as came_from[B] == A
	var cost_so_far: Dictionary[TerrainTile, float] = {}
	came_from[start_tile] = null
	cost_so_far[start_tile] = 0
	
	var current: TerrainTile
	while not frontier.is_empty():
		current = frontier.pop_front()
		
		# break early
		#if current == goal:
			#break  
		
		for next: TerrainTile in get_map_path_neighbors(current, map_tiles, units):
			var new_cost: float = cost_so_far[current] + get_move_cost(current, next)
			if new_cost > max_cost:
				continue # break early
			
			if next not in cost_so_far or new_cost < cost_so_far[next]:
				# TODO use a priority_queue
				if next not in cost_so_far:
					cost_so_far[next] = new_cost
					for idx: int in frontier.size(): # TODO use frontier.bsearch_custom(new_cost, func(a, b): return cost_so_far[b] < a)?
						if new_cost < cost_so_far[frontier[idx]]: # assumes frontier is sorted by ascending cost_so_far
							frontier.insert(idx, next)
							break
					frontier.append(next) # add at end if highest cost
				elif new_cost < cost_so_far[next]:
					var current_priority = frontier.bsearch(next)
					cost_so_far[next] = new_cost
					if current_priority == 0:
						pass # don't need to change priority
					elif cost_so_far[frontier[current_priority - 1]] < new_cost:
						pass # don't need to change priority
					else: # move position in queue
						frontier.remove_at(current_priority)
						for idx: int in frontier.size(): # TODO use frontier.bsearch_custom(new_cost, func(a, b): return cost_so_far[b] < a)?
							if new_cost < cost_so_far[frontier[idx]]: # assumes frontier is sorted by ascending cost_so_far
								frontier.insert(idx, next)
								break
				
				came_from[next] = current
	
	path_costs = cost_so_far
	return came_from


func get_map_path(start_tile: TerrainTile, target_tile: TerrainTile, came_from: Dictionary[TerrainTile, TerrainTile]) -> Array[TerrainTile]:
	if not came_from.has(target_tile):
		push_warning("No path from " + str(start_tile.location) + " to target: " + str(target_tile.location))
		return []
	
	var current: TerrainTile = target_tile
	var path: Array[TerrainTile] = []
	while current != start_tile: 
		path.append(current)
		current = came_from[current]
	#path.append(start_tile) # optional
	path.reverse() # optional
	
	return path


func get_map_path_neighbors(current_tile: TerrainTile, map_tiles: Dictionary[Vector2i, Array], units: Array[UnitData]) -> Array[TerrainTile]:
	var neighbors: Array[TerrainTile]
	const adjacent_offsets: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	# check adjacent tiles
	for offset: Vector2i in adjacent_offsets:
		var potential_xy: Vector2i = current_tile.location + offset
		if map_tiles.has(potential_xy):
			for tile: TerrainTile in map_tiles[potential_xy]:
				if tile.no_walk == 1:
					continue
				elif tile.surface_type_id == 0x12: # lava TODO check movement abilities
					continue
				elif abs(tile.height_mid - current_tile.height_mid) > jump_current: # restrict movement based on current jomp
					continue
				elif units.any(func(unit: UnitData): return unit.tile_position == tile): # prevent moving on top or through other units
					continue # TODO allow moving through knocked out units
				# TODO prevent trying to move vertically through floors/ceilings
				else:
					neighbors.append(tile)
		
		neighbors.append_array(get_leaping_neighbors(current_tile, map_tiles, units, offset, neighbors))
	# TODO check other cases - leaping, teleport, map warps, fly, float, etc.
	# TODO get costs
	# TODO get animations - walking, jumping, etc.
	
	return neighbors


func get_leaping_neighbors(current_tile: TerrainTile, map_tiles: Dictionary[Vector2i, Array], units: Array[UnitData], offset_direction: Vector2i, walk_neighbors: Array[TerrainTile]) -> Array[TerrainTile]:
	var leap_neighbors: Array[TerrainTile] = []
	var max_leap_distance: int = jump_current / 2
	
	if max_leap_distance == 0:
		return leap_neighbors
	
	for leap_distance: int in range(1, max_leap_distance + 1):
		var potential_xy: Vector2i = current_tile.location + (offset_direction * (leap_distance + 1))
		if map_tiles.has(potential_xy):
			var intermediate_tiles: Array[TerrainTile] = []
			for intermediate_distance: int in range(1, leap_distance + 1):
				var intermediate_xy: Vector2i = current_tile.location + (offset_direction * intermediate_distance)
				if map_tiles.has(intermediate_xy):
					intermediate_tiles.append_array(map_tiles[intermediate_xy])
			for tile: TerrainTile in map_tiles[potential_xy]:
				if tile.no_walk == 1:
					continue
				elif tile.surface_type_id == 0x12: # lava TODO check movement abilities
					continue
				elif abs(tile.height_mid - current_tile.height_mid) > jump_current: # restrict movement based on current jomp
					continue
				elif tile.height_mid > current_tile.height_mid: # can't leap up
					continue
				# TODO prevent trying to move vertically through floors/ceilings
				elif units.any(func(unit: UnitData): return unit.tile_position == tile): # prevent moving on top or through other units
					continue # TODO allow moving through knocked out units
				elif intermediate_tiles.any(func(intermediate_tile: TerrainTile): return intermediate_tile.height_mid > current_tile.height_mid): # prevent leaping through taller intermediate tiles
					continue # TODO fix leap check for leaping under a bridge/ceiling
				elif intermediate_tiles.any(func(intermediate_tile: TerrainTile): 
					var can_walk: bool = true
					if units.any(func(unit: UnitData): return unit.tile_position == tile):
						can_walk = intermediate_tile.height_mid + 3 > current_tile.height_mid # prevent leaping over units taller than starting height
					return not can_walk): 
					continue # TODO fix leap check for leaping under a bridge/ceiling
				elif intermediate_tiles.any(func(intermediate_tile: TerrainTile): # prevent leaping when walking would be fine
						var intermediate_is_taller_then_final: bool = intermediate_tile.height_mid >= tile.height_mid # TODO more complex check for if there is actually a path from the intermediate tile
						var intermediate_is_walkable: bool = walk_neighbors.has(intermediate_tile) or leap_neighbors.has(intermediate_tile)
						return (intermediate_is_taller_then_final and intermediate_is_walkable)
						): 
					continue
				else:
					leap_neighbors.append(tile)
	
	return leap_neighbors


func get_move_cost(from_tile: TerrainTile, to_tile: TerrainTile) -> float:
	var cost: float = 0
	cost = from_tile.location.distance_to(to_tile.location)
	
	# TODO check depth
	
	return cost


func walk_to_tile(to_tile: TerrainTile) -> void:
	current_animation_id_fwd = walk_to_animation_id
	var distance_to_move: float = tile_position.location.distance_to(to_tile.location)
	if distance_to_move > 1.1: # TODO is leaping the only case where moving more than 1 distance at a time?
		char_body.velocity.y = 1.1 * distance_to_move # hop over intermediate tiles
	await process_physics_move(to_tile.get_world_position())
	tile_position = to_tile
	
	while not char_body.is_on_floor():
		await get_tree().process_frame
	
	tile_position = to_tile
	reached_tile.emit()


func process_physics_move(target_position: Vector3) -> void:
	var speed: float = 4.0
	var current_xy: Vector2 = Vector2(char_body.global_position.x, char_body.global_position.z)
	var target_xy: Vector2 = Vector2(target_position.x, target_position.z)
	var distance_left: float = current_xy.distance_to(target_xy)
	
	while distance_left > 0.05: # char_body.position is about 0.25 off the ground
		current_xy = Vector2(char_body.global_position.x, char_body.global_position.z)
		var direction: Vector2 = current_xy.direction_to(target_xy)
		#direction.y = 0
		var velocity_2d: Vector2 = direction * speed
		distance_left = current_xy.distance_to(target_xy)
		velocity_2d = velocity_2d.limit_length(distance_left / get_physics_process_delta_time())
		char_body.velocity.x = velocity_2d.x
		char_body.velocity.z = velocity_2d.y
		if (char_body.is_on_wall() # TODO implement jumping and leaping correctly
				and target_position.y + 0.25 > char_body.global_position.y
				and char_body.velocity.y <= 0.1): # TODO fix comparing target position to charbody, char_body's position is offset from the ground
			char_body.velocity.y = sqrt((target_position.y + 0.25) - char_body.global_position.y) * 4.5
		await get_tree().physics_frame
	
	#char_body.velocity = Vector3.ZERO
	char_body.velocity.x = 0
	char_body.velocity.z = 0


#func sort_ascending(a_idx: int, b_idx: int):
	#if a.cost < b.cost:
		#return true
	#return false


func travel_path(path: Array[TerrainTile]) -> void:
	is_moving = true
	for tile: TerrainTile in path:
		await walk_to_tile(tile) # TODO handle movement types other than walking
	
	#animation_manager.global_animation_ptr_id = idle_animation_id
	current_animation_id_fwd = idle_animation_id
	set_base_animation_ptr_id(current_animation_id_fwd)
	is_moving = false
	completed_move.emit()


func get_move_targets() -> Array[TerrainTile]:
	var move_targets: Array[TerrainTile] = []
	for tile: TerrainTile in path_costs.keys():
		if path_costs[tile] > move_current:
			continue # don't highlight tiles beyond move range
		move_targets.append(tile)
	
	return move_targets


# TODO implement generic actions that can have tiles as targets, use this to highlight targets
func highlight_tiles(tiles: Array[TerrainTile], highlight_material: Material) -> void:
	for tile: TerrainTile in tiles:
		var new_tile_selector: MeshInstance3D = tile.get_tile_mesh()
		new_tile_selector.material_override = highlight_material # use pre-existing materials
		tile_highlights.add_child(new_tile_selector)
		new_tile_selector.global_position = tile.get_world_position(true) + Vector3(0, 0.05, 0)


func highlight_move_area(highlight_material: Material) -> void:
	for tile: TerrainTile in path_costs.keys():
		if tile == tile_position:
			continue
		if path_costs[tile] > move_current:
			continue # don't highlight tiles beyond move range
		var new_tile_selector: MeshInstance3D = tile.get_tile_mesh()
		new_tile_selector.material_override = highlight_material # use pre-existing materials
		tile_highlights.add_child(new_tile_selector)
		new_tile_selector.global_position = tile.get_world_position(true) + Vector3(0, 0.05, 0)


func clear_tile_highlights(highlight_container: Node3D) -> void:
	for child in highlight_container.get_children():
		child.queue_free()


func _on_character_body_3d_input_event(_camera: Node, _event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if Input.is_action_just_pressed("secondary_action") and UnitControllerRT.unit.char_body.is_on_floor():
		UnitControllerRT.unit.use_ability(char_body.position)
		process_targeted()


# TODO Unit preview ui - hp, mp, evade, hand equipment, statuses, status immunities, elemental scalaing, etc. portrait/mini sprite?

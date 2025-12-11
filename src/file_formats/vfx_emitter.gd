class_name VfxEmitter
extends RefCounted

var anim_index: int
var animation: VisualEffectData.VfxAnimation
var motion_type_flag: int
var align_to_velocity: bool = false
var target_anchor_mode: int = 0
var animation_target_flag: int
var spread_mode: int = 0
var emitter_anchor_mode: int = 0
var handler_index: int = 0 # unused
var frameset_group_index: int
# byte_05 unused
var emitter_flags: int = 0 # bytes 0x06 and 0x07
var child_death_mode: int = 0
var child_midlife_mode: int = 0
var is_velocity_inward: bool = false
var enable_color_curve: bool = false

var velocity_mode: int = 0

# curves
var interpolation_curve_indicies: Dictionary = {
	POSITION = 0,
	PARTICLE_SPREAD = 0,
	VELOCITY_ANGLE = 0,
	VELOCITY_ANGLE_SPREAD = 0,
	INERTIA = 0,
	WEIGHT = 0,
	RADIAL_VELOCITY = 0,
	ACCELERATION = 0,
	DRAG = 0,
	PARTICLE_LIFETIME = 0,
	TARGET_OFFSET = 0,
	PARTICLE_COUNT = 0,
	SPAWN_INTERVAL = 0,
	HOMING_STRENGTH = 0,
	HOMING_CURVE = 0,
	COLOR_R = 0,
	COLOR_G = 0,
	COLOR_B = 0,
}

var start_position: Vector3 = Vector3.ZERO
var end_position: Vector3 = Vector3.ZERO

var start_position_spread: Vector3 = Vector3.ZERO
var end_position_spread: Vector3 = Vector3.ZERO

var start_angle: Vector3 = Vector3.ZERO
var end_angle: Vector3 = Vector3.ZERO

var start_angle_spread: Vector3 = Vector3.ZERO
var end_angle_spread: Vector3 = Vector3.ZERO

var intertia_min_start: int = 0
var intertia_max_start: int = 0
var intertia_min_end: int = 0
var intertia_max_end: int = 0

var weight_min_start: int = 0
var weight_max_start: int = 0
var weight_min_end: int = 0
var weight_max_end: int = 0

var radial_velocity_min_start: int = 0
var radial_velocity_max_start: int = 0
var radial_velocity_min_end: int = 0
var radial_velocity_max_end: int = 0

var acceleration_min_start: Vector3 = Vector3.ZERO
var acceleration_max_start: Vector3 = Vector3.ZERO
var acceleration_min_end: Vector3 = Vector3.ZERO
var acceleration_max_end: Vector3 = Vector3.ZERO

var drag_min_start: Vector3 = Vector3.ZERO
var drag_max_start: Vector3 = Vector3.ZERO
var drag_min_end: Vector3 = Vector3.ZERO
var drag_max_end: Vector3 = Vector3.ZERO

var lifetime_min_start: int = 0
var lifetime_max_start: int = 0
var lifetime_min_end: int = 0
var lifetime_max_end: int = 0

var target_offset_start: Vector3 = Vector3.ZERO
var target_offset_end: Vector3 = Vector3.ZERO

var particle_count_start: int = 0
var particle_count_end: int = 0

var spawn_interval_start: int = 0
var spawn_interval_end: int = 0

var homing_strength_min_start: Vector3 = Vector3.ZERO
var homing_strength_max_start: Vector3 = Vector3.ZERO
var homing_strength_min_end: Vector3 = Vector3.ZERO
var homing_strength_max_end: Vector3 = Vector3.ZERO

var child_emitter_idx_on_death: int = 0
var child_emitter_idx_on_interval: int = 0

# var color_masking_motion_flags: int # byte 06
# var byte_07: int
# var start_position: Vector3i
# var end_position: Vector3i

var start_time: int = 0

func _init(bytes: PackedByteArray = []):
	if bytes.size() == 0:
		return
	
	anim_index = bytes.decode_u8(1)
	motion_type_flag = bytes.decode_u8(2)
	animation_target_flag = bytes.decode_u8(3)
	frameset_group_index = bytes.decode_u8(4)
	# byte_05 = bytes.decode_u8(5)
	# color_masking_motion_flags = bytes.decode_u8(6)
	# byte_07 = bytes.decode_u8(7)

	animation
	align_to_velocity = false
	target_anchor_mode = 0
	animation_target_flag
	spread_mode = 0
	emitter_anchor_mode = 0
	handler_index = 0 # unused
	frameset_group_index
	# byte_05 unused
	emitter_flags = 0 # bytes 0x06 and 0x07
	child_death_mode = 0
	child_midlife_mode = 0
	is_velocity_inward = false
	enable_color_curve = false

	var velocity_mode = 0

	# curves
	var interpolation_curve_indicies

	start_position = Vector3.ZERO
	end_position = Vector3.ZERO

	start_position_spread = Vector3.ZERO
	end_position_spread = Vector3.ZERO

	start_angle = Vector3.ZERO
	end_angle = Vector3.ZERO

	start_angle_spread = Vector3.ZERO
	end_angle_spread = Vector3.ZERO

	intertia_min_start = 0
	intertia_max_start = 0
	intertia_min_end = 0
	intertia_max_end = 0

	weight_min_start = 0
	weight_max_start = 0
	weight_min_end = 0
	weight_max_end = 0

	radial_velocity_min_start = 0
	radial_velocity_max_start = 0
	radial_velocity_min_end = 0
	radial_velocity_max_end = 0

	acceleration_min_start = Vector3.ZERO
	acceleration_max_start = Vector3.ZERO
	acceleration_min_end = Vector3.ZERO
	acceleration_max_end = Vector3.ZERO

	drag_min_start = Vector3.ZERO
	drag_max_start = Vector3.ZERO
	drag_min_end = Vector3.ZERO
	drag_max_end = Vector3.ZERO

	lifetime_min_start = 0
	lifetime_max_start = 0
	lifetime_min_end = 0
	lifetime_max_end = 0

	target_offset_start = Vector3.ZERO
	target_offset_end = Vector3.ZERO

	particle_count_start = 0
	particle_count_end = 0

	spawn_interval_start = 0
	spawn_interval_end = 0

	homing_strength_min_start = Vector3.ZERO
	homing_strength_max_start = Vector3.ZERO
	homing_strength_min_end = Vector3.ZERO
	homing_strength_max_end = Vector3.ZERO

	child_emitter_idx_on_death = 0
	child_emitter_idx_on_interval = 0

	
	start_position = Vector3i(bytes.decode_s16(0x14), -bytes.decode_s16(0x16), bytes.decode_s16(0x18))
	end_position = Vector3i(bytes.decode_s16(0x1a), -bytes.decode_s16(0x1c), bytes.decode_s16(0x1e))
	
	animation = VfxAnimation.new()
	animation.screen_offset = animations[anim_index].screen_offset
	animation.animation_frames = animations[anim_index].animation_frames.duplicate_deep()

	var frameset_group_id_offset: int = 0
	for idx: int in emitter.frameset_group_index:
		frameset_group_id_offset += frameset_groups_num_framesets[idx]

	for animation_frame: VfxAnimationFrame in emitter.animation.animation_frames:
		animation_frame.frameset_id += frameset_group_id_offset

	emitters[emitter_id] = emitter
	
	velocity_mode = emitter_flags & 0x0410

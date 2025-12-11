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
var interpolation_curve_indicies: Dictionary[String, int] = {
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

var particle_lifetime_min_start: int = 0
var particle_lifetime_max_start: int = 0
var particle_lifetime_min_end: int = 0
var particle_lifetime_max_end: int = 0

var target_offset_start: Vector3 = Vector3.ZERO
var target_offset_end: Vector3 = Vector3.ZERO

var particle_count_start: int = 0
var particle_count_end: int = 0

var spawn_interval_start: int = 0
var spawn_interval_end: int = 0

var homing_strength_min_start: int = 0
var homing_strength_max_start: int = 0
var homing_strength_min_end: int = 0
var homing_strength_max_end: int = 0

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
	align_to_velocity = motion_type_flag & 1 == 1
	target_anchor_mode = motion_type_flag >> 5
	
	animation_target_flag = bytes.decode_u8(3) 
	spread_mode = animation_target_flag & 1 # 0=sphere, 1=box
	emitter_anchor_mode = (animation_target_flag >> 1) & 7
	handler_index = (animation_target_flag >> 4) & 0x0F # unused
	
	frameset_group_index = bytes.decode_u8(4)
	# byte_05 = bytes.decode_u8(5) # unused
	# color_masking_motion_flags = bytes.decode_u8(6)
	# byte_07 = bytes.decode_u8(7)

	# byte_05 unused
	emitter_flags = bytes.decode_u16(0x06) # bytes 0x06 and 0x07
	child_death_mode = emitter_flags & 3
	child_midlife_mode = (emitter_flags >> 2) & 3
	is_velocity_inward = (emitter_flags >> 4) & 1 == 1
	enable_color_curve = (emitter_flags >> 6) & 1 == 1

	velocity_mode = emitter_flags & 0x0410

	# curves
	interpolation_curve_indicies["POSITION"] = bytes.decode_u8(0x08) & 0xF # lower nibble
	interpolation_curve_indicies["PARTICLE_SPREAD"] = (bytes.decode_u8(0x08) >> 8) & 0xF # upper nibble
	interpolation_curve_indicies["VELOCITY_ANGLE"] = bytes.decode_u8(0x09) & 0xF # lower nibble
	interpolation_curve_indicies["VELOCITY_ANGLE_SPREAD"] = (bytes.decode_u8(0x09) >> 8) & 0xF # upper nibble
	interpolation_curve_indicies["INERTIA"] = bytes.decode_u8(0x0a) & 0xF # lower nibble
	# byte 0x0a upper nibble not used
	interpolation_curve_indicies["WEIGHT"] = bytes.decode_u8(0x0b) & 0xF # lower nibble
	interpolation_curve_indicies["RADIAL_VELOCITY"] = (bytes.decode_u8(0x0b) >> 8) & 0xF # upper nibble
	interpolation_curve_indicies["ACCELERATION"] = bytes.decode_u8(0x0c) & 0xF # lower nibble
	interpolation_curve_indicies["DRAG"] = (bytes.decode_u8(0x0c) >> 8) & 0xF # upper nibble
	interpolation_curve_indicies["PARTICLE_LIFETIME"] = bytes.decode_u8(0x0d) & 0xF # lower nibble
	interpolation_curve_indicies["TARGET_OFFSET"] = (bytes.decode_u8(0x0d) >> 8) & 0xF # upper nibble
	# byte 0x0e low nibble not used
	interpolation_curve_indicies["PARTICLE_COUNT"] = (bytes.decode_u8(0x0e) >> 8) & 0xF # upper nibble
	interpolation_curve_indicies["SPAWN_INTERVAL"] = bytes.decode_u8(0x0f) & 0xF # lower nibble
	interpolation_curve_indicies["HOMING_STRENGTH"] = (bytes.decode_u8(0x0f) >> 8) & 0xF # upper nibble 2 bits?
	interpolation_curve_indicies["HOMING_CURVE"] = (bytes.decode_u8(0x0f) >> 8) & 0xF # upper nibble 2 bits?
	# TODO how is byte 0x0f handled for homing?

	# color curves
	interpolation_curve_indicies["COLOR_R"] = bytes.decode_u8(0x10) & 0xF # lower nibble
	interpolation_curve_indicies["COLOR_G"] = (bytes.decode_u8(0x10) >> 8) & 0xF # upper nibble
	interpolation_curve_indicies["COLOR_B"] = bytes.decode_u8(0x11) & 0xF # lower nibble

	start_position = Vector3(bytes.decode_s16(0x14), -bytes.decode_s16(0x16), bytes.decode_s16(0x18))
	end_position = Vector3(bytes.decode_s16(0x1a), -bytes.decode_s16(0x1c), bytes.decode_s16(0x1e))

	start_position_spread = Vector3(bytes.decode_s16(0x20), bytes.decode_s16(0x22), bytes.decode_s16(0x24))
	end_position_spread = Vector3(bytes.decode_s16(0x26), bytes.decode_s16(0x28), bytes.decode_s16(0x2a))

	start_angle = Vector3(bytes.decode_u16(0x2c), bytes.decode_u16(0x2e), bytes.decode_u16(0x30))
	end_angle = Vector3(bytes.decode_u16(0x32), bytes.decode_u16(0x34), bytes.decode_u16(0x36))

	start_angle_spread = Vector3(bytes.decode_u16(0x38), bytes.decode_u16(0x3a), bytes.decode_u16(0x3c))
	end_angle_spread = Vector3(bytes.decode_u16(0x3e), bytes.decode_u16(0x40), bytes.decode_u16(0x42))

	intertia_min_start = bytes.decode_u16(0x44)
	intertia_max_start = bytes.decode_u16(0x46)
	intertia_min_end = bytes.decode_u16(0x48)
	intertia_max_end = bytes.decode_u16(0x4a)
	
	# bytes 0x4c - 0x52 not used

	weight_min_start = bytes.decode_u16(0x54)
	weight_max_start = bytes.decode_u16(0x56)
	weight_min_end = bytes.decode_u16(0x58)
	weight_max_end = bytes.decode_u16(0x5a)

	radial_velocity_min_start = bytes.decode_u16(0x5c)
	radial_velocity_max_start = bytes.decode_u16(0x5e)
	radial_velocity_min_end = bytes.decode_u16(0x60)
	radial_velocity_max_end = bytes.decode_u16(0x62)

	acceleration_min_start = Vector3(bytes.decode_u16(0x64), bytes.decode_u16(0x68), bytes.decode_u16(0x6c))
	acceleration_max_start = Vector3(bytes.decode_u16(0x66), bytes.decode_u16(0x6a), bytes.decode_u16(0x6e))
	acceleration_min_end = Vector3(bytes.decode_u16(0x70), bytes.decode_u16(0x74), bytes.decode_u16(0x78))
	acceleration_max_end = Vector3(bytes.decode_u16(0x72), bytes.decode_u16(0x76), bytes.decode_u16(0x7a))

	drag_min_start = Vector3(bytes.decode_u16(0x7c), bytes.decode_u16(0x80), bytes.decode_u16(0x84))
	drag_max_start = Vector3(bytes.decode_u16(0x7e), bytes.decode_u16(0x82), bytes.decode_u16(0x86))
	drag_min_end = Vector3(bytes.decode_u16(0x88), bytes.decode_u16(0x8c), bytes.decode_u16(0x90))
	drag_max_end = Vector3(bytes.decode_u16(0x8a), bytes.decode_u16(0x8e), bytes.decode_u16(0x92))

	particle_lifetime_min_start = bytes.decode_u16(0x94)
	particle_lifetime_max_start = bytes.decode_u16(0x96)
	particle_lifetime_min_end = bytes.decode_u16(0x98)
	particle_lifetime_max_end = bytes.decode_u16(0x9a)

	target_offset_start = Vector3(bytes.decode_u16(0x9c), bytes.decode_u16(0x9e), bytes.decode_u16(0xa0))
	target_offset_end = Vector3(bytes.decode_u16(0xa2), bytes.decode_u16(0xa4), bytes.decode_u16(0xa6))

	# bytes 0xa8 - 0xaf not used

	particle_count_start = bytes.decode_u16(0xb0)
	particle_count_end = bytes.decode_u16(0xb2)

	spawn_interval_start = bytes.decode_u16(0xb4)
	spawn_interval_end = bytes.decode_u16(0xb6)

	homing_strength_min_start = bytes.decode_u16(0xb8)
	homing_strength_max_start = bytes.decode_u16(0xba)
	homing_strength_min_end = bytes.decode_u16(0xbc)
	homing_strength_max_end = bytes.decode_u16(0xbe)

	child_emitter_idx_on_death = bytes.decode_u16(0xc0)
	child_emitter_idx_on_interval = bytes.decode_u16(0xc1)

	# bytes 0xc2, 0xc3 not used

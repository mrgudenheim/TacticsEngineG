class_name FftAnimation

var id = 0

var draw_target: Sprite3D
var target_name: String = ""

var seq: Seq
var shp: Shp
var sequence := Sequence.new()

var flipped_v: bool = false # mirrors the animation
var submerged_depth: int = 0
var other_type_index: int = 0
var back_face_offset: int = 0

var time: float = 0
var frame_count: int = 0
var frame_timings: Dictionary[int, float] = {} # [frame number, time when frame should occur]. If framerate independent, time = frame number / animation speed

var parent_anim: FftAnimation = null: # used for nested loops in animations
	get:
		if parent_anim != null:
			return parent_anim.parent_anim
		else:
			return self
	set(value):
		parent_anim = value
var is_primary_anim: bool = true # false if this animation created through an opcode of another animation, such as QueueSpriteAnim
var primary_anim: FftAnimation = self
var primary_anim_opcode_part_id: int = 0 # used for nested loops in animations


func increment_time(delta: float) -> void:
	time += delta


func get_time() -> float:
	return primary_anim.time


func get_frame_count() -> float:
	return primary_anim.frame_count


func get_duplicate() -> FftAnimation:
	var new_fft_animation: FftAnimation = FftAnimation.new()
	new_fft_animation.seq = seq
	new_fft_animation.shp = shp
	new_fft_animation.sequence = sequence
	new_fft_animation.is_primary_anim = is_primary_anim
	new_fft_animation.primary_anim_opcode_part_id = primary_anim_opcode_part_id
	new_fft_animation.flipped_v = flipped_v
	
	return new_fft_animation

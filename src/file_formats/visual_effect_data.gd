class_name VisualEffectData

# https://ffhacktics.com/wiki/Effect_Files
# https://ffhacktics.com/wiki/Effect_Data
var is_initialized: bool = false
var file_name: String = "effect file name"
var vfx_id: int = 0
var ability_names: String = ""

var header_start: int = 0
var section_offsets: PackedInt32Array = []

var frame_sets: Array[VfxFrameSet] = []
var animations: Array[VfxAnimation] = []

class VfxFrameSet:
	var frame_set: Array[VfxFrame] = []

class VfxFrame:
	var vram_bytes: PackedByteArray = []
	var palette_id: int = 0 # 0 = 4bpp, 1 = 8bpp
	var semi_transparency_mode: int = 0
	var image_color_depth: int = 0
	var semi_transparency_on: bool = true
	var frame_width_signed: bool = false
	var frame_height_signed: bool = false
	
	var top_left_uv: Vector2i = Vector2i.ZERO
	var uv_width: int = 0
	var uv_height: int = 0
	var top_left_xy: Vector2i = Vector2i.ZERO
	var top_right_xy: Vector2i = Vector2i.ZERO
	var bottom_left_xy: Vector2i = Vector2i.ZERO
	var bottom_right_xy: Vector2i = Vector2i.ZERO
	var quad_width: float = 0
	var quad_height: float = 0
	var quad_rotation_deg: float = 0
	var quad_vertices: PackedVector3Array = []
	var quad_uvs_pixels: PackedVector2Array = []
	var quad_uvs: PackedVector2Array = []

class VfxAnimation:
	var animation_frames: Array[VfxAnimationFrame]
	var screen_offset: Vector2i

class VfxAnimationFrame:
	var frameset_id: int
	var duration: int
	var byte_02: int

class VfxEmitter:
	var anim_index: int
	var motion_type_flag: int
	var animation_target_flag: int
	var color_masking_motion_flags: int
	var byte_04: int
	var byte_05: int
	var byte_07: int
	var start_position: Vector3i
	var end_position: Vector3i

var script_bytes: PackedByteArray = []
var emitter_control_bytes: PackedByteArray = []
var emitters: Array[VfxEmitter] = []
var timer_data_header_bytes: PackedByteArray = []
var timer_data_bytes: PackedByteArray = []


var vfx_spr: Spr
var texture: Texture2D
var image_color_depth: int = 0 # 8bpp or 4bpp

# SINGLE - camera will point at the targeted location
# SEQUENTIAL - camera will move between each each target
# MULTI - camera will point at a single location, but make sure all targets are in view
enum camera_focus {SINGLE, SEQUENTIAL, MULTI} 

var sound_effects
var partical_effects


enum VfxSections {
	FRAMES = 0,
	ANIMATION = 1,
	VFX_SCRIPT = 2,
	EMITTER_MOTION_CONTROL = 3,
	DIRECTIONS = 4,
	TIMER_DATA_CAMERA_HEADER = 6,
	TIMER_DATA_CAMERA = 7,
	SOUND_EFFECTS = 8,
	PALETTE_IMAGE = 9,
	}


func _init(new_file_name: String = "") -> void:
	file_name = new_file_name
	vfx_id = new_file_name.trim_suffix(".BIN").trim_prefix("E").to_int()


func init_from_file() -> void:
	var vfx_bytes: PackedByteArray = RomReader.get_file_data(file_name)
	
	#### header data
	header_start = RomReader.battle_bin_data.ability_vfx_header_offsets[vfx_id]
	var entry_size = 4
	var num_entries = 10
	var data_bytes: PackedByteArray = vfx_bytes.slice(header_start, header_start + (entry_size * num_entries))
	section_offsets.resize(num_entries)
	for id: int in num_entries:
		section_offsets[id] = data_bytes.decode_u32(id * entry_size) + header_start
	
	#### frame data (and image color depth)
	var section_num = VfxSections.FRAMES
	var section_start: int = section_offsets[section_num]
	data_bytes = vfx_bytes.slice(section_start, section_offsets[section_num + 1])
	
	var initial_offset: int = 4
	initial_offset += data_bytes.decode_u8(0) * 2
	var frame_sets_data_start: int = data_bytes.decode_u16(initial_offset) + 4
	var num_frame_sets: int = (frame_sets_data_start - initial_offset) / 2
	frame_sets.resize(num_frame_sets)
	var frame_set_offsets: PackedInt32Array = []
	frame_set_offsets.resize(num_frame_sets)
	
	for id: int in num_frame_sets:
		var offset: int = data_bytes.decode_u16(initial_offset + (2 * id)) + 4
		if offset == 4:
			num_frame_sets -= 1
			frame_set_offsets.resize(num_frame_sets)
			frame_sets.resize(num_frame_sets)
			continue
		frame_set_offsets[id] = offset
	
	# image color depth from first frame in first frame_set
	if data_bytes.decode_u8(frame_set_offsets[0]) & 0x80 == 0 and data_bytes.decode_u8(0) == 1:
		image_color_depth = 4
	else:
		image_color_depth = 8
	
	# frame sets
	for frame_set_id: int in num_frame_sets:
		var frame_set: VfxFrameSet = VfxFrameSet.new()
		
		var next_section_start: int = data_bytes.size()
		if frame_set_id < num_frame_sets - 1:
			next_section_start = frame_set_offsets[frame_set_id + 1]
		
		var frame_set_bytes: PackedByteArray = data_bytes.slice(frame_set_offsets[frame_set_id], next_section_start)
		var frame_data_length: int = 0x18
		var num_frames: int = (frame_set_bytes.size() - 4) / frame_data_length
		frame_set.frame_set.resize(num_frames)
		for frame_id: int in num_frames:
			var frame_bytes: PackedByteArray = frame_set_bytes.slice(4 + (frame_id * frame_data_length))
			var new_frame: VfxFrame = VfxFrame.new()
			new_frame.vram_bytes = frame_bytes.slice(0, 4)
			new_frame.palette_id = new_frame.vram_bytes[0] & 0x0f
			new_frame.semi_transparency_mode = (new_frame.vram_bytes[0] & 0x60) >> 5
			new_frame.image_color_depth = 4 + ((new_frame.vram_bytes[0] & 0x80) >> 5)
			new_frame.semi_transparency_on = (new_frame.vram_bytes[1] & 0x02) == 0x02
			new_frame.frame_width_signed = (new_frame.vram_bytes[1] & 0x10) == 0x10
			new_frame.frame_height_signed = (new_frame.vram_bytes[1] & 0x20) == 0x20
			
			var top_left_u: int = frame_bytes.decode_u8(4)
			var top_left_v: int = frame_bytes.decode_u8(5)
			new_frame.top_left_uv = Vector2i(top_left_u, top_left_v)
			
			if new_frame.frame_width_signed:
				new_frame.uv_width = frame_bytes.decode_s8(6)
			else:
				new_frame.uv_width = frame_bytes.decode_u8(6)
			if new_frame.frame_height_signed:
				new_frame.uv_height = frame_bytes.decode_s8(7)
			else:
				new_frame.uv_height = frame_bytes.decode_u8(7)
			#new_frame.uv_width = frame_bytes.decode_s8(6)
			#new_frame.uv_height = frame_bytes.decode_s8(7)
			var top_left_x: int = frame_bytes.decode_s16(8)
			var top_left_y: int = frame_bytes.decode_s16(0xa)
			new_frame.top_left_xy = Vector2i(top_left_x, top_left_y)
			var top_right_x: int = frame_bytes.decode_s16(0xc)
			var top_right_y: int = frame_bytes.decode_s16(0xe)
			new_frame.top_right_xy = Vector2i(top_right_x, top_right_y)
			var bottom_left_x: int = frame_bytes.decode_s16(0x10)
			var bottom_left_y: int = frame_bytes.decode_s16(0x12)
			new_frame.bottom_left_xy = Vector2i(bottom_left_x, bottom_left_y)
			var bottom_right_x: int = frame_bytes.decode_s16(0x14)
			var bottom_right_y: int = frame_bytes.decode_s16(0x16)
			new_frame.bottom_right_xy = Vector2i(bottom_right_x, bottom_right_y)
			var vertices_xy: PackedVector2Array = []
			vertices_xy.append(new_frame.top_left_xy)
			vertices_xy.append(new_frame.top_right_xy)
			vertices_xy.append(new_frame.bottom_left_xy)
			vertices_xy.append(new_frame.bottom_right_xy)
			
			new_frame.quad_uvs_pixels.append(Vector2(top_left_u, top_left_v)) # top left
			new_frame.quad_uvs_pixels.append(Vector2((top_left_u + new_frame.uv_width), top_left_v)) # top right
			new_frame.quad_uvs_pixels.append(Vector2(top_left_u, (top_left_v + new_frame.uv_height))) # bottom left
			new_frame.quad_uvs_pixels.append(Vector2((top_left_u + new_frame.uv_width), (top_left_v + new_frame.uv_height))) # bottom right
			
			new_frame.quad_width = new_frame.top_left_xy.distance_to(new_frame.top_right_xy)
			new_frame.quad_height = new_frame.top_left_xy.distance_to(new_frame.bottom_left_xy)
			new_frame.quad_rotation_deg = rad_to_deg(Vector2(new_frame.top_right_xy - new_frame.top_left_xy).angle())
			
			for vertex_idx: int in vertices_xy.size():
				new_frame.quad_vertices.append(Vector3(vertices_xy[vertex_idx].x, -vertices_xy[vertex_idx].y, 0) * MapData.SCALE)
			
			frame_set.frame_set[frame_id] = new_frame
		
		frame_sets[frame_set_id] = frame_set
	
	
	### animation data
	section_num = VfxSections.ANIMATION
	section_start = section_offsets[section_num]
	data_bytes = vfx_bytes.slice(section_start, section_offsets[section_num + 1])
	
	var num_animations: int = data_bytes.decode_u32(0)
	animations.resize(num_animations)
	for anim_id: int in num_animations:
		var anim_start_offset: int = data_bytes.decode_u16(4 + (anim_id * 2)) + 4
		var anim_end: int = data_bytes.size()
		if anim_id < num_animations - 1:
			anim_end = data_bytes.decode_u16(4 + ((anim_id + 1) * 2)) + 4
		
		var anim_bytes: PackedByteArray = data_bytes.slice(anim_start_offset, anim_end)
		var animation: VfxAnimation = VfxAnimation.new()
		
		var screen_offset_x: int = anim_bytes.decode_s16(1)
		var screen_offset_y: int = anim_bytes.decode_s16(3)
		animation.screen_offset = Vector2i(screen_offset_x, screen_offset_y)
		
		# TODO do something when it references beyond the last frame? Figure out byte_02
		var byte_index: int = 5
		while byte_index + 3 < anim_bytes.size():
			var anim_frame_data: VfxAnimationFrame = VfxAnimationFrame.new()
			anim_frame_data.frameset_id = anim_bytes.decode_u8(byte_index)
			anim_frame_data.duration = anim_bytes.decode_u8(byte_index + 1)
			anim_frame_data.byte_02 = anim_bytes.decode_u8(byte_index + 2) 
			animation.animation_frames.append(anim_frame_data)
			byte_index += 3
		
		animations[anim_id] = animation
	
	
	### script data
	section_num = VfxSections.VFX_SCRIPT
	section_start = section_offsets[section_num]
	script_bytes = vfx_bytes.slice(section_start, section_offsets[section_num + 1])
	
	# TODO extract relevant data from effect script; 
	
	### TODO emitter control data
	section_num = VfxSections.EMITTER_MOTION_CONTROL
	section_start = section_offsets[section_num]
	emitter_control_bytes = vfx_bytes.slice(section_start, section_offsets[section_num + 1])
	
	var num_emitters: int = emitter_control_bytes.decode_u16(2)
	emitters.resize(num_emitters)
	
	for emitter_id: int in num_emitters:
		var emitter_data_start: int = 0x14 + (196 * emitter_id)
		var emitter_data_bytes: PackedByteArray = emitter_control_bytes.slice(emitter_data_start, emitter_data_start + 196)
		var emitter: VfxEmitter = VfxEmitter.new()
		
		emitter.anim_index = emitter_data_bytes.decode_u8(1)
		emitter.motion_type_flag = emitter_data_bytes.decode_u8(2)
		emitter.animation_target_flag = emitter_data_bytes.decode_u8(3)
		emitter.byte_04 = emitter_data_bytes.decode_u8(4)
		emitter.byte_05 = emitter_data_bytes.decode_u8(5)
		emitter.color_masking_motion_flags = emitter_data_bytes.decode_u8(6)
		emitter.byte_07 = emitter_data_bytes.decode_u8(7)
		
		emitter.start_position = Vector3i(emitter_data_bytes.decode_s16(0x14), emitter_data_bytes.decode_s16(0x16), emitter_data_bytes.decode_s16(0x18))
		emitter.end_position = Vector3i(emitter_data_bytes.decode_s16(0x1a), emitter_data_bytes.decode_s16(0x1c), emitter_data_bytes.decode_s16(0x1e))
		
		emitters[emitter_id] = emitter
	
	# TODO extract relevant data from emitter data
	
	### TODO timer header data
	section_num = VfxSections.TIMER_DATA_CAMERA_HEADER
	section_start = section_offsets[section_num]
	timer_data_header_bytes = vfx_bytes.slice(section_start, section_offsets[section_num + 1])
	
	
	
	### TODO timer data
	section_num = VfxSections.TIMER_DATA_CAMERA
	section_start = section_offsets[section_num]
	timer_data_bytes = vfx_bytes.slice(section_start, section_offsets[section_num + 1])
	
	var effect_start_time: int = timer_data_bytes.decode_u16(4)
	var target_switching_delay: int = timer_data_bytes.decode_u16(6)
	var effect_max_duration_per_target: int = timer_data_bytes.decode_u16(10)
	
	# TODO 5 timing sections, 0x80 long each
	
	
	#### image and palette data
	section_num = VfxSections.PALETTE_IMAGE
	section_start = section_offsets[section_num]
	data_bytes = vfx_bytes.slice(section_start)
	
	var palette_bytes: PackedByteArray = []
	if image_color_depth == 8:
		palette_bytes = data_bytes.slice(0, 512)
	elif image_color_depth == 4:
		palette_bytes = data_bytes.slice(512, 1024)
	else:
		push_warning(file_name + " image_color_depth not set")
	
	vfx_spr = Spr.new(file_name)
	vfx_spr.bits_per_pixel = image_color_depth
	vfx_spr.pixel_data_start = 1024 + 4
	vfx_spr.num_colors = 256
	var image_size_bytes: PackedByteArray = data_bytes.slice(1024, 1024 + 4)
	if image_color_depth == 8 and image_size_bytes[2] == 0x01 and image_size_bytes[3] == 0x01:
		vfx_spr.width = 256
		vfx_spr.height = 256
	else:
		vfx_spr.height = image_size_bytes[1] * 2
		vfx_spr.width = 1024 / image_color_depth
	
	vfx_spr.has_compressed = false
	vfx_spr.num_pixels = vfx_spr.width * vfx_spr.height
	vfx_spr.set_palette_data(palette_bytes)
	vfx_spr.color_indices = vfx_spr.set_color_indices(data_bytes.slice(1024 + 4))
	
	# TODO fix transparency - some frames should be opaque, like summons (Odin), some should just be less transparent, like songs and some geomancy (waterfall)
	
	#vfx_spr.color_palette[vfx_spr.color_indices[0]].a8 = 0 # set background color (ie. color of top left pixel) as transparent
	
	vfx_spr.set_pixel_colors()
	vfx_spr.spritesheet = vfx_spr.get_rgba8_image()
	
	texture = ImageTexture.create_from_image(vfx_spr.spritesheet)
	
	# set frame uvs based on spr
	for frameset_idx: int in frame_sets.size():
		for frame_idx: int in frame_sets[frameset_idx].frame_set.size():
			var vfx_frame: VfxFrame = frame_sets[frameset_idx].frame_set[frame_idx]
			vfx_frame.quad_uvs.resize(vfx_frame.quad_uvs_pixels.size())
			for vert_idx: int in vfx_frame.quad_uvs_pixels.size():
				vfx_frame.quad_uvs[vert_idx] = Vector2(vfx_frame.quad_uvs_pixels[vert_idx].x / float(vfx_spr.width), 
					vfx_frame.quad_uvs_pixels[vert_idx].y / float(vfx_spr.height))
	
	is_initialized = true


func get_frame_mesh(frame_set_idx: int, frame_idx: int = 0) -> ArrayMesh:
	var vfx_frame: VfxFrame = frame_sets[frame_set_idx].frame_set[frame_idx]
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for vert_index: int in [0, 1, 2]:
		#st.set_normal(quad_normals[vert_index] * SCALE)
		st.set_uv(vfx_frame.quad_uvs[vert_index])
		st.set_color(Color.WHITE)
		st.add_vertex(vfx_frame.quad_vertices[vert_index])
	
	for vert_index: int in [2, 1, 3]:
		#st.set_normal(quad_normals[vert_index] * SCALE)
		st.set_uv(vfx_frame.quad_uvs[vert_index])
		st.set_color(Color.WHITE)
		st.add_vertex(vfx_frame.quad_vertices[vert_index])
	
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	
	var mesh_material: StandardMaterial3D
	var albedo_texture: Texture2D = texture
	mesh_material = StandardMaterial3D.new()
	mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	#mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mesh_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	#mesh_material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mesh_material.vertex_color_use_as_albedo = true
	
	
	# TODO maybe byte 1, bit 0x02 turns semi-transparency on or off?
	# Mostly (only?) affects Summon's creature and texture squares, meteor, pitfall, carve model, local quake, small bomb, empty black squares on some others
	#var semi_transparency_on = ((vfx_frame.vram_bytes[1] & 0x02) >> 1) == 1
	if vfx_frame.semi_transparency_on:
		#var semi_transparency_mode = (vfx_frame.vram_bytes[0] & 0x60) >> 5 # TODO maybe byte 0, bit 0x60 is semi-transparency mode?
		if vfx_frame.semi_transparency_mode == 0: # 0.5 back + 0.5 forward
			#albedo_texture = ImageTexture.create_from_image(image_mode_0)
			mesh_material.albedo_color = Color(1, 1, 1, 0.5)
			mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh_material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		elif vfx_frame.semi_transparency_mode == 1: # 1 back + 1 forward
			#albedo_texture = ImageTexture.create_from_image(vfx_spr.spritesheet)
			#albedo_texture = ImageTexture.create_from_image(image_mode_0)
			#mesh_material.albedo_color = Color(0.75, 0.75, 0.75, 1)
			mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		elif vfx_frame.semi_transparency_mode == 2: # 1 back - 1 forward
			#albedo_texture = ImageTexture.create_from_image(vfx_spr.spritesheet)
			mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh_material.blend_mode = BaseMaterial3D.BLEND_MODE_SUB
		elif vfx_frame.semi_transparency_mode == 3: # 1 back + 0.25 forward
			#albedo_texture = ImageTexture.create_from_image(image_mode_3)
			mesh_material.albedo_color = Color(0.25, 0.25, 0.25, 1)
			mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			#mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			#mesh_material.alpha_scissor_threshold = 0.01
	else:
		mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		mesh_material.alpha_scissor_threshold = 0.5
	
	mesh_material.set_texture(BaseMaterial3D.TEXTURE_ALBEDO, albedo_texture)
	mesh.surface_set_material(0, mesh_material)
	
	return mesh

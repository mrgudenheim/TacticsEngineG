class_name Map
extends StaticBody3D

@export var mesh: MeshInstance3D
@export var collision_shape: CollisionShape3D
var map_data: MapData


func play_animations(local_map_data: MapData) -> void:
	# set up shader parameters for uv_animations
	var canvas_positions: PackedVector2Array = []
	var canvas_sizes: PackedVector2Array = []
	var frame_positions: PackedVector2Array = []
	var frame_idxs: PackedFloat32Array = []
	
	var num_texture_animations: int = local_map_data.texture_animations.size()
	canvas_positions.resize(num_texture_animations)
	canvas_sizes.resize(num_texture_animations)
	frame_positions.resize(num_texture_animations)
	frame_idxs.resize(num_texture_animations)
	
	for anim_id: int in num_texture_animations: # TODO convert these values from pixels to UV space (0.0 - 1.0)
		canvas_positions[anim_id] = Vector2(local_map_data.texture_animations[anim_id].canvas_x / MapData.TEXTURE_SIZE.x, 
				local_map_data.texture_animations[anim_id].canvas_y / MapData.TEXTURE_SIZE.y)
		canvas_sizes[anim_id] = Vector2(local_map_data.texture_animations[anim_id].canvas_width / MapData.TEXTURE_SIZE.x, 
				local_map_data.texture_animations[anim_id].canvas_height / MapData.TEXTURE_SIZE.y)
		frame_positions[anim_id] = Vector2(local_map_data.texture_animations[anim_id].frame1_x / MapData.TEXTURE_SIZE.x, 
				local_map_data.texture_animations[anim_id].frame1_y / MapData.TEXTURE_SIZE.y)
	
	var map_shader_material: ShaderMaterial = mesh.material_override as ShaderMaterial
	map_shader_material.set_shader_parameter("canvas_pos", canvas_positions)
	map_shader_material.set_shader_parameter("canvas_size", canvas_sizes)
	map_shader_material.set_shader_parameter("frame_pos", frame_positions)
	map_shader_material.set_shader_parameter("frame_idx", frame_idxs)
	
	# start animations
	for anim_id: int in num_texture_animations:
		if [0x03, 0x04].has(local_map_data.texture_animations[anim_id].anim_technique): # if palette animation
			local_map_data.animate_palette(local_map_data.texture_animations[anim_id], self)
		elif [0x01, 0x02].has(local_map_data.texture_animations[anim_id].anim_technique): # if uv animation
			local_map_data.animate_uv(local_map_data.texture_animations[anim_id], self, anim_id)
		

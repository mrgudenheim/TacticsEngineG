class_name Map
extends StaticBody3D

@export var mesh: MeshInstance3D
@export var collision_shape: CollisionShape3D
var map_data: MapData


func play_animations(local_map_data: MapData) -> void:
	var colors_per_palette: int = 16
	
	for anim_id: int in local_map_data.texture_animations.size():
		if [0x03, 0x04].has(local_map_data.texture_animations[anim_id].anim_technique): # if palette animation
			local_map_data.animate_palette(local_map_data.texture_animations[anim_id], self)
			#var frame_id: int = 0
			#var dir: int = 1
			#while frame_id < texture_anim.num_frames:
				#swap_palette(texture_anim.palette_id_to_animate, texture_animations_palette_frames[frame_id + texture_anim.animation_starting_index], map)
				##map.mesh.mesh = mesh
				#await Engine.get_main_loop().create_timer(texture_anim.frame_duration / float(30)).timeout
				#if texture_anim.anim_technique == 0x3: # loop forward
					#frame_id += dir
					#frame_id = frame_id % texture_anim.num_frames
				#elif texture_anim.anim_technique == 0x4: # loop back and forth
					#if frame_id == texture_anim.num_frames - 1:
						#dir = -1
					#elif frame_id == 0:
						#dir = 1
					#frame_id += dir
			
			#var new_palette: PackedColorArray = local_map_data.texture_animations_palette_frames
			#var new_texture_palette: PackedColorArray = local_map_data.texture_palettes.duplicate()
			#for color_id in colors_per_palette:
				#new_texture_palette[color_id + (local_map_data.texture_animations[anim_id].palette_id_to_animate * colors_per_palette)]
			#
			#(mesh.material_override as ShaderMaterial).set_shader_parameter("palettes_colors", new_texture_palette)

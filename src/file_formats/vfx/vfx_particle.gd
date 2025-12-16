class_name VfxParticle
extends Node3D

var vfx_data: VisualEffectData # used to get texture, other data
var emitter_data: VfxEmitter
var lifetime: int = 0 # 0xFFFF - particle dies when animation frame duration = 0
var animation: VisualEffectData.VfxAnimation

var current_animation_frame: VisualEffectData.VfxAnimationFrame

func _init(new_vfx_data: VisualEffectData, new_emitter_data: VfxEmitter):
	vfx_data = new_vfx_data
	emitter_data = new_emitter_data
	animation = new_emitter_data.animation
	lifetime = emitter_data.particle_lifetime_min_start


func play_animation() -> void:
	if lifetime != 0xFFFF:
		get_tree().create_timer(lifetime * 3.0 / vfx_data.animation_speed).timeout.connect(queue_free)
	
	var camera_right: Vector3 = get_viewport().get_camera_3d().basis * Vector3.RIGHT
	var screen_space_x: Vector3 = (animation.screen_offset.x * camera_right)
	var screen_space_y: Vector3 = Vector3(0, -animation.screen_offset.y, 0)
	position = (screen_space_x + screen_space_y) * MapData.SCALE 

	for anim_frame_idx: int in animation.animation_frames.size():
		var vfx_anim_frame: VisualEffectData.VfxAnimationFrame = animation.animation_frames[anim_frame_idx]
		current_animation_frame = vfx_anim_frame
		
		if vfx_anim_frame.frameset_id == 0x83: # move anim_location, handle anim_location 0x83 movement as screen_space movement instead of world space
			var screen_space_offset_x: Vector3 = (vfx_anim_frame.duration * camera_right)
			var screen_space_offset_y: Vector3 = Vector3(0, -vfx_anim_frame.byte_02, 0)
			position += (screen_space_offset_x + screen_space_offset_y) * MapData.SCALE # byte01 is actually the X movement in function 0x83, not the duration
			continue
		elif vfx_anim_frame.frameset_id == 0x81: # start animation over
			play_animation()
			return
		elif vfx_anim_frame.frameset_id >= vfx_data.framesets.size():
			push_warning(vfx_data.file_name + " frameset_id: " + str(vfx_anim_frame.frameset_id)) # TODO fix special frame_id codes, >= 0x80 (128)
			continue
		
		# get composite frame
		for frame_idx: int in vfx_data.framesets[vfx_anim_frame.frameset_id].frameset.size():
			var vfx_frame_mesh: MeshInstance3D = MeshInstance3D.new()
			vfx_frame_mesh.name = "frame " + str(frame_idx)
			#mesh_instance.mesh = frame_meshes[frame_mesh_idx]
			vfx_frame_mesh.mesh = vfx_data.get_frame_mesh(vfx_anim_frame.frameset_id, frame_idx)
			#vfx_frame_mesh.scale.y = -1
			add_child(vfx_frame_mesh)
		
		if vfx_anim_frame.duration == 0 and lifetime == 0xFFFF: # end animation if lifetime is controlled by animation
			queue_free()
		elif vfx_anim_frame.duration == 0: # hold frame indefinitely
			return
		else:
			if vfx_anim_frame.duration < 0:
				vfx_anim_frame.duration += 256 # convert signed byte to unsigned 
			await get_tree().create_timer(vfx_anim_frame.duration / vfx_data.animation_speed).timeout
		
		# if particle == null:
		# 	break
		
		# clear composite frame
		var children := get_children()
		for child: Node in children:
			child.queue_free()

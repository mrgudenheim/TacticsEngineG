class_name AbilityData

# https://ffhacktics.com/wiki/Ability_Data
# https://ffhacktics.com/wiki/BATTLE.BIN_Data_Tables#Animation_.26_Display_Related_Data

enum AbilityType {
	NONE,
	NORMAL,
	ITEM,
	THROWING,
	JUMPING,
	AIM,
	MATH_SKILL,
	REACTION,
	SUPPORT,
	MOVEMENT,
	UNKNOWN1,
	UNKNOWN2,
	UNKNOWN3,
	UNKNOWN4,
	UNKNOWN5,
	UNKNOWN6,
	}

var id: int = 0
var name: String = "ability name"
var spell_quote: String = "spell quote"
var jp_cost: int = 0
var chance_to_learn: float = 100 # percent
var ability_type: AbilityType = AbilityType.NORMAL

var formula # TODO store Callable?
var formula_id: int = 0
var formula_x: int = 0
var formula_y: int = 0
var targeting_range: int = 1
var effect_radius: int = 1
var vertical_tolerance: int = 2
var inflict_status_id: int = 0
var ticks_charge_time: int = 0
var mp_cost: int = 0

var animation_charging_set_id: int # BATTLE.BIN offset="2ce10" - table of animations IDs used by Ability ID - byte 1
var animation_start_id: int
var animation_charging_id: int
var animation_executing_id: int # BATTLE.BIN offset="2ce10" - table of animations IDs used by Ability ID - byte 2
var animation_text_id: int # BATTLE.BIN offset="2ce10" - table of animations IDs used by Ability ID - byte 3
var effect_text: String = "ability effect"

var vfx_data: VisualEffectData # BATTLE.BIN offset="14F3F0" - table of Effect IDs used by Ability ID
var vfx_id: int = 0

var animation_speed: float = 59 # frames per second

func _init(new_id: int = 0) -> void:
	id = new_id
	
	name = RomReader.fft_text.ability_names[id]
	spell_quote = RomReader.fft_text.spell_quotes[id]
	
	animation_charging_set_id = RomReader.battle_bin_data.ability_animation_charging_set_ids[new_id]
	animation_start_id = RomReader.battle_bin_data.ability_animation_start_ids[animation_charging_set_id] * 2
	animation_charging_id = RomReader.battle_bin_data.ability_animation_charging_ids[animation_charging_set_id] * 2
	animation_executing_id = RomReader.battle_bin_data.ability_animation_executing_ids[new_id] * 2
	animation_text_id = RomReader.battle_bin_data.ability_animation_text_ids[new_id]
	effect_text = RomReader.fft_text.battle_effect_text[animation_text_id]
	vfx_id = RomReader.battle_bin_data.ability_vfx_ids[new_id]
	if [0x11d, 0x11f].has(vfx_id): # Ball
		vfx_data = RomReader.vfx[0] # TODO handle special cases without vfx files, 0x11d (Ball), 0x11f (ability 0x2d)
	elif vfx_id < RomReader.NUM_VFX:
		RomReader.vfx[vfx_id].ability_names += name + " "
		vfx_data = RomReader.vfx[vfx_id]
	elif vfx_id == 0xffff:
		vfx_data = RomReader.vfx[0] # TODO handle when vfx_id is 0xffff
	else:
		vfx_data = RomReader.vfx[0]
		#push_warning(vfx_id)
	
	jp_cost = RomReader.scus_data.jp_costs[new_id]
	chance_to_learn = RomReader.scus_data.chance_to_learn[new_id]
	ability_type = RomReader.scus_data.ability_types[new_id]
	formula_id = RomReader.scus_data.formula_id[new_id]
	formula_x = RomReader.scus_data.formula_x[new_id]
	formula_y = RomReader.scus_data.formula_y[new_id]
	targeting_range = RomReader.scus_data.ranges[new_id]
	effect_radius = RomReader.scus_data.effect_radius[new_id]
	vertical_tolerance = RomReader.scus_data.vertical_tolerance[new_id]
	inflict_status_id = RomReader.scus_data.inflict_status_id[new_id]
	ticks_charge_time = RomReader.scus_data.ct[new_id]


func display_vfx(location: Node3D) -> void:
	#if vfx_id == 163: # TODO handle vfx other than stasis sword
		#display_stasis_sword_vfx(location)
		#return
	
	var children: Array[Node] = location.get_children()
	for child: Node in children:
		child.queue_free()
	
	#var frame_meshes: Array[ArrayMesh] = []
	#for frameset_idx: int in range(0, num_framesets):
		#frame_meshes.append(vfx_data.get_frame_mesh(frameset_idx))
	
	# TODO show vfx animations on emitters, get correct position of vfx
	
	for emitter_idx: int in vfx_data.emitters.size():
		var emitter := vfx_data.emitters[emitter_idx]
		
		var emitter_location: Node3D = Node3D.new()
		emitter_location.position = emitter.start_position * MapData.SCALE
		location.add_child(emitter_location)
	
	#for anim_idx: int in vfx_data.animations.size():
		#var vfx_animation := vfx_data.animations[anim_idx]
		
		var vfx_animation := vfx_data.animations[emitter.anim_index]
		var anim_location: Node3D = Node3D.new()
		anim_location.position = Vector3(vfx_animation.screen_offset.x, -vfx_animation.screen_offset.y, 0) * MapData.SCALE
		emitter_location.add_child(anim_location)
		
		for anim_frame_idx: int in vfx_animation.animation_frames.size():
			var vfx_anim_frame := vfx_animation.animation_frames[anim_frame_idx]
			
			if vfx_anim_frame.frameset_id >= vfx_data.frame_sets.size(): # TODO vfx animation figure out code 0x83
				push_warning(name + " frameset_id: " + str(vfx_anim_frame.frameset_id))
				continue
			
			# get composite frame
			for frame_idx: int in vfx_data.frame_sets[vfx_anim_frame.frameset_id].frame_set.size():
				var vfx_frame_mesh: MeshInstance3D = MeshInstance3D.new()
				#mesh_instance.mesh = frame_meshes[frame_mesh_idx]
				vfx_frame_mesh.mesh = vfx_data.get_frame_mesh(vfx_anim_frame.frameset_id, frame_idx)
				#vfx_frame_mesh.scale.y = -1
				anim_location.add_child(vfx_frame_mesh)
			
			if vfx_anim_frame.duration == 0: # TODO handle vfx animation with duration 00 corretly
				await anim_location.get_tree().create_timer(10 / animation_speed).timeout
			else:
				await anim_location.get_tree().create_timer(vfx_anim_frame.duration / animation_speed).timeout
			
			# clear composite frame
			children = anim_location.get_children()
			for child: Node in children:
				child.queue_free()
		
		emitter_location.queue_free()
	
	
	# show each frameset
	#for frameset_idx: int in vfx_data.frame_sets.size():
		#for frame_idx: int in vfx_data.frame_sets[frameset_idx].frame_set.size():
			#var mesh_instance: MeshInstance3D = MeshInstance3D.new()
			##mesh_instance.mesh = frame_meshes[frame_mesh_idx]
			#mesh_instance.mesh = vfx_data.get_frame_mesh(frameset_idx, frame_idx)
			#location.add_child(mesh_instance)
			#
			#mesh_instance.position.y += 5
			#var target_pos: Vector3 = Vector3.ZERO
			#
			## https://docs.godotengine.org/en/stable/classes/class_tween.html
			#var tween: Tween = location.create_tween()
			#tween.tween_property(mesh_instance, "position", target_pos, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		#
		#await location.get_tree().create_timer(0.4).timeout
	#
	#await location.get_tree().create_timer(0.4).timeout
	#
	#children = location.get_children()
	#for child: Node in children:
		#child.queue_free()
	location.queue_free()

func display_stasis_sword_vfx(location: Node3D) -> void:
	if vfx_id != 163: # TODO handle vfx other than stasis sword
		return
	
	var children: Array[Node] = location.get_children()
	for child: Node in children:
		child.queue_free()
	
	var frame_meshes: Array[ArrayMesh] = []
	for frameset_idx: int in [0, 1, 2, 17, 34, 55, 76, 98, 110]:
		frame_meshes.append(vfx_data.get_frame_mesh(frameset_idx))
	
	for frame_mesh_idx: int in range(2, frame_meshes.size() - 2):
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		mesh_instance.mesh = frame_meshes[frame_mesh_idx]
		location.add_child(mesh_instance)
		
		mesh_instance.position.y += 5
		var target_pos: Vector3 = Vector3.ZERO
		if frame_mesh_idx == 5:
			target_pos.y -= 15 * MapData.SCALE
		
		# https://docs.godotengine.org/en/stable/classes/class_tween.html
		var tween: Tween = location.create_tween()
		tween.tween_property(mesh_instance, "position", target_pos, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		await location.get_tree().create_timer(0.4).timeout
	
	await location.get_tree().create_timer(0.4).timeout
	
	children = location.get_children() # store current children to remove later
	
	for frame_mesh_idx: int in [0, 1]:
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		mesh_instance.mesh = frame_meshes[frame_mesh_idx]
		location.add_child(mesh_instance)
	
	await location.get_tree().create_timer(0.2).timeout
	
	for child: Node in children:
		child.queue_free()
	
	await location.get_tree().create_timer(0.6).timeout
	
	children = location.get_children()
	for child: Node in children:
		child.queue_free()
	location.queue_free()

class_name Map
extends StaticBody3D

@export var mesh: MeshInstance3D
@export var collision_shape: CollisionShape3D

func play_animations(map_data: MapData) -> void:
	for anim_id: int in map_data.texture_animations.size():
		if [0x03, 0x04].has(map_data.texture_animations[anim_id].anim_technique): # if palette animation
			map_data.animate_palette(map_data.texture_animations[anim_id], self)

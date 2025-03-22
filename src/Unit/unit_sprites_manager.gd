class_name UnitSpritesManager
extends Node3D

const LAYERING_OFFSET: float = 0.001

@export var sprite_primary: Sprite3D
@export var sprite_weapon: Sprite3D
@export var sprite_effect: Sprite3D
@export var sprite_text: Sprite3D

@export var sprite_item: Sprite3D
@export var sprite_background: Sprite3D

@export var pivot_primary: Node3D
@export var pivot_weapon: Node3D
@export var pivot_effect: Node3D
@export var pivot_text: Node3D



func reset_sprites(flip_h: bool = false) -> void:
	# reset position
	self.position = Vector3.ZERO
	sprite_item.position = Vector3.ZERO
	sprite_item.rotation = Vector3.ZERO
	sprite_item.texture = ImageTexture.create_from_image(Image.create_empty(120, 120, false, Image.FORMAT_RGBA8)) # TODO don't create texture every time...
	
	# reset layer priority
	sprite_primary.position.z = -2 * LAYERING_OFFSET
	sprite_weapon.position.z = -3 * LAYERING_OFFSET
	#sprite_weapon.frame = 511 # TODO fix setting blank, set visible = false?
	sprite_weapon.frame = (sprite_weapon.hframes * sprite_weapon.vframes) - 1
	#sprite_weapon.visible = false
	#sprite_weapon.texture = ImageTexture.create_from_image(Image.create_empty(120, 120, false, Image.FORMAT_RGBA8))
	sprite_effect.position.z = -1 * LAYERING_OFFSET
	#sprite_effect.frame = 255 # TODO fix setting blank, set visible = false?
	sprite_effect.frame = (sprite_effect.hframes * sprite_effect.vframes) - 1
	#sprite_effect.visible = false
	#sprite_effect.texture = ImageTexture.create_from_image(Image.create_empty(120, 120, false, Image.FORMAT_RGBA8))
	sprite_text.position.z = 0 * LAYERING_OFFSET
	
	pivot_primary.rotation_degrees.y = 0
	pivot_weapon.rotation_degrees.y = 0
	pivot_effect.rotation_degrees.y = 0
	pivot_text.rotation_degrees.y = 0
	
	
	#sprite_primary.z_index = -2
	#sprite_weapon.z_index = -3
	#sprite_effect.z_index = -1
	#sprite_text.z_index = 0
	
	# reset flip_h
	sprite_primary.flip_h = flip_h
	sprite_weapon.flip_h = flip_h
	sprite_effect.flip_h = flip_h
	sprite_text.flip_h = flip_h
	
	# reset flip_v
	sprite_primary.flip_v = false
	sprite_weapon.flip_v = false
	sprite_effect.flip_v = false
	sprite_text.flip_v = false


func flip_h() -> void:
	sprite_primary.flip_h = not sprite_primary.flip_h
	sprite_weapon.flip_h = not sprite_weapon.flip_h
	sprite_effect.flip_h = not sprite_effect.flip_h
	sprite_item.flip_h = not sprite_item.flip_h

class_name VfxParticle
extends Node3D

var vfx_data: VisualEffectData # used to get texture, other data
var lifetime: int = 0 # 0xFFFF - particle dies when animation frame duration = 0
var animation: VisualEffectData.VfxAnimation


func _init(new_vfx_data: VisualEffectData, new_animation: VisualEffectData.VfxAnimation):
	vfx_data = new_vfx_data
	animation = new_animation

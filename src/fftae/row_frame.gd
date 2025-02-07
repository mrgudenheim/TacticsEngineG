class_name FrameRow
extends MarginContainer

@export var frame_label: Label
@export var rotation_label: Label
@export var subframes_label: Label
@export var preview_rect: TextureRect
@export var button: Button

@export var frame_id: int:
	get:
		return frame_id
	set(value):
		frame_id = value
		frame_label.text = "%s (0x%02x)" % [value, value]

@export var frame_rotation: int:
	get:
		return frame_rotation
	set(value):
		frame_rotation = value
		rotation_label.text = str(value)
		#rotation_spinbox.value_changed.emit(value)

@export var subframes_text: String:
	get:
		return subframes_label.text
	set(text):
		subframes_label.text = text

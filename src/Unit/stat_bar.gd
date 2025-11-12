class_name StatBar
extends TextureProgressBar

@export var name_label: Label
@export var value_label: Label
@export var visual_max: float = 0.0:
	set(new_value):
		visual_max = new_value
		max_value = visual_max

@export var show_name: bool = false:
	set(new_value):
		show_name = new_value
		name_label.visible = new_value

@export var show_value: bool = false:
	set(new_value):
		show_value = new_value
		value_label.visible = new_value

@export var fill_color: Color = Color.WHITE:
	set(new_value):
		fill_color = new_value
		tint_progress = new_value


func set_stat(stat_name: String, stat: ClampedValue) -> void:
	name_label.text = stat_name
	update_stat(stat)
	
	stat.changed.connect(update_stat)


func update_stat(stat: ClampedValue) -> void:
	min_value = stat.min_value
	
	if visual_max == 0.0:
		max_value = stat.max_value
	
	value = stat.get_modified_value()
	
	value_label.text = str(roundi(value)) + "/" + str(roundi(max_value))

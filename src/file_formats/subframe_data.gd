class_name SubFrameData

const SUBFRAME_LENGTH:int = 4 # bytes
var shift_x:int = 0
var shift_y:int = 0
var load_location_x:int = 0 # 8px tiles
var load_location_y:int = 0 # 8px tiles
var rect_size:Vector2i = Vector2i.ONE # in 8px tiles
var flip_x:bool = false
var flip_y:bool = false

func _to_string() -> String:
	var values: PackedStringArray = [
		shift_x,
		shift_y,
		load_location_x,
		load_location_y,
		rect_size,
		flip_x,
		flip_y,
		]
	
	return ", ".join(values)

class_name EvadeData
extends Resource

var value: int = 0
var source: EvadeSource
var type: EvadeType = EvadeType.PHYSICAL
var directions: Array[Directions] = [Directions.FRONT]

enum EvadeType {
	NONE,
	PHYSICAL,
	MAGICAL,
	}


enum EvadeSource {
	JOB,
	SHIELD,
	ACCESSORY,
	WEAPON,
	}


enum Directions {
	FRONT,
	SIDE,
	BACK,
	}


func _init(new_value: int, new_source: EvadeSource, new_type: EvadeType, new_directions: Array[Directions] = []) -> void:
	value = new_value
	source = new_source
	type = new_type
	
	if not new_directions.is_empty():
		directions = new_directions
	else:
		set_default_directions()


func set_default_directions() -> void:
	if type == EvadeType.MAGICAL:
		directions = [Directions.FRONT, Directions.SIDE, Directions.BACK]
	else:
		match source:
			EvadeSource.JOB:
				directions = [Directions.FRONT]
			EvadeSource.SHIELD, EvadeSource.WEAPON:
				directions = [Directions.FRONT, Directions.SIDE]
			EvadeSource.ACCESSORY:
				directions = [Directions.FRONT, Directions.SIDE, Directions.BACK]

class_name EvadeData
extends Resource

var value: int = 0
var source: EvadeSource
var type: EvadeType = EvadeType.PHYSICAL
var positions: Array[Position] = [Position.FRONT]

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


enum Position {
	FRONT,
	SIDE,
	BACK,
	}


func _init(new_value: int, new_source: EvadeSource, new_type: EvadeType) -> void:
	value = new_value
	source = new_source
	type = new_type
	
	match source:
		EvadeSource.JOB:
			positions = [Position.FRONT]
		EvadeSource.SHIELD, EvadeSource.WEAPON:
			positions = [Position.FRONT, Position.SIDE]
		EvadeSource.ACCESSORY:
			positions = [Position.FRONT, Position.SIDE, Position.BACK]

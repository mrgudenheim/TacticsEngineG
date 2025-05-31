class_name EvadeData
extends Resource

var value: int = 0
var source: EvadeSource
var type: EvadeType = EvadeType.PHYSICAL


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


func _init(new_value: int, new_source: EvadeSource, new_type: EvadeType) -> void:
	value = new_value
	source = new_source
	type = new_type

class_name FftEntd
extends Resource

# https://ffhacktics.com/wiki/ENTD

@export var units: Array # TODO store UnitData separate from unit_battle_data
@export var sprite_id: int = 0
@export var flags1: int = 0
@export var name_idx: int = 0
@export var level: int = 0
@export var birthday_month: int = 0
@export var birthday_day: int = 0
@export var brave: int = 0
@export var faith: int = 0
@export var job_unlock: int = 0
@export var job_level: int = 0

@export var main_job: int = 0
@export var secondary_skillset: int = 0
@export var reaction: int = 0
@export var support: int = 0
@export var movement: int = 0

@export var equipment_head: int = 0
@export var equipment_body: int = 0
@export var equipment_accessory: int = 0
@export var equipment_right_hand: int = 0
@export var equipment_left_hand: int = 0

@export var palette: int = 0
@export var flags2: int = 0
@export var position_x: int = 0
@export var position_y: int = 0
@export var initial_direction: int = 0
@export var experience: int = 0
@export var x1d: int = 0
@export var x1e: int = 0
@export var unit_id: int = 0
@export var x21: int = 0
@export var flags3: int = 0
@export var target_unit_id: int = 0
@export var x25: int = 0

func _init(bytes: PackedByteArray) -> void:
	sprite_id = bytes.decode_u8(0)
	flags1 = bytes.decode_u8(1)

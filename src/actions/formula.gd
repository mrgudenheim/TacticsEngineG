# https://ffhacktics.com/wiki/Formulas
class_name Formula
extends Resource

@export var is_modified_by_faith: bool = false
@export var physical_evasion_applies: bool = false
@export var magical_evasion_applies: bool = false
@export var no_evasion_applies: bool = false

func dmg_weapon_01() -> void:
	# hit chance - base hit, evade
	# damage calculation - base damage, modifiers (elements, status, zodiac, support abilities, critical hits)
	# apply status
	# post action proc # https://ffhacktics.com/wiki/02_Dmg_(Weapon)
	pass


func pa_x_wp(user: UnitData, item: ItemData) -> int:
	var base_damaage: int = 0
	base_damaage = user.physical_attack_current * item.weapon_power
	return base_damaage


func ma_x_wp(user: UnitData, item: ItemData) -> int:
	var base_damaage: int = 0
	base_damaage = user.magical_attack_current * item.weapon_power
	return base_damaage


func pa_ma_x_wp(user: UnitData, item: ItemData) -> int:
	var base_damaage: int = 0
	base_damaage = round(((user.physical_attack_current + user.magical_attack_current) / 2.0) * item.weapon_power)
	return base_damaage


func pa_sp_x_wp(user: UnitData, item: ItemData) -> int:
	var base_damaage: int = 0
	base_damaage = round(((user.physical_attack_current + user.speed_current) / 2.0) * item.weapon_power)
	return base_damaage


func pa_x_brave_x_wp(user: UnitData, item: ItemData) -> int:
	var base_damaage: int = 0
	base_damaage = round(user.physical_attack_current * user.brave_current * item.weapon_power / 100.0)
	return base_damaage


func rndm_pa_x_wp(user: UnitData, item: ItemData) -> int:
	var base_damaage: int = 0
	base_damaage = randi_range(1, user.physical_attack_current) * item.weapon_power
	return base_damaage


func wp_2(user: UnitData, item: ItemData) -> int:
	var base_damaage: int = 0
	base_damaage = item.weapon_power * item.weapon_power
	return base_damaage

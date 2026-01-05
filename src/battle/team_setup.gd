class_name TeamSetup
extends Container

signal unit_job_select_pressed(unit: UnitData)
signal unit_item_select_pressed(unit: UnitData, slot: UnitData.EquipmentSlot)
signal unit_ability_select_pressed(unit: UnitData, slot: UnitData.AbilitySlot)

@export var units: Array[UnitData]
@export var unit_list: Container
@export var num_units_spinbox: SpinBox
@export var unit_setup_scene: PackedScene

func _ready() -> void:
	for num_unit: int in num_units_spinbox.value:
		var unit_setup: UnitSetupPanel = unit_setup_scene.instantiate()
		unit_list.add_child(unit_setup)
		
		unit_setup.job_select_pressed.connect(unit_job_select_pressed.emit)
		unit_setup.item_select_pressed.connect(unit_item_select_pressed.emit)
		unit_setup.ability_select_pressed.connect(unit_ability_select_pressed.emit)

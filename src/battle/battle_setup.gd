class_name BattleSetup
extends Control

@export var team_setups: Array[TeamSetup]

@export var job_select_control: JobSelectControl
@export var item_select_control: ItemSelectControl
@export var ability_select_control: AbilitySelectControl

func _ready() -> void:
	for team_setup: TeamSetup in team_setups:
		
		team_setup.unit_job_select_pressed.connect(setup_job_select)
		#team_setup.unit_item_select_pressed.connect(unit_item_select_pressed.emit)
		#team_setup.unit_ability_select_pressed.connect(unit_ability_select_pressed.emit)


func populate_option_lists() -> void:
	job_select_control.populate_list()
	# TODO populate item list
	# TODO populate ability list


func setup_job_select(unit: UnitData) -> void:
	job_select_control.visible = true
	for job_select_button: JobSelectButton in job_select_control.job_select_buttons:
		job_select_button.selected.connect(func(new_job: JobData): update_unit_job(unit, new_job))


func desetup_job_select() -> void:
	job_select_control.visible = false
	for job_select_button: JobSelectButton in job_select_control.job_select_buttons:
		Utilities.disconnect_all_connections(job_select_button.selected)


func setup_item_select(unit: UnitData, slot: UnitData.EquipmentSlot) -> void:
	item_select_control.visible = true
	for item_select_button: ItemSelectButton in item_select_control.item_select_buttons:
		item_select_button.selected.connect(func(new_item: ItemData): update_unit_equipment(unit, slot, new_item))


func desetup_item_select() -> void:
	item_select_control.visible = false
	for item_select_button: ItemSelectButton in item_select_control.item_select_buttons:
		Utilities.disconnect_all_connections(item_select_button.selected)


func setup_ability_select(unit: UnitData, slot: UnitData.AbilitySlot) -> void:
	ability_select_control.visible = true
	for ability_select_button: AbilitySelectButton in ability_select_control.ability_select_buttons:
		ability_select_button.selected.connect(func(new_ability: Ability): update_unit_ability(unit, slot, new_ability))


func desetup_ability_select() -> void:
	ability_select_control.visible = false
	for ability_select_button: AbilitySelectButton in ability_select_control.ability_select_buttons:
		Utilities.disconnect_all_connections(ability_select_button.selected)

func update_unit_job(unit: UnitData, new_job: JobData) -> void:
	unit.set_job_id(new_job.job_id)
	# TODO update stats (apply multipliers, redo growths, etc.)
	
	desetup_job_select()

func update_unit_equipment(unit: UnitData, slot: UnitData.EquipmentSlot, new_item: ItemData) -> void:
	unit.set_equipment_slot(slot, new_item)
	
	desetup_item_select()


func update_unit_ability(unit: UnitData, slot: UnitData.AbilitySlot, new_ability: Ability) -> void:
	unit.equip_ability(slot, new_ability)
	
	desetup_ability_select()

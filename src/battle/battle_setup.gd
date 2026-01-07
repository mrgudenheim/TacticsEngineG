class_name BattleSetup
extends Control

@export var team_setups: Array[TeamSetup]
@export var job_select_control: JobSelectControl

func _ready() -> void:
	for team_setup: TeamSetup in team_setups:
		
		team_setup.unit_job_select_pressed.connect(setup_job_select)
		#team_setup.unit_item_select_pressed.connect(unit_item_select_pressed.emit)
		#team_setup.unit_ability_select_pressed.connect(unit_ability_select_pressed.emit)


func populate_option_lists() -> void:
	job_select_control.populate_list()


func setup_job_select(unit: UnitData) -> void:
	job_select_control.visible = true
	for job_select_button: JobSelectButton in job_select_control.job_select_buttons:
		job_select_button.selected.connect(func(new_job: JobData): update_unit_job(unit, new_job))


func desetup_job_select() -> void:
	job_select_control.visible = false
	for job_select_button: JobSelectButton in job_select_control.job_select_buttons:
		Utilities.disconnect_all_connections(job_select_button.selected)


func update_unit_job(unit: UnitData, new_job: JobData) -> void:
	unit.set_job_id(new_job.job_id)
	# TODO update stats (apply multipliers, redo growths, etc.)
	
	desetup_job_select()

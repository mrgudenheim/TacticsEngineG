class_name BattleSetupUi
extends Control

@export var battle_manager: BattleManager
@export var start_button: Button
@export var unit_scene: PackedScene

@export var battle_setup_container: TabContainer
@export var team_setups: Array[TeamSetup]
@export var team_setup_scene: PackedScene

@export var job_select_control: JobSelectControl
@export var item_select_control: ItemSelectControl
@export var ability_select_control: AbilitySelectControl


func initial_setup() -> void:
	visible = true
	
	populate_option_lists()
	
	for team_num: int in 2:
		add_team("Team" + str(team_num))
	
	start_button.pressed.connect(battle_manager.start_battle)
	battle_setup_container.tab_clicked.connect(adjust_height)


func populate_option_lists() -> void:
	job_select_control.populate_list()
	item_select_control.populate_list()
	ability_select_control.populate_list()


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
		if slot.slot_types.has(item_select_button.item_data.slot_type) and unit.equipable_item_types.has(item_select_button.item_data.item_type):
			item_select_button.visible = true
			item_select_button.selected.connect(func(new_item: ItemData): update_unit_equipment(unit, slot, new_item))
		else:
			item_select_button.visible = false


func desetup_item_select() -> void:
	item_select_control.visible = false
	for item_select_button: ItemSelectButton in item_select_control.item_select_buttons:
		Utilities.disconnect_all_connections(item_select_button.selected)


func setup_ability_select(unit: UnitData, slot: UnitData.AbilitySlot) -> void:
	ability_select_control.visible = true
	for ability_select_button: AbilitySelectButton in ability_select_control.ability_select_buttons:
		if slot.slot_types.has(ability_select_button.ability_data.slot_type):
			ability_select_button.visible = true
			ability_select_button.selected.connect(func(new_ability: Ability): update_unit_ability(unit, slot, new_ability))
		else:
			ability_select_button.visible = false


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


func add_team(new_team_name: String) -> Team:
	var new_team: Team = Team.new()
	battle_manager.teams.append(new_team)
	new_team.team_name = new_team_name
	
	var new_team_setup: TeamSetup = team_setup_scene.instantiate()
	battle_setup_container.add_child(new_team_setup)
	team_setups.append(new_team_setup)
	
	new_team_setup.unit_job_select_pressed.connect(setup_job_select)
	new_team_setup.unit_item_select_pressed.connect(setup_item_select)
	new_team_setup.unit_ability_select_pressed.connect(setup_ability_select)
	new_team_setup.need_new_unit.connect(battle_manager.spawn_random_unit)
	battle_manager.unit_created.connect(new_team_setup.add_unit_setup)
	
	new_team_setup.setup(new_team)
	
	return new_team


func adjust_height(tab_idx: int) -> void:
	push_warning(str(tab_idx))
	if tab_idx == 0:
		battle_setup_container.size.y = 0
		await get_tree().process_frame
		battle_setup_container.position.y = 0
	else:
		battle_setup_container.offset_bottom = 0

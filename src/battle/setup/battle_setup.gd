class_name BattleSetup
extends Control

@export var battle_manager: BattleManager
@export var start_button: Button
@export var unit_scene: PackedScene

@export var battle_setup_container: Container
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


func populate_option_lists() -> void:
	job_select_control.populate_list()
	item_select_control.populate_list()
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


func add_units_to_map() -> void:
	pass
	#if use_test_teams:
		#add_test_teams_to_map()
	#else: # use random teams
		#var generic_job_ids: Array[int] = []
		#generic_job_ids.assign(range(0x4a, 0x5a)) # generics
		#var special_characters: Array[int] = [
			#0x01, # ramza 1
			#0x04, # ramza 4
			#0x05, # delita 1
			#0x34, # agrias
			#0x11, # gafgorian
			#]
		#
		#var monster_jobs: Array[int] = []
		#monster_jobs.assign(range(0x5e, 0x8e)) # generic monsters
		#var special_monsters: Array[int] = [
			#0x41, # holy angel
			#0x49, # arch angel
			#0x3c, # gigas/warlock (Belias)
			#0x3e, # angel of death
			#0x40, # regulator (Hashmal)
			#0x43, # impure king (quakelin)
			#0x45, # ghost of fury (adremelk)
			#0x97, # serpentarious
			#0x91, # steel giant
			#]
		#
		#var team_1_job_ids: Array[int] = generic_job_ids
		#team_1_job_ids.append_array(special_characters)
		#
		#var team_2_job_ids: Array[int] = monster_jobs
		#team_2_job_ids.append_array(special_monsters)
		#
		#for random_unit: int in units_per_team:
			#var rand_job: int = team_1_job_ids.pick_random()
			#while [0x2c, 0x31].has(rand_job): # prevent jobs without idle frames - 0x2c (Alma2) and 0x31 (Ajora) do not have walking frames
				#rand_job = randi_range(0x01, 0x8d)
			#var new_unit: UnitData = spawn_unit(get_random_stand_terrain_tile(), rand_job, team1)
			#new_unit.is_ai_controlled = false
		#
		#for random_unit: int in units_per_team:
			#var rand_job: int = team_2_job_ids.pick_random()
			##var rand_job: int = randi_range(0x5e, 0x8d) # monsters
			#while [0x2c, 0x31].has(rand_job): # prevent jobs without idle frames - 0x2c (Alma2) and 0x31 (Ajora) do not have walking frames
				#rand_job = randi_range(0x01, 0x8d)
			#var new_unit: UnitData = spawn_unit(get_random_stand_terrain_tile(), rand_job, team2)
			##new_unit.is_ai_controlled = false

class_name TeamSetup
extends Container

signal need_new_unit(team: Team)

signal unit_job_select_pressed(unit: Unit)
signal unit_item_select_pressed(unit: Unit, slot: EquipmentSlot)
signal unit_ability_select_pressed(unit: Unit, slot: AbilitySlot)

@export var team: Team
@export var unit_list: Container
@export var num_units_spinbox: SpinBox
@export var unit_setup_scene: PackedScene
@export var unit_scene: PackedScene


func _ready() -> void:
	num_units_spinbox.value_changed.connect(on_num_units_changed)


func setup(new_team: Team):
	team = new_team
	name = team.team_name
	
	on_num_units_changed(num_units_spinbox.value)


func on_num_units_changed(new_value: int) -> void:
	var delta_units: int = new_value - team.units.size()
	if delta_units > 0:
		for delta: int in delta_units:
			need_new_unit.emit(team)
	elif delta_units < 0:
		var unit_panels: Array[UnitSetupPanel] = []
		unit_panels.assign(unit_list.get_children())
		
		for delta: int in -delta_units:
			team.units[-1].queue_free()
			team.units.remove_at(-1)
			unit_panels[-1].queue_free()
			unit_panels.remove_at(-1)


func add_unit_setup(new_unit: Unit) -> void:
	if new_unit.team != team:
		return
	
	var unit_setup: UnitSetupPanel = unit_setup_scene.instantiate()
	unit_list.add_child(unit_setup)
	unit_setup.setup(new_unit)
	
	#var tile_position: TerrainTile = battle_manager.get_random_stand_terrain_tile()
	#var new_unit: Unit = battle_manager.spawn_unit(tile_position, 0x01, team)
	
	unit_setup.job_select_pressed.connect(unit_job_select_pressed.emit)
	unit_setup.item_select_pressed.connect(unit_item_select_pressed.emit)
	unit_setup.ability_select_pressed.connect(unit_ability_select_pressed.emit)
	
	#var new_unit: Unit = unit_scene.instantiate()
	#add_child(new_unit)
	#new_unit.initialized.connect(func(): setup(new_unit))

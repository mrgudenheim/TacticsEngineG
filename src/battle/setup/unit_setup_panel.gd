class_name UnitSetupPanel
extends Container

signal job_select_pressed(unit: UnitData)
signal item_select_pressed(unit: UnitData, slot: UnitData.EquipmentSlot)
signal ability_select_pressed(unit: UnitData, slot: UnitData.AbilitySlot)

@export var sprite_rect: TextureRect
@export var unit_name_line_edit: LineEdit
@export var gender_option_button: OptionButton
@export var job_button: Button
@export var level_spinbox: SpinBox

@export var hp_bar: StatBar
@export var mp_bar: StatBar
@export var ct_bar: StatBar

@export var pa_label: Label
@export var ma_label: Label
@export var brave_label: Label
@export var faith_label: Label
@export var move_label: Label
@export var jump_label: Label
@export var speed_label: Label

@export var evade_grid: GridContainer

@export var equipment_grid: GridContainer
@export var ability_grid: GridContainer

@export var passive_effect_container: Container
@export var innate_ability_container: Container
@export var status_affinity_container: Container
# @export var element_affinity_list: VBoxContainer

@export var weak_elements_label: Label
@export var resist_elements_label: Label
@export var immune_elements_label: Label
@export var absorb_elements_label: Label
@export var strengthen_elements_label: Label

@export var unit_scene: PackedScene
var unit_data: UnitData


func setup(unit: UnitData) -> void:
	unit_data = unit
	if unit.job_data == null:
		unit.set_job_id(0x01) # TODO set initial job correctly
	
	unit_name_line_edit.text = unit.unit_nickname
	job_button.text = unit.job_data.display_name

	hp_bar.set_stat(str(UnitData.StatType.keys()[UnitData.StatType.HP]), unit.stats[UnitData.StatType.HP])
	hp_bar.name_label.position.x = 5
	hp_bar.name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hp_bar.value_label.position.x = hp_bar.size.x - hp_bar.value_label.size.x - 5
	hp_bar.value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# hp_bar.value_label.grow_horizontal = GrowDirection.GROW_DIRECTION_BEGIN
	
	mp_bar.set_stat(str(UnitData.StatType.keys()[UnitData.StatType.MP]), unit.stats[UnitData.StatType.MP])
	mp_bar.fill_color = Color.INDIAN_RED
	mp_bar.name_label.position.x = 5
	mp_bar.name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	mp_bar.value_label.position.x = mp_bar.size.x - mp_bar.value_label.size.x - 5
	mp_bar.value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# mp_bar.value_label.grow_horizontal = GrowDirection.GROW_DIRECTION_BEGIN

	ct_bar.set_stat(str(UnitData.StatType.keys()[UnitData.StatType.CT]), unit.stats[UnitData.StatType.CT])
	ct_bar.fill_color = Color.WEB_GREEN
	ct_bar.name_label.position.x = 5
	ct_bar.name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ct_bar.value_label.position.x = ct_bar.size.x - ct_bar.value_label.size.x - 5
	ct_bar.value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# ct_bar.value_label.grow_horizontal = GrowDirection.GROW_DIRECTION_BEGIN

	# clear connections for when panel is reused
	Utilities.disconnect_all_connections(unit_name_line_edit.text_submitted)
	Utilities.disconnect_all_connections(level_spinbox.value_changed)
	Utilities.disconnect_all_connections(job_button.pressed)
	Utilities.disconnect_all_connections(unit.data_updated)

	# hook up buttons to update Unit data
	unit_name_line_edit.text_submitted.connect(func(new_name: String): unit.unit_nickname = new_name)
	level_spinbox.value_changed.connect(func(new_value): update_level(unit, new_value))
	# TODO update gender - sprite and stats
	
	# TODO hook up job select button
	job_button.pressed.connect(func(): job_select_pressed.emit(unit))
	
	# show job select list
	# hookup job select buttons to update this units job
	# remove invalid equipment
	# generate battle stats (aka apply stat multipliers)
	unit.data_updated.connect(update_ui)

	update_ui(unit)


func update_ui(unit: UnitData) -> void:
	# update_stat_label(level_label, unit, UnitData.StatType.LEVEL)
	job_button.text = unit.job_data.display_name
	level_spinbox.value = unit.stats[UnitData.StatType.LEVEL].get_modified_value()
	
	update_stat_label(pa_label, unit, UnitData.StatType.PHYSICAL_ATTACK)
	update_stat_label(ma_label, unit, UnitData.StatType.MAGIC_ATTACK)
	update_stat_label(brave_label, unit, UnitData.StatType.BRAVE)
	update_stat_label(faith_label, unit, UnitData.StatType.FAITH)
	update_stat_label(move_label, unit, UnitData.StatType.MOVE)
	update_stat_label(jump_label, unit, UnitData.StatType.JUMP)
	update_stat_label(speed_label, unit, UnitData.StatType.SPEED)

	# update evade
	var unit_passive_effects: Array[PassiveEffect] = unit.get_all_passive_effects()

	for evade_type: EvadeData.EvadeType in EvadeData.EvadeType.values():
		# skip EvadeType.NONE
		if evade_type == EvadeData.EvadeType.NONE:
			continue
		
		# skip first row of lables (column headers)
		var label_idx: int = evade_type * (EvadeData.Directions.keys().size() + EvadeData.EvadeSource.keys().size() + 2)
		label_idx += 1 # skip first column of labels
		for evade_direction: EvadeData.Directions in EvadeData.Directions.values():
			var evade_factor: int = get_total_evade_factor(unit, unit_passive_effects, evade_type, evade_direction)
			var evade_value_label: Label = evade_grid.get_child(label_idx)
			evade_value_label.text = str(evade_factor) + "%"
			
			label_idx += 1

		label_idx += 1 # skip empty spacer column
		var source_evade_values: Dictionary[EvadeData.EvadeSource, int] = unit.get_evade_values(evade_type, EvadeData.Directions.FRONT)
		for evade_source: EvadeData.EvadeSource in source_evade_values.keys():
			var evade_value_label: Label = evade_grid.get_child(label_idx)
			evade_value_label.text = str(source_evade_values[evade_source]) + "%"
			
			label_idx += 1

	# update equipment
	var equipment_labels: Array[Node] = equipment_grid.get_children()
	for child_idx: int in range(0, equipment_labels.size()):
		equipment_labels[child_idx].queue_free()

	for equip_slot: UnitData.EquipmentSlot in unit.equip_slots:
		var new_slot_label: Label = Label.new()
		new_slot_label.text = equip_slot.equipment_slot_name
		equipment_grid.add_child(new_slot_label)

		var new_item_button: Button = Button.new()
		new_item_button.text = equip_slot.item.display_name
		new_item_button.pressed.connect(func(): item_select_pressed.emit(unit, equip_slot))
		new_item_button.custom_minimum_size = Vector2(60, 0)
		equipment_grid.add_child(new_item_button)

	# update abilities
	var ability_labels: Array[Node] = ability_grid.get_children()
	for child_idx: int in range(0, ability_labels.size()):
		ability_labels[child_idx].queue_free()

	for ability_slot: UnitData.AbilitySlot in unit.ability_slots:
		var new_slot_label: Label = Label.new()
		new_slot_label.text = ability_slot.ability_slot_name
		ability_grid.add_child(new_slot_label)

		var new_ability_button: Button = Button.new()
		new_ability_button.text = ability_slot.ability.display_name
		new_ability_button.pressed.connect(func(): ability_select_pressed.emit(unit, ability_slot))
		# TODO implement ability select buttons
		ability_grid.add_child(new_ability_button)
	
	# update passive effects
	var passive_effect_labels: Array[Node] = passive_effect_container.get_children()
	for child_idx: int in range(1, passive_effect_labels.size()):
		passive_effect_labels[child_idx].queue_free()
	
	# update innate abilities
	var innate_abilities_names: PackedStringArray = []
	for ability: Ability in unit.job_data.innate_abilities:
		innate_abilities_names.append(ability.display_name)
	#for passive_effect: PassiveEffect in unit.get_all_passive_effects(): # TODO allow giving innate abilities from passive effects?
		#innate_abilities_names.append(passive_effect.innate_abilities)
	
	update_passive_effect_list_label("Innate: ", innate_abilities_names)
	
	update_passive_effect_list_label("Weak: ", get_elements_text(unit.elemental_weakness))
	update_passive_effect_list_label("Resist: ", get_elements_text(unit.elemental_half))
	update_passive_effect_list_label("Immune: ", get_elements_text(unit.elemental_cancel))
	update_passive_effect_list_label("Absorb: ", get_elements_text(unit.elemental_absorb))
	update_passive_effect_list_label("Strengthen: ", get_elements_text(unit.elemental_strengthen))
	
	update_passive_effect_list_label("Always: ", unit.always_statuses)
	update_passive_effect_list_label("Starting: ", unit.start_statuses)
	update_passive_effect_list_label("Immune: ", unit.immune_statuses)
	
	
	# update innate abilities
	var innate_ability_labels: Array[Node] = innate_ability_container.get_children()
	for child_idx: int in range(0, innate_ability_labels.size()):
		innate_ability_labels[child_idx].queue_free()

	for ability: Ability in unit.job_data.innate_abilities:
		var new_ability_label: Label = Label.new()
		new_ability_label.text = ability.display_name
		innate_ability_container.add_child(new_ability_label)

	# update status affinity
	var current_status_labels: Array[Node] = status_affinity_container.get_children()
	for child_idx: int in range(1, current_status_labels.size()):
		current_status_labels[child_idx].queue_free()

	for status_name: String in unit.always_statuses:
		var new_status_label: Label = Label.new()
		new_status_label.text = "Always " + status_name
		status_affinity_container.add_child(new_status_label)
	
	for status_name: String in unit.start_statuses:
		var new_status_label: Label = Label.new()
		new_status_label.text = "Start " + status_name
		status_affinity_container.add_child(new_status_label)
	
	for status_name: String in unit.immune_statuses:
		var new_status_label: Label = Label.new()
		new_status_label.text = "Immune " + status_name
		status_affinity_container.add_child(new_status_label)
	
	# update element affinities
	update_element_list(weak_elements_label, "Weak: ", unit.elemental_weakness)
	update_element_list(resist_elements_label, "Resist: ", unit.elemental_half)
	update_element_list(immune_elements_label, "Immune: ", unit.elemental_cancel)
	update_element_list(absorb_elements_label, "Absorb: ", unit.elemental_absorb)
	update_element_list(strengthen_elements_label, "Strengthen: ", unit.elemental_strengthen)


func update_element_list(affinity_list_label: Label, label_start: String, affinity_list: Array[Action.ElementTypes]) -> void:
	affinity_list_label.text = label_start
	var elements_list: PackedStringArray = get_elements_text(affinity_list)
	affinity_list_label.text += ", ".join(elements_list)


func get_elements_text(element_list: Array[Action.ElementTypes]) -> PackedStringArray:
	var elements_text: PackedStringArray = []
	for element: Action.ElementTypes in element_list:
		elements_text.append(Action.ElementTypes.find_key(element).to_pascal_case())
	
	return elements_text


func update_passive_effect_list_label(starting_text: String, text_list: PackedStringArray) -> void:
	if not text_list.is_empty():
		var new_label: Label = Label.new()
		new_label.name = starting_text.to_pascal_case()
		new_label.text = starting_text + ", ".join(text_list)
		new_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		passive_effect_container.add_child(new_label)


func update_stat_label(stat_label: Label, unit: UnitData, stat_type: UnitData.StatType) -> void:
	var stat_name: String = UnitData.StatType.find_key(stat_type).to_pascal_case()
	var stat: ClampedValue = unit.stats[stat_type]
	var stat_value: int = stat.get_modified_value()
	# stat_label.text = stat_name + ": " + str(roundi(stat_value)) + "/" + str(roundi(stat.max_value))
	stat_label.text = stat_name + ": " + str(roundi(stat_value)) # + "/" + str(roundi(stat.max_value))


func get_total_evade_factor(unit: UnitData, unit_passive_effects: Array[PassiveEffect], evade_type: EvadeData.EvadeType, evade_direction: EvadeData.Directions) -> int:
	var evade_values: Dictionary[EvadeData.EvadeSource, int] = unit.get_evade_values(evade_type, evade_direction)

	var total_evade_factor: float = 1.0
	var evade_factors: Dictionary[EvadeData.EvadeSource, float] = {}

	for evade_source: EvadeData.EvadeSource in evade_values.keys():
		if unit_passive_effects.any(func(passive_effect): return passive_effect.include_evade_sources.has(evade_source)):
			var evade_value: float = evade_values[evade_source]
			for passive_effect: PassiveEffect in unit_passive_effects:
				if passive_effect.evade_source_modifiers_targeted.has(evade_source):
					evade_value = passive_effect.evade_source_modifiers_targeted[evade_source].apply(evade_value)
			
			var evade_factor: float = max(0.0, 1 - (evade_value / 100.0))

			evade_factors[evade_source] = evade_factor
			total_evade_factor = total_evade_factor * evade_factor

	total_evade_factor = max(0, total_evade_factor) # prevent negative evasion
	var total_evade_value: int = roundi((1 - total_evade_factor) * 100)

	return total_evade_value


func update_level(unit: UnitData, new_level: int) -> void:
	unit.generate_leveled_raw_stats(new_level, unit.job_data)
	unit.calc_battle_stats(unit.job_data)

class_name UnitDetailsBattleUi
extends PanelContainer

@export var portrait_rect: TextureRect
@export var team_label: Label
@export var unit_name_label: Label
@export var job_label: Label
@export var level_label: Label

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

@export var current_status_list: VBoxContainer
@export var immune_status_list: VBoxContainer
# @export var element_affinity_list: VBoxContainer

@export var weak_elements_label: Label
@export var resist_elements_label: Label
@export var immune_elements_label: Label
@export var absorb_elements_label: Label
@export var strengthen_elements_label: Label

func setup(unit: UnitData) -> void:
	unit_name_label.text = unit.unit_nickname
	job_label.text = unit.job_data.display_name

	hp_bar.set_stat(str(UnitData.StatType.keys()[UnitData.StatType.HP]), unit.stats[UnitData.StatType.HP])
	hp_bar.name_label.position.x = 0
	hp_bar.value_label.position.x -= (hp_bar.value_label.size.x + 10)
	hp_bar.value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# hp_bar.value_label.grow_horizontal = GrowDirection.GROW_DIRECTION_BEGIN
	
	mp_bar.set_stat(str(UnitData.StatType.keys()[UnitData.StatType.MP]), unit.stats[UnitData.StatType.MP])
	mp_bar.fill_color = Color.INDIAN_RED
	mp_bar.name_label.position.x = 0
	mp_bar.value_label.position.x -= (mp_bar.value_label.size.x + 10)
	mp_bar.value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# mp_bar.value_label.grow_horizontal = GrowDirection.GROW_DIRECTION_BEGIN

	ct_bar.set_stat(str(UnitData.StatType.keys()[UnitData.StatType.CT]), unit.stats[UnitData.StatType.CT])
	ct_bar.fill_color = Color.WEB_GREEN
	ct_bar.name_label.position.x = 0
	ct_bar.value_label.position.x -= (ct_bar.value_label.size.x + 10)
	ct_bar.value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# ct_bar.value_label.grow_horizontal = GrowDirection.GROW_DIRECTION_BEGIN

	update_ui(unit)

	visibility_changed.connect(func(): update_ui(unit))


func update_ui(unit: UnitData) -> void:
	update_stat_label(level_label, unit, UnitData.StatType.LEVEL)
	
	update_stat_label(pa_label, unit, UnitData.StatType.PHYSICAL_ATTACK)
	update_stat_label(ma_label, unit, UnitData.StatType.MAGIC_ATTACK)
	update_stat_label(brave_label, unit, UnitData.StatType.BRAVE)
	update_stat_label(faith_label, unit, UnitData.StatType.FAITH)
	update_stat_label(move_label, unit, UnitData.StatType.MOVE)
	update_stat_label(jump_label, unit, UnitData.StatType.JUMP)
	update_stat_label(speed_label, unit, UnitData.StatType.SPEED)

	# TODO update evade

	# update equipment
	var equipment_labels: Array[Node] = equipment_grid.get_children()
	for child_idx: int in range(0, equipment_labels.size()):
		equipment_labels[child_idx].queue_free()

	for equip_slot: UnitData.EquipmentSlot in unit.equip_slots:
		var new_slot_label: Label = Label.new()
		new_slot_label.text = equip_slot.equipment_slot_name
		equipment_grid.add_child(new_slot_label)

		var new_item_label: Label = Label.new()
		new_item_label.text = equip_slot.item.display_name
		equipment_grid.add_child(new_item_label)

	# update abilities
	var ability_labels: Array[Node] = ability_grid.get_children()
	for child_idx: int in range(0, ability_labels.size()):
		ability_labels[child_idx].queue_free()

	for ability_slot: UnitData.AbilitySlot in unit.ability_slots:
		var new_slot_label: Label = Label.new()
		new_slot_label.text = ability_slot.ability_slot_name
		ability_grid.add_child(new_slot_label)

		var new_ability_label: Label = Label.new()
		new_ability_label.text = ability_slot.ability.display_name
		ability_grid.add_child(new_ability_label)

	# update statuses
	var current_status_labels: Array[Node] = current_status_list.get_children()
	for child_idx: int in range(1, current_status_labels.size()):
		current_status_labels[child_idx].queue_free()

	for status: StatusEffect in unit.current_statuses:
		var new_status_label: Label = Label.new()
		new_status_label.text = status.status_effect_name
		current_status_list.add_child(new_status_label)
	
	# update immune statuses
	var immune_statuses_labels: Array[Node] = immune_status_list.get_children()
	for child_idx: int in range(1, immune_statuses_labels.size()):
		immune_statuses_labels[child_idx].queue_free()

	for status_name: String in unit.immune_statuses:
		var new_status_label: Label = Label.new()
		new_status_label.text = status_name
		immune_status_list.add_child(new_status_label)
	
	# update element affinities
	update_element_list(weak_elements_label, "Weak: ", unit.elemental_weakness)
	update_element_list(resist_elements_label, "Resist: ", unit.elemental_half)
	update_element_list(immune_elements_label, "Immune: ", unit.elemental_cancel)
	update_element_list(absorb_elements_label, "Absorb: ", unit.elemental_absorb)
	update_element_list(strengthen_elements_label, "Strengthen: ", unit.elemental_strengthen)


func update_element_list(affinity_list_label: Label, label_start: String, affinity_list: Array[Action.ElementTypes]) -> void:
	affinity_list_label.text = label_start
	var elements_list: PackedStringArray = []
	for element: Action.ElementTypes in affinity_list:
		elements_list.append(Action.ElementTypes.find_key(element).to_pascal_case())
	affinity_list_label.text += ", ".join(elements_list)



func update_stat_label(stat_label: Label, unit: UnitData, stat_type: UnitData.StatType) -> void:
	var stat_name: String = UnitData.StatType.find_key(stat_type).to_pascal_case()
	var stat: ClampedValue = unit.stats[stat_type]
	var stat_value: int = stat.get_modified_value()
	# stat_label.text = stat_name + ": " + str(roundi(stat_value)) + "/" + str(roundi(stat.max_value))
	stat_label.text = stat_name + ": " + str(roundi(stat_value)) # + "/" + str(roundi(stat.max_value))

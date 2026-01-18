class_name ItemSelectButton
extends PanelContainer

signal selected(item_data: ItemData)

var item_data: ItemData:
	get: return item_data
	set(value):
		item_data = value
		update_ui(value)

@export var button: Button
@export var display_name: Label
@export var sprite_rect: TextureRect

@export var list: Container

func _ready():
	button.pressed.connect(on_selected)


func on_selected() -> void:
	selected.emit(item_data)


func update_ui(new_item_data: ItemData) -> void:
	display_name.text = new_item_data.display_name + " (Item ID: " + str(new_item_data.item_idx) + ")"
	name = new_item_data.unique_name
	
	var passive_effect: PassiveEffect = new_item_data.passive_effect
	
	var wp_label: Label = Label.new()
	wp_label.text = "WP: " + str(new_item_data.weapon_power)
	list.add_child(wp_label)
	
	for stat_type: UnitData.StatType in passive_effect.stat_modifiers.keys():
		var stat_modifier: Modifier = passive_effect.stat_modifiers[stat_type]
		var modifier_label: Label = Label.new()
		modifier_label.text = UnitData.StatType.keys()[stat_type] + ": +" + str(stat_modifier.value_formula.values[0])
		list.add_child(modifier_label)

	## TODO update evade
	#for evade_type: EvadeData.EvadeType in EvadeData.EvadeType.values():
		## skip EvadeType.NONE
		#if evade_type == EvadeData.EvadeType.NONE:
			#continue
		#
		## skip first row of lables (column headers)
		#var label_idx: int = evade_type * (EvadeData.EvadeSource.keys().size() + 1)
		#label_idx += 1 # skip first column of labels

		#var source_evade_values: Dictionary[EvadeData.EvadeSource, int] = get_evade_values(new_job_data.evade_datas, evade_type, EvadeData.Directions.FRONT)
		#for evade_source: EvadeData.EvadeSource in source_evade_values.keys():
			#var evade_value_label: Label = evade_grid.get_child(label_idx)
			#evade_value_label.text = str(source_evade_values[evade_source]) + "%"
			#
			#label_idx += 1
	

	# update statuses	
	var statuses_always: PackedStringArray = []
	var statuses_start: PackedStringArray = []
	var statuses_immune: PackedStringArray = []

	#for passive_effect: PassiveEffect in new_item_data.passive_effects:
	statuses_always.append_array(passive_effect.status_always)
	statuses_start.append_array(passive_effect.status_start)
	statuses_immune.append_array(passive_effect.status_immune)
	
	statuses_always = PackedStringArray(Utilities.get_array_unique(statuses_always))
	statuses_start = PackedStringArray(Utilities.get_array_unique(statuses_start))
	statuses_immune = PackedStringArray(Utilities.get_array_unique(statuses_immune))
	
	update_list(statuses_always, "Always: ")
	update_list(statuses_start, "Start: ")
	update_list(statuses_immune, "Immune: ")
	
	## Update element affinities
	var element_weak_list: Array[Action.ElementTypes] = passive_effect.element_weakness
	var element_resist_list: Array[Action.ElementTypes] = passive_effect.element_half
	var element_immune_list: Array[Action.ElementTypes] = passive_effect.element_cancel
	var element_absorb_list: Array[Action.ElementTypes] = passive_effect.element_absorb
	var element_strengthen_list: Array[Action.ElementTypes] = passive_effect.element_strengthen
	
	#for passive_effect: PassiveEffect in new_job_data.passive_effects:
		#element_weak_list.append_array(passive_effect.element_weakness)
		#element_resist_list.append_array(passive_effect.element_half)
		#element_immune_list.append_array(passive_effect.element_cancel)
		#element_absorb_list.append_array(passive_effect.element_absorb)
		#element_strengthen_list.append_array(passive_effect.element_strengthen)
	
	element_weak_list.assign(Utilities.get_array_unique(element_weak_list))
	element_resist_list.assign(Utilities.get_array_unique(element_resist_list))
	element_immune_list.assign(Utilities.get_array_unique(element_immune_list))
	element_absorb_list.assign(Utilities.get_array_unique(element_absorb_list))
	element_strengthen_list.assign(Utilities.get_array_unique(element_strengthen_list))

	update_list(get_element_text_list(element_weak_list), "Weak: ")
	update_list(get_element_text_list(element_resist_list), "Resist: ")
	update_list(get_element_text_list(element_immune_list), "Immune: ")
	update_list(get_element_text_list(element_absorb_list), "Absorb: ")
	update_list(get_element_text_list(element_strengthen_list), "Strengthen: ")

	## update action list
	#var action_labels: Array[Node] = action_list.get_children()
	#for child_idx: int in range(1, action_labels.size()):
		#action_labels[child_idx].queue_free()
	#
	#for ability_id: int in RomReader.scus_data.skillsets_data[job_data.skillset_id].action_ability_ids:
		#if ability_id != 0:
			#var new_action: Action = RomReader.fft_abilities[ability_id].ability_action
			#var new_action_name: Label = Label.new()
			#new_action_name.text = new_action.display_name
			#action_list.add_child(new_action_name)
	
	# TODO update showing other passive_effect stuff for Items?


#func get_evade_values(evade_datas: Array[EvadeData], evade_type: EvadeData.EvadeType, direction: EvadeData.Directions) -> Dictionary[EvadeData.EvadeSource, int]:
	#var evade_values: Dictionary[EvadeData.EvadeSource, int] = {
		#EvadeData.EvadeSource.JOB: 0,
		#EvadeData.EvadeSource.SHIELD: 0,
		#EvadeData.EvadeSource.ACCESSORY: 0,
		#EvadeData.EvadeSource.WEAPON: 0,
	#}
	#
	#for evade_data: EvadeData in evade_datas:
		#if evade_data.directions.has(direction) and evade_data.type == evade_type:
			#evade_values[evade_data.source] += evade_data.value
	#
	#return evade_values
#
#
func get_element_text_list(affinity_list: Array[Action.ElementTypes]) -> PackedStringArray:
	var elements_list: PackedStringArray = []
	for element: Action.ElementTypes in affinity_list:
		elements_list.append(Action.ElementTypes.find_key(element).to_pascal_case())
	return elements_list
	# affinity_list_label.text += ", ".join(elements_list)


func update_list(text_list: PackedStringArray, label_start: String) -> void:
	if text_list.is_empty():
		return
	
	var new_label: Label = Label.new()
	new_label.text = label_start + ", ".join(text_list)
	list.add_child(new_label)

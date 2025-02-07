class_name OpcodeOptionButton
extends OptionButton

var parent: GridContainer
var params_ui: Array[Node] = [] 
var param_spinboxes: Array[SpinBox] = []
var seq_id: int
var seq_part_id: int
var seq_part: SeqPart = SeqPart.new()

func _ready() -> void:
	parent = get_parent()
	item_selected.connect(on_item_selected)


func on_item_selected(item_index: int) -> void:
	var opcode_name: String = get_item_text(item_index)
	
	# remove existing ui elements
	for node in params_ui:
		node.queue_free()
	params_ui.clear()
	param_spinboxes.clear()
	
	# set up seq_part
	var params_need_initialize: bool = false
	if seq_part.opcode_name != opcode_name:
		params_need_initialize = true
	seq_part.opcode_name = opcode_name
	for opcode: String in Seq.opcode_names.keys():
		if Seq.opcode_names[opcode] == opcode_name:
			seq_part.opcode = opcode
	var opcode_params: int = 2 # 2 for LoadFrameWait
	if Seq.opcode_parameters_by_name.has(opcode_name):
		opcode_params = Seq.opcode_parameters_by_name[opcode_name]
	seq_part.parameters.resize(opcode_params)
	FFTae.ae.ui_manager.current_bytes = FFTae.ae.seq.toal_length
	if params_need_initialize:
		for param_index: int in seq_part.parameters.size():
			seq_part.parameters[param_index] = 0
	
	# add new parameter ui elements
	var max_params: int = 3
	for param_index: int in range(max_params):
		if param_index < opcode_params:
			var param_spinbox: SpinBox = SpinBox.new()
			param_spinbox.select_all_on_focus = true
			param_spinbox.max_value = 255
			param_spinbox.min_value = -128
			param_spinbox.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			parent.add_child(param_spinbox)
			parent.move_child(param_spinbox, self.get_index() + 1 + param_index)
			param_spinboxes.append(param_spinbox)
			params_ui.append(param_spinbox)
			param_spinbox.value_changed.connect(func(value: int) -> void: 
					seq_part.parameters[param_index] = value
					)
		else:
			var empty: Label = Label.new()
			parent.add_child(empty)
			var empty_location: int = self.get_index() + 1 + param_index
			parent.move_child(empty, empty_location)
			params_ui.append(empty)
	
	FFTae.ae.seq.sequences[seq_id].update_length()
	
	# update animation list to reflect changes (very slow)
	#FFTae.ae.populate_animation_list(FFTae.ae.animation_list_container, FFTae.ae.seq)

class_name UnitDebugMenu
extends Control

var unit: Node3D
@export var animation_manager: UnitAnimationManager

@export var sprite_options: OptionButton
@export var anim_id_spin: SpinBox

@export var weapon_options: OptionButton
@export var item_options: OptionButton
@export var other_type_options: OptionButton

@export var sprite_sheet_viewer: Sprite3D


func _ready() -> void:
	unit = get_parent()
	RomReader.rom_loaded.connect(populat_sprite_options)
	sprite_options.item_selected.connect(_on_sprite_option_selected)
	anim_id_spin.value_changed.connect(_on_anim_id_spin_value_changed)
	weapon_options.item_selected.connect(func(idx) -> void: 
		animation_manager.weapon_id = idx)
	item_options.item_selected.connect(func(idx) -> void: 
		animation_manager.item_index = idx
		animation_manager._on_animation_changed())

func _process(delta: float) -> void:
	position = MapViewer.main_camera.unproject_position(unit.position) + Vector2(50, -50)


func populate_options() -> void:	
	weapon_options.clear()
	for weapon_index: int in UnitAnimationManager.weapon_table.size():
		weapon_options.add_item(str(UnitAnimationManager.weapon_table[weapon_index][0]))
	
	item_options.clear()
	for item_list_index: int in UnitAnimationManager.item_list.size():
		if UnitAnimationManager.item_list[item_list_index].size() < 2: # ignore blank lines
			break
		item_options.add_item(str(UnitAnimationManager.item_list[item_list_index][1]))


func populat_sprite_options() -> void:
	sprite_options.clear()
	for spr: Spr in RomReader.sprs:
		sprite_options.add_item(spr.file_name)
	
	sprite_options.select(RomReader.file_records["RAMUZA.SPR"].type_index)
	sprite_options.item_selected.emit(sprite_options.selected)


func enable_ui() -> void:
	weapon_options.disabled = false
	item_options.disabled = false
	other_type_options.disabled = false


func _on_sprite_option_selected(index) -> void:
	var spr: Spr = RomReader.sprs[index]
	if not spr.is_initialized:
		spr.set_data(RomReader.get_file_data(sprite_options.get_item_text(index)))
		spr.set_spritesheet_data(RomReader.spr_file_name_to_id[spr.file_name])
	
	animation_manager.global_spr = spr
	
	var shp: Shp = RomReader.shps[RomReader.file_records[spr.shp_name].type_index]
	if not shp.is_initialized:
		shp.set_data_from_shp_bytes(RomReader.get_file_data(shp.file_name))
	
	animation_manager.global_spr = spr
	
	var seq: Seq = RomReader.seqs[RomReader.file_records[spr.seq_name].type_index]
	if not seq.is_initialized:
		seq.set_data_from_seq_bytes(RomReader.get_file_data(seq.file_name))
	
	animation_manager.global_spr = spr
	animation_manager.global_shp = shp
	animation_manager.global_seq = seq
	
	animation_manager.wep_spr = RomReader.sprs[RomReader.file_records["WEP.SPR"].type_index]
	animation_manager.wep_shp = RomReader.shps[RomReader.file_records["WEP1.SHP"].type_index]
	animation_manager.wep_seq = RomReader.seqs[RomReader.file_records["WEP1.SEQ"].type_index]

	animation_manager.eff_spr = RomReader.sprs[RomReader.file_records["EFF.SPR"].type_index]
	animation_manager.eff_shp = RomReader.shps[RomReader.file_records["EFF1.SHP"].type_index]
	animation_manager.eff_seq = RomReader.seqs[RomReader.file_records["EFF1.SEQ"].type_index]

	animation_manager.item_spr = RomReader.sprs[RomReader.file_records["ITEM.BIN"].type_index]
	animation_manager.item_shp = RomReader.shps[RomReader.file_records["ITEM.SHP"].type_index]

	animation_manager.other_spr = RomReader.sprs[RomReader.file_records["OTHER.SPR"].type_index]
	animation_manager.other_shp = RomReader.shps[RomReader.file_records["OTHER.SHP"].type_index]
	
	sprite_sheet_viewer.texture = ImageTexture.create_from_image(spr.spritesheet)


func _on_anim_id_spin_value_changed(value: int) -> void:
	animation_manager.global_animation_ptr_id = value

class_name UnitDebugMenu
extends Control

signal spritesheet_changed(new_image: ImageTexture)

@export var unit: UnitData
@export var unit_char_body: CharacterBody3D
@export var animation_manager: UnitAnimationManager

@export var sprite_options: OptionButton
@export var anim_id_spin: SpinBox

@export var weapon_options: OptionButton
@export var item_options: OptionButton
@export var other_type_options: OptionButton

@export var ability_id_spin: SpinBox
@export var ability_name_line: LineEdit

#@export var sprite_viewer: Sprite3D


func _ready() -> void:
	sprite_options.item_selected.connect(_on_sprite_option_selected)
	anim_id_spin.value_changed.connect(_on_anim_id_spin_value_changed)
	weapon_options.item_selected.connect(func(idx) -> void: 
		unit.set_primary_weapon(idx))
	item_options.item_selected.connect(animation_manager.set_item)
	
	ability_id_spin.value_changed.connect(_on_ability_id_value_changed)
	unit.ability_assigned.connect(func(id): ability_id_spin.value = id)
	unit.primary_weapon_assigned.connect(func(id): weapon_options.select(id))

func _process(delta: float) -> void:
	if is_instance_valid(MapViewer.main_camera):
		position = MapViewer.main_camera.unproject_position(unit_char_body.position) + Vector2(50, -50)


func populate_options() -> void:
	weapon_options.clear()
	for weapon_index: int in RomReader.NUM_WEAPONS:
		var equipment_type_name: String = ""
		if RomReader.items[weapon_index].item_type < RomReader.fft_text.equipment_types.size():
			equipment_type_name = " (" + RomReader.fft_text.equipment_types[RomReader.items[weapon_index].item_type] + ")"
		weapon_options.add_item(str(weapon_index) + " - " + RomReader.items[weapon_index].name + equipment_type_name)
	
	item_options.clear()
	for item_index: int in RomReader.NUM_ITEMS:
		var type_name: String = ""
		if RomReader.items[item_index].item_type < RomReader.fft_text.equipment_types.size():
			type_name = " (" + RomReader.fft_text.equipment_types[RomReader.items[item_index].item_type] + ")"
		item_options.add_item(str(item_index) + " - " + RomReader.items[item_index].name + type_name )
	
	
	sprite_options.clear()
	for spr: Spr in RomReader.sprs:
		sprite_options.add_item(spr.file_name)


func populate_sprite_options() -> void:
	sprite_options.clear()
	for spr: Spr in RomReader.sprs:
		sprite_options.add_item(spr.file_name)


func enable_ui() -> void:
	weapon_options.disabled = false
	item_options.disabled = false
	other_type_options.disabled = false


func _on_sprite_option_selected(index: int) -> void:
	unit.on_sprite_idx_selected(index)


func _on_anim_id_spin_value_changed(value: int) -> void:
	animation_manager.global_animation_ptr_id = value


func _on_ability_id_value_changed(value: int) -> void:
	unit.set_ability(value)
	ability_name_line.text = RomReader.fft_text.ability_names[value]

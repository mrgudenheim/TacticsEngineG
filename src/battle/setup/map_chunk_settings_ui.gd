class_name MapChunkSettingsUi
extends Control

signal map_changed()

const settings_ui_scene: PackedScene = preload("res://src/battle/setup/map_chunk_settings.tscn")

@export var chunk_name_dropdown: OptionButton
@export var position_edit_container: Container
@export var mirror_bools_container: Container
@export var delete_button: Button

@export var position_edit: Vector3iEdit
@export var mirror_bools: Array[CheckBox]

@export var map_chunk: Scenario.MapChunk
@export var map: Map

func _ready() -> void:
	delete_button.pressed.connect(queue_free)


func add_row_to_table(settings_table: Container) -> void:
	chunk_name_dropdown.reparent(settings_table)
	position_edit_container.reparent(settings_table)
	mirror_bools_container.reparent(settings_table)
	delete_button.reparent(settings_table)


func on_map_selected(dropdown_item_index: int) -> void:
	var map_file_name: String = chunk_name_dropdown.get_item_text(dropdown_item_index)

	#clear_maps()
	#clear_units()
	#teams.clear()
	
	#load_scenario(RomReader.scenarios["test0"])


func _exit_tree() -> void:
	if is_queued_for_deletion():
		chunk_name_dropdown.queue_free()
		position_edit_container.queue_free()
		mirror_bools_container.queue_free()
		delete_button.queue_free()
		
		if map != null:
			map.queue_free()

class_name ActionInstance

signal action_completed(battle_manager: BattleManager)

var action: Action
var user: UnitData
var battle_manager: BattleManager

var potential_targets: Array[TerrainTile]
var potential_targets_highlights: Dictionary[TerrainTile, Node3D]
var preview_targets: Array[TerrainTile]
var preview_targets_highlights: Dictionary[TerrainTile, Node3D]
var submitted_targets: Array[TerrainTile]

var current_tile_hovered: TerrainTile
var potential_targets_are_set: bool = false

func _init(new_action: Action, new_user: UnitData, new_battle_manager: BattleManager) -> void:
	action = new_action
	user = new_user
	battle_manager = new_battle_manager


func clear() -> void:
	clear_targets(potential_targets_highlights)
	potential_targets.clear()
	
	clear_targets(preview_targets_highlights)
	preview_targets.clear()
	
	submitted_targets.clear()


func clear_targets(target_highlights: Dictionary[TerrainTile, Node3D]) -> void:
	for highlight: Node3D in target_highlights.values():
		highlight.queue_free()
	
	target_highlights.clear()


func is_usable() -> bool:
	return action.is_usable(self)


func update_potential_targets() -> void:
	clear_targets(potential_targets_highlights)
	potential_targets.clear()
	
	potential_targets = action.targeting_strategy.get_potential_targets(self)
	update_potential_targets_highlights()
	
	potential_targets_are_set = true


func update_potential_targets_highlights() -> void:
	var highlight_material: Material = battle_manager.tile_highlights[Color.WHITE]
	if is_usable():
		highlight_material = battle_manager.tile_highlights[Color.BLUE]
	
	potential_targets_highlights = get_tile_highlights(potential_targets, highlight_material)


func show_potential_targets() -> void:
	if not potential_targets_are_set:
		update_potential_targets()
	show_targets_highlights(potential_targets_highlights)


func hide_potential_targets() -> void:
	show_targets_highlights(potential_targets_highlights, false)


func show_targets_highlights(targets_highlights: Dictionary[TerrainTile, Node3D], show: bool = true) -> void:
	for highlight: Node3D in targets_highlights.values():
		highlight.visible = show


# TODO implement generic actions that can have tiles as targets, use this to highlight targets
func get_tile_highlights(tiles: Array[TerrainTile], highlight_material: Material) -> Dictionary[TerrainTile, Node3D]:
	var tile_highlights: Dictionary[TerrainTile, Node3D]
	for tile: TerrainTile in tiles:
		var new_tile_highlight: MeshInstance3D = tile.get_tile_mesh()
		new_tile_highlight.material_override = highlight_material # use pre-existing materials
		user.tile_highlights.add_child(new_tile_highlight)
		new_tile_highlight.position = tile.get_world_position(true) + Vector3(0, 0.025, 0)
		new_tile_highlight.visible = false
		tile_highlights[tile] = new_tile_highlight
	
	return tile_highlights


func start_targeting() -> void:
	# cancel any current targeting
	if is_instance_valid(user.active_action):
		user.active_action.stop_targeting()
	user.active_action = self
	action.targeting_strategy.start_targeting(self)


func stop_targeting() -> void:
	show_targets_highlights(potential_targets_highlights, false)
	show_targets_highlights(preview_targets_highlights, false)
	action.targeting_strategy.stop_targeting(self)


func use() -> void:
	stop_targeting()
	
	action.use(self)

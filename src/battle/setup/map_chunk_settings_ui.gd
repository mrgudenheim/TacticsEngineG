class_name MapChunkSettingsUi
extends Control

signal map_chunk_settings_changed(new_map_chunk_settings: MapChunkSettingsUi)

const settings_ui_scene: PackedScene = preload("res://src/battle/setup/map_chunk_settings.tscn")

@export var chunk_name_dropdown: OptionButton
@export var position_edit_container: Container
@export var mirror_bools_container: Container
@export var delete_button: Button

@export var position_edit: Vector3iEdit
@export var mirror_bools: Array[CheckBox]

@export var map_chunk: Scenario.MapChunk = Scenario.MapChunk.new()
@export var map_chunk_nodes: MapChunkNodes


static func instantiate() -> MapChunkSettingsUi:
	return settings_ui_scene.instantiate()


func _ready() -> void:
	delete_button.pressed.connect(queue_free)
	chunk_name_dropdown.item_selected.connect(on_map_selected)
	
	for map_data: MapData in RomReader.maps.values():
		chunk_name_dropdown.add_item(map_data.unique_name)
	
	var default_index: int = RomReader.maps.keys().find("map_056_orbonne_monastery")
	if default_index == -1:
		default_index = 0
	
	chunk_name_dropdown.select(default_index)
	chunk_name_dropdown.item_selected.emit(default_index)


func _exit_tree() -> void:
	if is_queued_for_deletion():
		chunk_name_dropdown.queue_free()
		position_edit_container.queue_free()
		mirror_bools_container.queue_free()
		delete_button.queue_free()
		
		if map_chunk_nodes != null:
			map_chunk_nodes.queue_free()


func add_row_to_table(settings_table: Container) -> void:
	chunk_name_dropdown.reparent(settings_table)
	position_edit_container.reparent(settings_table)
	mirror_bools_container.reparent(settings_table)
	delete_button.reparent(settings_table)


func on_map_selected(dropdown_item_index: int) -> void:
	map_chunk.unique_name = chunk_name_dropdown.get_item_text(dropdown_item_index)
	if map_chunk_nodes != null:
		map_chunk_nodes.queue_free()
	map_chunk.mirror_xyz[1] = true # vanilla maps need to be mirrored along y
	map_chunk.mirror_xyz[0] = true # mirror along x to get the un-mirrored look after mirroring along y
	map_chunk_nodes = get_map_mesh(map_chunk.unique_name)
	map_chunk_settings_changed.emit(self)


func get_map_mesh(map_chunk_unique_name: String) -> MapChunkNodes:
	var map_chunk_data: MapData = RomReader.maps[map_chunk_unique_name]
	if not map_chunk_data.is_initialized:
		map_chunk_data.init_map()

	var new_map_instance: MapChunkNodes = MapChunkNodes.instantiate()
	new_map_instance.map_data = map_chunk_data
	new_map_instance.name = map_chunk_data.unique_name
	
	# if gltf_map_mesh != null:
	# 	new_map_instance.mesh.queue_free()
	# 	var new_gltf_mesh: MeshInstance3D = gltf_map_mesh.duplicate()
	# 	new_map_instance.add_child(new_gltf_mesh)
	# 	new_map_instance.mesh = new_gltf_mesh
	# 	new_map_instance.mesh.rotation_degrees = Vector3.ZERO
	# else:

	var map_chunk_scale: Vector3 = Vector3.ONE
	if map_chunk.mirror_xyz[0]:
		map_chunk_scale.x = -1
	if map_chunk.mirror_xyz[1]:
		map_chunk_scale.y = -1
	if map_chunk.mirror_xyz[2]:
		map_chunk_scale.z = -1

	var mesh_aabb: AABB = map_chunk_data.mesh.get_aabb()
	# modify mesh based on mirroring and so bottom left corner is at (0, 0, 0)
	# TODO handle rotation
	if map_chunk_scale != Vector3.ONE or mesh_aabb.position != Vector3.ZERO:
		var surface_arrays: Array = map_chunk_data.mesh.surface_get_arrays(0)
		var original_mesh_center: Vector3 = mesh_aabb.get_center()
		for vertex_idx: int in surface_arrays[Mesh.ARRAY_VERTEX].size():
			var vertex: Vector3 = surface_arrays[Mesh.ARRAY_VERTEX][vertex_idx]
			vertex = vertex - original_mesh_center # shift center to be at (0, 0, 0) to make moving after mirroring easy
			vertex = vertex * map_chunk_scale # apply mirroring
			vertex = vertex + (mesh_aabb.size / 2.0) # shift so mesh_aabb start will be at (0, 0, 0)
			
			surface_arrays[Mesh.ARRAY_VERTEX][vertex_idx] = vertex
		
		# var new_array_index: Array = []
		# new_array_index.resize(surface_arrays[Mesh.ARRAY_VERTEX].size())
		# if mirrored along an odd number of axis polygons will render with the wrong facing
		var sum_scale: int = roundi(map_chunk_scale.x) + roundi(map_chunk_scale.y) + roundi(map_chunk_scale.z)
		if sum_scale % 2 == 1:
			for idx: int in surface_arrays[Mesh.ARRAY_VERTEX].size() / 3:
				var tri_idx: int = idx * 3
				var temp_vertex: Vector3 = surface_arrays[Mesh.ARRAY_VERTEX][tri_idx]
				surface_arrays[Mesh.ARRAY_VERTEX][tri_idx] = surface_arrays[Mesh.ARRAY_VERTEX][tri_idx + 2]
				surface_arrays[Mesh.ARRAY_VERTEX][tri_idx + 2] = temp_vertex

				var temp_uv: Vector2 = surface_arrays[Mesh.ARRAY_TEX_UV][tri_idx]
				surface_arrays[Mesh.ARRAY_TEX_UV][tri_idx] = surface_arrays[Mesh.ARRAY_TEX_UV][tri_idx + 2]
				surface_arrays[Mesh.ARRAY_TEX_UV][tri_idx + 2] = temp_uv

				# TODO fix ordering of normals for mirrored mesh?
		
		var modified_mesh: ArrayMesh = ArrayMesh.new()
		modified_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arrays)
		new_map_instance.mesh_instance.mesh = modified_mesh
	else:
		new_map_instance.mesh_instance.mesh = map_chunk_data.mesh

	new_map_instance.set_mesh_shader(map_chunk_data.albedo_texture_indexed, map_chunk_data.texture_palettes)
	new_map_instance.collision_shape.shape = new_map_instance.mesh_instance.mesh.create_trimesh_shape()
	
	return new_map_instance

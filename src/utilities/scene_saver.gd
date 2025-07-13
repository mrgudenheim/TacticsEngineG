class_name SceneSaver
extends Node3D

@export var node_to_save: MeshInstance3D


func save_scene() -> void:
	node_to_save.material_override = null
	
	var directory: String = "user://overrides/MAP/"
	DirAccess.make_dir_recursive_absolute(directory)
	var file_name: String = node_to_save.name
	var gltf_state: GLTFState = GLTFState.new()
	var gltf_document: GLTFDocument = GLTFDocument.new()
	
	gltf_document.append_from_scene(node_to_save, gltf_state)
	var extension: String = ".glb"
	gltf_document.write_to_filesystem(gltf_state, directory + file_name + extension)
	
	push_warning("Saved: " + directory + file_name + extension)


func import_gltf(file_name: String) -> Node:
	var directory: String = "user://overrides/MAP/"
	var gltf_state: GLTFState = GLTFState.new()
	var gltf_document: GLTFDocument = GLTFDocument.new()
	var import_path: String = directory + file_name + ".glb"
	var error = gltf_document.append_from_file(import_path, gltf_state, 0, directory)
	if error != 0:
		push_warning(file_name + " failed to import as glb: " + str(error))
		return null
	
	var node = gltf_document.generate_scene(gltf_state)
	node.name = file_name
	
	return node

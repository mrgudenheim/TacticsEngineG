class_name MapData

var file_name: String = "default map file name"
var mesh: ArrayMesh
var mesh_material: StandardMaterial3D
var albedo_texture: Texture2D
var st: SurfaceTool = SurfaceTool.new()

var num_text_tris: int
var num_text_quads: int
var num_black_tris: int
var num_black_quads: int

var text_tri_vertices: PackedVector3Array
var text_quad_vertices: PackedVector3Array
var black_tri_vertices: PackedVector3Array
var black_quad_vertices: PackedVector3Array

var text_tri_normals: PackedVector3Array
var text_quad_normals: PackedVector3Array

var tris_uvs: PackedVector2Array
var quads_uvs: PackedVector2Array
var tris_palettes: PackedInt32Array
var quads_palettes: PackedInt32Array

var texture_palettes: PackedColorArray


func create_map(bytes: PackedByteArray) -> void:	
	st.clear()
	num_text_tris
	num_text_quads
	num_black_tris
	num_black_quads
	set_map_data(bytes)
	_create_mesh()
	
	mesh_material.set_texture(BaseMaterial3D.TEXTURE_ALBEDO, albedo_texture)
	mesh.surface_set_material(0, mesh_material)
	
	# add mesh_node to scene? maybe should be in a different class
	var mesh_node = MeshInstance3D.new()
	mesh_node.mesh = mesh


func _create_mesh() -> void:
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# add textured tris
	for i: int in num_text_tris:
		for vertex_index: int in 3:
			var index: int = (i*3) + vertex_index
			st.set_normal(text_tri_normals[index])
			st.set_uv(tris_uvs[index])
			st.set_color(Color.WHITE)
			st.add_vertex(text_tri_vertices[index])
	
	# add black tris
	for i: int in num_black_tris:
		for vertex_index: int in 3:
			var index: int = (i*3) + vertex_index
			st.set_color(Color.BLACK)
			st.add_vertex(text_tri_vertices[index])
	
	# add textured quads
	for i: int in num_text_quads:
		var quad_start: int = i * 4
		var quad_end: int = (i + 1) * 4
		var quad_vertices: PackedVector3Array = text_quad_vertices.slice(quad_start, quad_end)
		var quad_normals: PackedVector3Array = text_quad_normals.slice(quad_start, quad_end)
		var quad_uvs: PackedVector2Array = quads_uvs.slice(quad_start, quad_end)
		var quad_colors: PackedColorArray
		quad_colors.resize(4)
		quad_colors.fill(Color.WHITE)
		
		st.add_triangle_fan(quad_vertices, quad_uvs, quad_colors, PackedVector2Array(), quad_normals)
	
	# add black quads
	for i: int in num_black_quads:
		var quad_start: int = i * 4
		var quad_end: int = (i + 1) * 4
		var quad_vertices: PackedVector3Array = text_quad_vertices.slice(quad_start, quad_end)
		var quad_colors: PackedColorArray
		quad_colors.resize(4)
		quad_colors.fill(Color.BLACK)
		
		st.add_triangle_fan(quad_vertices, PackedVector2Array(), quad_colors)
	
	mesh = st.commit()


func set_map_data(bytes: PackedByteArray) -> void:
	_set_text_tri_vertices(bytes)
	_set_text_quad_vertices(bytes)
	_set_black_tri_vertices(bytes)
	_set_black_qaud_vertices(bytes)
	_set_text_tri_normals(bytes)
	_set_text_quad_normals(bytes)
	_set_tris_uvs(bytes)
	_set_quads_uvs(bytes)
	_set_texture_palettes(bytes)


func _set_text_tri_vertices(bytes: PackedByteArray) -> void:
	text_tri_vertices


func _set_text_quad_vertices(bytes: PackedByteArray) -> void:
	text_quad_vertices


func _set_black_tri_vertices(bytes: PackedByteArray) -> void:
	black_tri_vertices


func _set_black_qaud_vertices(bytes: PackedByteArray) -> void:
	black_quad_vertices


func _set_text_tri_normals(bytes: PackedByteArray) -> void:
	text_tri_normals


func _set_text_quad_normals(bytes: PackedByteArray) -> void:
	text_quad_normals


func _set_tris_uvs(bytes: PackedByteArray) -> void:
	tris_uvs
	tris_palettes


func _set_quads_uvs(bytes: PackedByteArray) -> void:
	quads_uvs
	quads_palettes


func _set_texture_palettes(bytes: PackedByteArray) -> void:
	texture_palettes


func _set_texture(bytes: PackedByteArray) -> void:
	albedo_texture

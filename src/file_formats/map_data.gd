#https://ffhacktics.com/wiki/Maps/Mesh
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
	set_map_data(bytes)
	
	
	st.clear()
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
	var primary_mesh_data: PackedByteArray = bytes.slice(bytes.decode_u32(0x40), bytes.decode_u32(0x44))
	num_text_tris = primary_mesh_data.decode_u16(0)
	num_text_quads = primary_mesh_data.decode_u16(2)
	num_black_tris = primary_mesh_data.decode_u16(4)
	num_black_quads = primary_mesh_data.decode_u16(6)
	
	var text_tris_vertices_data_length: int = num_text_tris * 2 * 3 * 3
	var text_quad_vertices_data_length: int = num_text_quads * 2 * 3 * 4
	var black_tris_vertices_data_length: int = num_black_tris * 2 * 3 * 3
	var black_quads_vertices_data_length: int = num_black_quads * 2 * 3 * 4
	var tris_uvs_data_length: int = num_text_tris * 10
	var quad_uvs_data_length: int = num_text_quads * 12
	
	var text_quad_vertices_start: int = 8 + text_tris_vertices_data_length
	var black_tris_vertices_start: int = text_quad_vertices_start + text_quad_vertices_data_length
	var black_quads_vertices_start: int = black_tris_vertices_start + black_tris_vertices_data_length
	var text_tri_normals_start: int = black_quads_vertices_start + black_quads_vertices_data_length
	var text_quad_normals_start: int = text_tri_normals_start + text_tris_vertices_data_length
	var tris_uvs_start: int = text_quad_normals_start + text_quad_vertices_data_length
	var quads_uvs_start: int = tris_uvs_start + tris_uvs_data_length
	
	#_set_text_tri_vertices(primary_mesh_data.slice(8, text_quad_vertices_start))
	#_set_text_quad_vertices(primary_mesh_data.slice(text_quad_vertices_start, black_tris_vertices_start))
	#_set_black_tri_vertices(primary_mesh_data.slice(black_tris_vertices_start, black_quads_vertices_start))
	#_set_black_qaud_vertices(primary_mesh_data.slice(black_quads_vertices_start, text_tri_normals_start))
	#_set_text_tri_normals(primary_mesh_data.slice(text_tri_normals_start, text_quad_normals_start))
	#_set_text_quad_normals(primary_mesh_data.slice(text_quad_normals_start, tris_uvs_start))
	#_set_tris_uvs(primary_mesh_data.slice(tris_uvs_start, quads_uvs_start))
	#_set_quads_uvs(primary_mesh_data.slice(quads_uvs_start, quads_uvs_start + quad_uvs_data_length))
	
	text_tri_vertices = get_vertices(primary_mesh_data.slice(8, text_quad_vertices_start), num_text_tris * 3)
	text_quad_vertices = get_vertices(primary_mesh_data.slice(text_quad_vertices_start, black_tris_vertices_start), num_text_quads * 4)
	black_tri_vertices = get_vertices(primary_mesh_data.slice(black_tris_vertices_start, black_quads_vertices_start), num_black_tris * 3)
	black_quad_vertices = get_vertices(primary_mesh_data.slice(black_quads_vertices_start, text_tri_normals_start), num_black_quads * 4)
	
	text_tri_normals = get_normals(primary_mesh_data.slice(text_tri_normals_start, text_quad_normals_start), num_text_tris * 3)
	text_quad_normals = get_normals(primary_mesh_data.slice(text_quad_normals_start, tris_uvs_start), num_text_quads * 4)
	
	tris_uvs = get_uvs(primary_mesh_data.slice(tris_uvs_start, quads_uvs_start), num_text_tris, false)
	quads_uvs = get_uvs(primary_mesh_data.slice(quads_uvs_start, quads_uvs_start + quad_uvs_data_length), num_text_quads, true)
	
	var texture_palettes_data_start: int = bytes.decode_u32(0x44)
	if texture_palettes_data_start == 0:
		push_warning("No palette data found")
		return
	
	var texture_palettes_data_end: int = texture_palettes_data_start + 512	
	var texture_palettes_data: PackedByteArray = bytes.slice(texture_palettes_data_start, texture_palettes_data_end)
	_set_texture_palettes(texture_palettes_data)


func get_vertices(vertex_bytes: PackedByteArray, num_vertices: int) -> PackedVector3Array:
	var vertices: PackedVector3Array = []
	
	for vertex_index: int in num_vertices:
		var byte_index: int = vertex_index * 6
		var x: int = vertex_bytes.decode_s16(byte_index)
		var y: int = vertex_bytes.decode_s16(byte_index + 2)
		var z: int = vertex_bytes.decode_s16(byte_index + 4)
		
		var vertex: Vector3 = Vector3(x, y, z)
		vertices.append(vertex)
	
	return vertices


func get_normals(normals_bytes: PackedByteArray, num_vertices: int) -> PackedVector3Array:
	var normals: PackedVector3Array = []
	
	for vertex_index: int in num_vertices:
		var byte_index: int = vertex_index * 6
		var x: float = normals_bytes.decode_s16(byte_index) / 4096.0
		var y: float = normals_bytes.decode_s16(byte_index + 2) / 4096.0 
		var z: float = normals_bytes.decode_s16(byte_index + 4) / 4096.0
		
		var normal: Vector3 = Vector3(x, y, z)
		normals.append(normal)
	
	return normals


func get_uvs(uvs_bytes: PackedByteArray, num_polys: int, is_quad = false) -> PackedVector2Array:
	var uvs: PackedVector2Array = []
	
	var data_length: int = 10
	if is_quad:
		data_length = 12
	
	for poly_index: int in num_polys:
		var byte_index: int = poly_index * data_length
		
		var texture_page: int = uvs_bytes.decode_u8(byte_index + 6) & 0b0000_0011 # two right most bits are texture page
		var v_offset: int = texture_page * 256
		var palette_index: int = uvs_bytes.decode_u8(byte_index + 2) # TODO store this somewhere?
		
		# TODO do u and v need to be percentage, ie. u / 256 and v / 1024
		var au: int = uvs_bytes.decode_u8(byte_index)
		var av: int = uvs_bytes.decode_u8(byte_index + 1) + v_offset
		var bu: int = uvs_bytes.decode_u8(byte_index + 4)
		var bv: int = uvs_bytes.decode_u8(byte_index + 5) + v_offset
		var cu: int = uvs_bytes.decode_u8(byte_index + 8)
		var cv: int = uvs_bytes.decode_u8(byte_index + 9) + v_offset
		
		var auv: Vector2 = Vector2(au, av)
		var buv: Vector2 = Vector2(bu, bv)
		var cuv: Vector2 = Vector2(cu, cv)
		uvs.append(auv)
		uvs.append(buv)
		uvs.append(cuv)
		
		if is_quad:
			var du: int = uvs_bytes.decode_u8(byte_index + 10)
			var dv: int = uvs_bytes.decode_u8(byte_index + 11) + v_offset
			var duv: Vector2 = Vector2(du, dv)
			uvs.append(duv)
	
	return uvs


#func _set_text_tri_vertices(text_tris_vertex_bytes: PackedByteArray) -> void:
	#for tris_vertex_index: int in (num_text_tris * 3):
		#var byte_index: int = tris_vertex_index * 6
		#var x: int = text_tris_vertex_bytes.decode_s16(byte_index)
		#var y: int = text_tris_vertex_bytes.decode_s16(byte_index + 2)
		#var z: int = text_tris_vertex_bytes.decode_s16(byte_index + 4)
		#
		#var vertex: Vector3 = Vector3(x, y, z)
		#text_tri_vertices.append(vertex)
#
#
#func _set_text_quad_vertices(text_quads_vertex_bytes: PackedByteArray) -> void:
	#for quads_vertex_index: int in (num_text_quads * 4):
		#var byte_index: int = quads_vertex_index * 6
		#var x: int = text_quads_vertex_bytes.decode_s16(byte_index)
		#var y: int = text_quads_vertex_bytes.decode_s16(byte_index + 2)
		#var z: int = text_quads_vertex_bytes.decode_s16(byte_index + 4)
		#
		#var vertex: Vector3 = Vector3(x, y, z)
		#text_quad_vertices.append(vertex)
#
#
#func _set_black_tri_vertices(black_tris_vertex_bytes: PackedByteArray) -> void:
	#black_tri_vertices
#
#
#func _set_black_qaud_vertices(black_quads_vertex_bytes: PackedByteArray) -> void:
	#black_quad_vertices
#
#
#func _set_text_tri_normals(text_tris_normals_bytes: PackedByteArray) -> void:
	#text_tri_normals
#
#
#func _set_text_quad_normals(text_quads_normals_bytes: PackedByteArray) -> void:
	#text_quad_normals
#
#
#func _set_tris_uvs(tris_uvs_bytes: PackedByteArray) -> void:
	#tris_uvs
	#tris_palettes
#
#
#func _set_quads_uvs(quads_uvs_bytes: PackedByteArray) -> void:
	#quads_uvs
	#quads_palettes


func _set_texture_palettes(texture_palettes_bytes: PackedByteArray) -> void:
	texture_palettes


func _set_texture(texture_bytes: PackedByteArray) -> void:
	albedo_texture

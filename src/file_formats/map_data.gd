#https://ffhacktics.com/wiki/Maps/Mesh
class_name MapData

var file_name: String = "default map file name"
var mesh: ArrayMesh
var mesh_material: StandardMaterial3D
var albedo_texture: Texture2D
var st: SurfaceTool = SurfaceTool.new()
const TEXTURE_SIZE: Vector2i = Vector2i(256, 1024)

var num_text_tris: int = 0
var num_text_quads: int = 0
var num_black_tris: int = 0
var num_black_quads: int = 0

var text_tri_vertices: PackedVector3Array = []
var text_quad_vertices: PackedVector3Array = []
var black_tri_vertices: PackedVector3Array = []
var black_quad_vertices: PackedVector3Array = []

var text_tri_normals: PackedVector3Array = []
var text_quad_normals: PackedVector3Array = []

var tris_uvs: PackedVector2Array = []
var quads_uvs: PackedVector2Array = []
var tris_palettes: PackedInt32Array = []
var quads_palettes: PackedInt32Array = []

var texture_palettes: PackedColorArray = []
var texture_color_indices: PackedInt32Array = []

func create_map(mesh_bytes: PackedByteArray, texture_bytes: PackedByteArray = [], palette_id: int = 0) -> void:
	set_mesh_data(mesh_bytes)
	
	_create_mesh()
	
	#albedo_texture = get_texture(texture_bytes, palette_id)
	albedo_texture = get_texture_all(texture_bytes)
	mesh_material = StandardMaterial3D.new()
	mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mesh_material.vertex_color_use_as_albedo = true
	mesh_material.set_texture(BaseMaterial3D.TEXTURE_ALBEDO, albedo_texture)
	mesh.surface_set_material(0, mesh_material)


func clear_map_data() -> void:
	mesh = null
	mesh_material = null
	albedo_texture = null
	
	num_text_tris = 0
	num_text_quads = 0
	num_black_tris = 0
	num_black_quads = 0
	
	text_tri_vertices = []
	text_quad_vertices = []
	black_tri_vertices = []
	black_quad_vertices = []
	
	text_tri_normals = []
	text_quad_normals = []
	
	tris_uvs = []
	quads_uvs = []
	tris_palettes = []
	quads_palettes = []
	
	texture_palettes = []
	texture_color_indices = []


func _create_mesh() -> void:
	st.clear()
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
			st.add_vertex(black_tri_vertices[index])
	
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
		
		for vert_index: int in [0, 1, 2]:
			st.set_normal(quad_normals[vert_index])
			st.set_uv(quad_uvs[vert_index])
			st.set_color(Color.WHITE)
			st.add_vertex(quad_vertices[vert_index])
		
		for vert_index: int in [3, 2, 1]:
			st.set_normal(quad_normals[vert_index])
			st.set_uv(quad_uvs[vert_index])
			st.set_color(Color.WHITE)
			st.add_vertex(quad_vertices[vert_index])
	
	# add black quads
	for i: int in num_black_quads:
		var quad_start: int = i * 4
		var quad_end: int = (i + 1) * 4
		var quad_vertices: PackedVector3Array = black_quad_vertices.slice(quad_start, quad_end)
		var quad_colors: PackedColorArray
		quad_colors.resize(4)
		quad_colors.fill(Color.BLACK)
		
		for vert_index: int in [0, 1, 2]:
			st.set_color(Color.BLACK)
			st.add_vertex(quad_vertices[vert_index])
		
		for vert_index: int in [3, 2, 1]:
			st.set_color(Color.BLACK)
			st.add_vertex(quad_vertices[vert_index])
	
	mesh = st.commit()


func set_mesh_data(bytes: PackedByteArray) -> void:
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
	
	text_tri_vertices = get_vertices(primary_mesh_data.slice(8, text_quad_vertices_start), num_text_tris * 3)
	text_quad_vertices = get_vertices(primary_mesh_data.slice(text_quad_vertices_start, black_tris_vertices_start), num_text_quads * 4)
	black_tri_vertices = get_vertices(primary_mesh_data.slice(black_tris_vertices_start, black_quads_vertices_start), num_black_tris * 3)
	black_quad_vertices = get_vertices(primary_mesh_data.slice(black_quads_vertices_start, text_tri_normals_start), num_black_quads * 4)
	
	text_tri_normals = get_normals(primary_mesh_data.slice(text_tri_normals_start, text_quad_normals_start), num_text_tris * 3)
	text_quad_normals = get_normals(primary_mesh_data.slice(text_quad_normals_start, tris_uvs_start), num_text_quads * 4)
	
	#tris_uvs = get_uvs(primary_mesh_data.slice(tris_uvs_start, quads_uvs_start), num_text_tris, false)
	#quads_uvs = get_uvs(primary_mesh_data.slice(quads_uvs_start, quads_uvs_start + quad_uvs_data_length), num_text_quads, true)
	tris_uvs = get_uvs_all_palettes(primary_mesh_data.slice(tris_uvs_start, quads_uvs_start), num_text_tris, false)
	quads_uvs = get_uvs_all_palettes(primary_mesh_data.slice(quads_uvs_start, quads_uvs_start + quad_uvs_data_length), num_text_quads, true)
	
	var texture_palettes_data_start: int = bytes.decode_u32(0x44)
	if texture_palettes_data_start == 0:
		push_warning("No palette data found")
		return
	
	var texture_palettes_data_end: int = texture_palettes_data_start + 512	
	var texture_palettes_data: PackedByteArray = bytes.slice(texture_palettes_data_start, texture_palettes_data_end)
	texture_palettes = get_texture_palettes(texture_palettes_data)


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
		
		var texture_page: int = uvs_bytes.decode_u8(byte_index + 6) & 0b11 # two right most bits are texture page
		var v_offset: int = texture_page * 256
		var palette_index: int = uvs_bytes.decode_u8(byte_index + 2)
		var x_offset: int = palette_index * 256
		
		# u and v need to be percentage, ie. u / width and v / height
		var au: float = uvs_bytes.decode_u8(byte_index) / 256.0
		var av: float = (uvs_bytes.decode_u8(byte_index + 1) + v_offset) / float(TEXTURE_SIZE.y)
		var bu: float = uvs_bytes.decode_u8(byte_index + 4) / 256.0
		var bv: float = (uvs_bytes.decode_u8(byte_index + 5) + v_offset) / float(TEXTURE_SIZE.y)
		var cu: float = uvs_bytes.decode_u8(byte_index + 8) / 256.0
		var cv: float = (uvs_bytes.decode_u8(byte_index + 9) + v_offset) / float(TEXTURE_SIZE.y)
		
		var auv: Vector2 = Vector2(au, av)
		var buv: Vector2 = Vector2(bu, bv)
		var cuv: Vector2 = Vector2(cu, cv)
		uvs.append(auv)
		uvs.append(buv)
		uvs.append(cuv)
		
		if is_quad:
			var du: float = uvs_bytes.decode_u8(byte_index + 10) / 256.0
			var dv: float = (uvs_bytes.decode_u8(byte_index + 11) + v_offset) / float(TEXTURE_SIZE.y)
			
			var duv: Vector2 = Vector2(du, dv)
			uvs.append(duv)
			quads_palettes.append(palette_index)
		else:
			tris_palettes.append(palette_index)
	
	return uvs


func get_uvs_all_palettes(uvs_bytes: PackedByteArray, num_polys: int, is_quad = false) -> PackedVector2Array:
	var uvs: PackedVector2Array = []
	var num_palettes: int = 8
	
	var data_length: int = 10
	if is_quad:
		data_length = 12
	
	for poly_index: int in num_polys:
		var byte_index: int = poly_index * data_length
		
		var texture_page: int = uvs_bytes.decode_u8(byte_index + 6) & 0b11 # two right most bits are texture page
		var v_offset: int = texture_page * 256
		var palette_index: int = uvs_bytes.decode_u8(byte_index + 2)
		var x_offset: int = palette_index * 256
		
		# u and v need to be percentage, ie. u / width and v / height
		var au: float = (uvs_bytes.decode_u8(byte_index) + x_offset) / float(TEXTURE_SIZE.x * num_palettes)
		var av: float = (uvs_bytes.decode_u8(byte_index + 1) + v_offset) / float(TEXTURE_SIZE.y)
		var bu: float = (uvs_bytes.decode_u8(byte_index + 4) + x_offset) / float(TEXTURE_SIZE.x * num_palettes)
		var bv: float = (uvs_bytes.decode_u8(byte_index + 5) + v_offset) / float(TEXTURE_SIZE.y)
		var cu: float = (uvs_bytes.decode_u8(byte_index + 8) + x_offset) / float(TEXTURE_SIZE.x * num_palettes)
		var cv: float = (uvs_bytes.decode_u8(byte_index + 9) + v_offset) / float(TEXTURE_SIZE.y)
		
		var auv: Vector2 = Vector2(au, av)
		var buv: Vector2 = Vector2(bu, bv)
		var cuv: Vector2 = Vector2(cu, cv)
		uvs.append(auv)
		uvs.append(buv)
		uvs.append(cuv)
		
		if is_quad:
			var du: float = (uvs_bytes.decode_u8(byte_index + 10) + x_offset) / float(TEXTURE_SIZE.x * num_palettes)
			var dv: float = (uvs_bytes.decode_u8(byte_index + 11) + v_offset) / float(TEXTURE_SIZE.y)
			
			var duv: Vector2 = Vector2(du, dv)
			uvs.append(duv)
			quads_palettes.append(palette_index)
		else:
			tris_palettes.append(palette_index)
	
	return uvs


func get_texture_palettes(texture_palettes_bytes: PackedByteArray) -> PackedColorArray:
	var new_texture_palettes: PackedColorArray = []
	var num_colors: int = 256 # 16 palettes of 16 colors each
	new_texture_palettes.resize(num_colors)
	
	for i: int in num_colors:
		var color: Color = Color.BLACK
		var color_bits: int = texture_palettes_bytes.decode_u16(i * 2)
		color.a8 = (color_bits & 0b1000_0000_0000_0000) >> 15 # first bit is alpha (if bit is zero, color is transparent)
		color.b8 = (color_bits & 0b0111_1100_0000_0000) >> 10 # then 5 bits each: blue, green, red
		color.g8 = (color_bits & 0b0000_0011_1110_0000) >> 5
		color.r8 = color_bits & 0b0000_0000_0001_1111
		
		# convert 5 bit channels to 8 bit
		color.a8 = 255 * color.a8 # first bit is alpha (if bit is one, color is opaque)
		#color.a8 = 255 # TODO use alpha correctly
		color.b8 = roundi(255 * (color.b8 / float(31))) # then 5 bits each: blue, green, red
		color.g8 = roundi(255 * (color.g8 / float(31)))
		color.r8 = roundi(255 * (color.r8 / float(31)))
		
		# if R == G == B == A == 0, then the color is transparent. 
		#if (color == Color(0, 0, 0, 0)):
			#color.a8 = 0
		if (i % 16) == 0:
			color.a8 = 0
		else:
			color.a8 = 255
		new_texture_palettes[i] = color
	
	return new_texture_palettes


func get_texture_color_indices(texture_bytes: PackedByteArray) -> PackedInt32Array:
	var new_color_indicies: PackedInt32Array = []
	var bits_per_pixel: int = 4
	new_color_indicies.resize(texture_bytes.size() * 2)
	
	for i: int in new_color_indicies.size():
		var pixel_offset: int = (i * bits_per_pixel)/8
		var byte: int = texture_bytes.decode_u8(pixel_offset)
		
		if i % 2 == 1: # get 4 leftmost bits
			new_color_indicies[i] = byte >> 4
		else:
			new_color_indicies[i] = byte & 0b0000_1111 # get 4 rightmost bits
	
	return new_color_indicies


func get_texture_pixel_colors(palette_id: int = 0) -> PackedColorArray:
	var new_pixel_colors: PackedColorArray = []
	var new_size: int = TEXTURE_SIZE.x * TEXTURE_SIZE.y
	new_pixel_colors.resize(new_size)
	new_pixel_colors.fill(Color.BLACK)
	for i: int in new_size:
		new_pixel_colors[i] = texture_palettes[texture_color_indices[i] + (16 * palette_id)]
	
	return new_pixel_colors


func get_texture_rgba8_image(palette_id: int = 0) -> Image:
	var image: Image = Image.create_empty(TEXTURE_SIZE.x, TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	var pixel_colors: PackedColorArray = get_texture_pixel_colors(palette_id)
	
	for x in TEXTURE_SIZE.x:
		for y in TEXTURE_SIZE.y:
			var color: Color = pixel_colors[x + (y * TEXTURE_SIZE.x)]
			var color8: Color = Color8(color.r8, color.g8, color.b8, color.a8) # use Color8 function to prevent issues with format conversion changing color by 1/255
			image.set_pixel(x,y, color8) # spr stores pixel data left to right, top to bottm
	
	return image


func get_texture(texture_bytes: PackedByteArray, palette_id = 0) -> Texture2D:
	texture_color_indices = get_texture_color_indices(texture_bytes)
	
	#var unique_palettes: Dictionary = {}
	#for palette_index: int in tris_palettes:
		#unique_palettes[palette_index] = 1
	#push_warning("Tris palettes: " + str(unique_palettes.keys()))
	#
	#unique_palettes.clear()
	#for palette_index: int in quads_palettes:
		#unique_palettes[palette_index] = 1
	#push_warning("Quads palettes: " + str(unique_palettes.keys()))
	
	return ImageTexture.create_from_image(get_texture_rgba8_image(palette_id))


func get_texture_color_indices_all(color_indices: PackedInt32Array) -> PackedInt32Array:
	var new_color_indicies: PackedInt32Array = []
	var num_palettes: int = 8
	var colors_per_palette: int = 16
	
	for row_index in (color_indices.size() / TEXTURE_SIZE.x):
		var row_start_index: int = row_index * TEXTURE_SIZE.x
		var row_end_index: int = row_start_index + TEXTURE_SIZE.x
		var row_indices: PackedInt32Array = color_indices.slice(row_start_index, row_end_index)
		
		for palette_index: int in num_palettes:			
			var row_indices_adjusted: PackedInt32Array = []
			row_indices_adjusted.resize(TEXTURE_SIZE.x)
			row_indices_adjusted.fill(palette_index * colors_per_palette)
			
			for i: int in TEXTURE_SIZE.x:
				row_indices_adjusted[i] += row_indices[i]
			
			new_color_indicies.append_array(row_indices_adjusted)
	
	return new_color_indicies


func get_texture_pixel_colors_all() -> PackedColorArray:
	var new_pixel_colors: PackedColorArray = []
	var num_palettes: int = 8
	var new_size: int = TEXTURE_SIZE.x * TEXTURE_SIZE.y * num_palettes
	new_pixel_colors.resize(new_size)
	new_pixel_colors.fill(Color.BLACK)
	
	var texture_color_indices_all: PackedInt32Array = get_texture_color_indices_all(texture_color_indices)
	
	for i: int in new_size:
		new_pixel_colors[i] = texture_palettes[texture_color_indices_all[i]]
	
	return new_pixel_colors


func get_texture_rgba8_image_all() -> Image:
	var num_palettes: int = 8
	var image_width: int = TEXTURE_SIZE.x * num_palettes
	var image: Image = Image.create_empty(image_width, TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	var pixel_colors: PackedColorArray = get_texture_pixel_colors_all()
	
	for x in image_width:
		for y in TEXTURE_SIZE.y:
			var color: Color = pixel_colors[x + (y * image_width)]
			var color8: Color = Color8(color.r8, color.g8, color.b8, color.a8) # use Color8 function to prevent issues with format conversion changing color by 1/255
			image.set_pixel(x,y, color8) # spr stores pixel data left to right, top to bottm
	
	return image


func get_texture_all(texture_bytes: PackedByteArray) -> Texture2D:
	texture_color_indices = get_texture_color_indices(texture_bytes)
	
	var image: Image = get_texture_rgba8_image_all()
	return ImageTexture.create_from_image(image)

shader_type spatial;

uniform sampler2D albedo_texture_color_indicies : source_color;
//uniform int total_texture_width;
//uniform int single_texture_width;
//uniform int palette_ids_to_animate[1];
//uniform vec4 color_indices[16];
uniform vec4 palettes_colors[256] : source_color; // 16 palettes of 16 colors each, TODO should this be an instance uniform?

// per instance uniform so a unique material is not required for each map
instance uniform vec4 my_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);

//void vertex() {
	//COLOR.rgba = animation_palettes_colors[int(round(texture(albedo_texture_color_indicies, UV).r * float(255)))];
//}
//
//void fragment() {
	//int palette_id = int(floor(UV.x * float(total_texture_width) / float(texture_width)));
	//if (palette_id == palette_ids_to_animate[0]) {
		//COLOR.rgba = 
	//}
//}

void fragment() {
	vec4 new_color = palettes_colors[int(round(texture(albedo_texture_color_indicies, UV).r * 255.0))];
	ALBEDO.rgb = new_color.rgb;
	ALPHA = new_color.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

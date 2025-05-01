shader_type spatial;

uniform sampler2D albedo_texture_color_indicies : source_color;
uniform vec4 palettes_colors[256] : source_color; // 16 palettes of 16 colors each, TODO should this be an instance uniform?

void fragment() {
	vec4 new_color = palettes_colors[int(round(texture(albedo_texture_color_indicies, UV).r * 255.0))];
	ALBEDO.rgb = new_color.rgb;
	ALPHA = new_color.a;
}
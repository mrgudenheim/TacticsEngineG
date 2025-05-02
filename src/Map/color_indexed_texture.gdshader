// https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html

shader_type spatial;
render_mode unshaded, depth_prepass_alpha;

uniform sampler2D albedo_texture_color_indicies : source_color, filter_nearest;
uniform vec4[256] palettes_colors : source_color; // 16 palettes of 16 colors each, TODO should this be an instance uniform?

void fragment() {
	vec4 new_color = palettes_colors[int(round(texture(albedo_texture_color_indicies, UV).r * 255.0))];
	//new_color = texture(albedo_texture_color_indicies, UV);
	ALBEDO.rgb = new_color.rgb;
	ALPHA = new_color.a;
}
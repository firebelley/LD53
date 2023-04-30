shader_type canvas_item;


uniform sampler2D noise_texture : filter_nearest, repeat_enable;
uniform vec4 color_one : source_color;
uniform vec4 color_two : source_color;
uniform vec4 color_three : source_color;
uniform vec4 color_four : source_color;

void fragment() {
	vec2 adjusted_uv_one = (UV * vec2(3.0, 7.0)) + vec2(0.05 * TIME, 0);
	vec2 adjusted_uv_two = (UV * vec2(3.0, 7.0)) + vec2(0.02 * TIME, 0);
	vec2 adjusted_uv_three = (UV * vec2(3.0, 7.0)) + vec2(0.1 * TIME, 0);
	vec2 adjusted_uv_four = (UV * vec2(3.0, 7.0)) + vec2(0, 0.15 * TIME);
	vec2 surface_uv = (UV) + vec2(0.3 * TIME, 0);
	float noise_sample_one = texture(noise_texture, adjusted_uv_one).r;
	float noise_sample_two = texture(noise_texture, adjusted_uv_two).r;
	float noise_sample_three = texture(noise_texture, adjusted_uv_three).r;
	float noise_sample_four = texture(noise_texture, adjusted_uv_four).r;
	float surface_noise_sample = texture(noise_texture, surface_uv).r;
	
	
	float average = (noise_sample_one + noise_sample_two + noise_sample_three + noise_sample_four) / 4.0;
	
	if (average > .65) {
		COLOR = color_four;
	}
	else if (average > .45) {
		COLOR = color_one;
	}
	else if (average > .3) {
		COLOR = color_two;
	}
	else {
		COLOR = color_three;
	}
	
	if ((average * UV.y) < .006) {
		COLOR = color_two;
	}
	if ((average * UV.y) < .003) {
		COLOR.a = 0.0;
	}
}

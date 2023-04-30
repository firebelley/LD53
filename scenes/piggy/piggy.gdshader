shader_type canvas_item;

void fragment() {
	vec2 adjusted_uv = UV + vec2(TIME * -4.0, 0.0);
	COLOR = texture(TEXTURE, adjusted_uv);
}

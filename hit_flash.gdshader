shader_type canvas_item;

uniform bool active = false;
uniform float r = 1.0;
uniform float g = 1.0;
uniform float b = 1.0;

void fragment() {
	vec4 previous_color = texture(TEXTURE, UV);
	vec4 change_color = vec4(r, g, b, previous_color.a);
	vec4 new_color = previous_color;
	if (active == true) {
		new_color = change_color;
	}
	COLOR = new_color;
}

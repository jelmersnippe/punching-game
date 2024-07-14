shader_type canvas_item;

uniform float intensity = 0.0;

void fragment() {
	COLOR = mix(vec4(0.0), vec4(1.0,0.0,0.0,1.0), intensity);
}

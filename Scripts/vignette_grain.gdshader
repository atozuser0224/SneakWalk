shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.22;
uniform float grain_strength : hint_range(0.0, 0.08) = 0.012;

float hash12(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 base = texture(screen_texture, uv).rgb;

	float aspect = 1.7778;
	vec2 vd = (uv - vec2(0.5)) * vec2(aspect, 1.0);
	float vig = smoothstep(0.5, 1.25, length(vd)) * vignette_strength;
	base *= 1.0 - vig;

	float grain = (hash12(uv * vec2(1920.0, 1080.0) + fract(TIME) * 71.0) - 0.5) * grain_strength;
	base += grain;

	COLOR = vec4(base, 1.0);
}

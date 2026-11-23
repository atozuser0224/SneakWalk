shader_type canvas_item;
render_mode blend_add;

uniform vec4 beam_color : source_color = vec4(1.0, 0.87, 0.63, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 0.4;
uniform float softness : hint_range(0.0, 1.0) = 0.55;

float hash12(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x),
		mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

void fragment() {
	vec2 uv = UV;
	float across = abs(uv.x - 0.5) * 2.0;
	float edge = smoothstep(1.0, 1.0 - softness, across);
	float fade = pow(clamp(1.0 - uv.y, 0.0, 1.0), 1.6);
	float start = smoothstep(0.0, 0.06, uv.y);
	float dust = 0.75 + 0.25 * value_noise(vec2(uv.x * 7.0, uv.y * 3.0 - TIME * 0.12));
	float a = edge * fade * start * dust * intensity;
	COLOR = vec4(beam_color.rgb, a);
}

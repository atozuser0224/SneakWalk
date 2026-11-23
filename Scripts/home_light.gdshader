shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 light_center = vec2(0.3, 0.16);
uniform vec4 light_color : source_color = vec4(1.0, 0.86, 0.64, 1.0);
uniform float light_radius : hint_range(0.0, 2.0) = 0.95;
uniform float light_strength : hint_range(0.0, 1.0) = 0.22;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.18;
uniform float grain_strength : hint_range(0.0, 0.08) = 0.018;
uniform float sway : hint_range(0.0, 0.2) = 0.015;

float hash12(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 base = texture(screen_texture, uv).rgb;

	float aspect = 1.7778;
	vec2 center = light_center + vec2(sin(TIME * 0.22) * sway, cos(TIME * 0.17) * sway * 0.6);
	vec2 d = (uv - center) * vec2(aspect, 1.0);
	float glow = 1.0 - smoothstep(0.0, light_radius, length(d));
	glow = pow(glow, 2.2) * light_strength;

	vec3 lit = base + light_color.rgb * glow;
	lit = mix(lit, lit * light_color.rgb, glow * 0.5);

	vec2 vd = (uv - vec2(0.5)) * vec2(aspect, 1.0);
	float vig = smoothstep(0.45, 1.2, length(vd)) * vignette_strength;
	lit *= 1.0 - vig;

	float grain = (hash12(uv * vec2(1920.0, 1080.0) + fract(TIME) * 97.0) - 0.5) * grain_strength;
	lit += grain;

	COLOR = vec4(lit, 1.0);
}

shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D occluder_map : repeat_disable, filter_linear;
uniform vec2 viewport_size = vec2(1920.0, 1080.0);
uniform vec2 pano_offset = vec2(0.0, 0.0);
uniform vec2 pano_size = vec2(7680.0, 1080.0);
uniform vec2 light_pos[1];
uniform float light_energy[1];
uniform float floor_y = 0.865;
uniform float ao_strength : hint_range(0.0, 1.0) = 0.35;
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.4;
uniform float reflection_strength : hint_range(0.0, 0.5) = 0.14;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.2;
uniform float grain_strength : hint_range(0.0, 0.08) = 0.012;

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

float mask_at(vec2 world) {
	vec2 inner = world / pano_size;
	if (inner.x < 0.0 || inner.x > 1.0 || inner.y < 0.0 || inner.y > 1.0) {
		return 0.0;
	}
	return texture(occluder_map, inner).r;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = texture(screen_texture, uv).rgb;
	vec2 world = uv * viewport_size - pano_offset;

	float ao_radius = 20.0;
	float ao = mask_at(world) * 0.45;
	ao += mask_at(world + vec2(ao_radius, 0.0)) * 0.1375;
	ao += mask_at(world - vec2(ao_radius, 0.0)) * 0.1375;
	ao += mask_at(world + vec2(0.0, ao_radius)) * 0.1375;
	ao += mask_at(world - vec2(0.0, ao_radius)) * 0.1375;
	col *= 1.0 - clamp(ao, 0.0, 1.0) * ao_strength;

	float shadow = 0.0;
	for (int i = 0; i < 1; i++) {
		vec2 lp = light_pos[i];
		float d = distance(world, lp);
		float weight = light_energy[i] * (1.0 - smoothstep(250.0, 2300.0, d));
		if (weight <= 0.001) {
			continue;
		}
		float occ = 0.0;
		for (int j = 1; j <= 8; j++) {
			float t = float(j) / 9.0;
			vec2 p = mix(world, lp, t);
			occ += mask_at(p) * (1.0 - t);
		}
		shadow += clamp(occ / 3.0, 0.0, 1.0) * weight;
	}
	col *= 1.0 - clamp(shadow, 0.0, 1.0) * shadow_strength;

	float dy = uv.y - floor_y;
	if (dy > 0.0) {
		float ripple = (value_noise(vec2(uv.x * 26.0, TIME * 0.25)) - 0.5) * 0.012 * dy;
		vec2 ruv = vec2(uv.x + ripple, floor_y - dy * 0.9);
		ruv.y = clamp(ruv.y, 0.0, 1.0);
		vec3 refl = vec3(0.0);
		refl += texture(screen_texture, ruv + vec2(-0.0015, 0.0)).rgb;
		refl += texture(screen_texture, ruv).rgb;
		refl += texture(screen_texture, ruv + vec2(0.0015, 0.0)).rgb;
		refl /= 3.0;
		float fade = smoothstep(0.4, 0.0, dy) * reflection_strength;
		col = mix(col, refl * 0.92, fade);
	}

	float aspect = 1.7778;
	vec2 vd = (uv - vec2(0.5)) * vec2(aspect, 1.0);
	float vig = smoothstep(0.5, 1.25, length(vd)) * vignette_strength;
	col *= 1.0 - vig;

	float grain = (hash12(uv * vec2(1920.0, 1080.0) + fract(TIME) * 71.0) - 0.5) * grain_strength;
	col += grain;

	COLOR = vec4(col, 1.0);
}

shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform vec3 water_color : source_color = vec3(0.10, 0.13, 0.12);
uniform float clarity : hint_range(0.0, 1.0) = 0.6;
uniform float roughness : hint_range(0.0, 1.0) = 0.06;

group_uniforms ripples;
uniform float ripple_scale = 1.5;
uniform float ripple_speed = 0.15;
uniform float ripple_strength : hint_range(0.0, 2.0) = 0.35;

group_uniforms rings;
uniform float ring_strength : hint_range(0.0, 2.0) = 0.6;
uniform float ring_frequency = 18.0;
uniform float ring_speed = 6.0;
uniform float ring_radius = 1.2;
group_uniforms;

uniform vec3 player_pos = vec3(0.0, -1000.0, 0.0);
uniform float player_moving = 0.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float height(vec2 p, float water_y) {
	float t = TIME * ripple_speed;
	float h = noise(p * ripple_scale + vec2(t, t * 0.6));
	h += noise(p * ripple_scale * 1.7 - vec2(t * 0.8, -t * 0.5)) * 0.6;
	h *= ripple_strength;

	float r = length(p - player_pos.xz);
	float near = 1.0 - smoothstep(0.0, ring_radius, r);
	float same_level = 1.0 - smoothstep(1.0, 2.0, abs(player_pos.y - water_y));
	h += sin(r * ring_frequency - TIME * ring_speed) * near * same_level * player_moving * ring_strength * 0.3;
	return h;
}

void fragment() {
	vec2 p = world_pos.xz;
	float e = 0.02;
	float h = height(p, world_pos.y);
	float gx = (height(p + vec2(e, 0.0), world_pos.y) - h) / e;
	float gz = (height(p + vec2(0.0, e), world_pos.y) - h) / e;
	vec3 n = normalize(vec3(-gx * 0.1, 1.0, -gz * 0.1));

	ALBEDO = water_color;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = 0.5;
	ALPHA = 1.0 - clarity;
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
}

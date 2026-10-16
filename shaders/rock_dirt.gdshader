shader_type spatial;

group_uniforms rock;
uniform sampler2D rock_albedo : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D rock_roughness : hint_default_white, filter_nearest_mipmap, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_nearest_mipmap, repeat_enable;
uniform float rock_scale = 0.5;

group_uniforms dirt;
uniform sampler2D dirt_albedo : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D dirt_roughness : hint_default_white, filter_nearest_mipmap, repeat_enable;
uniform sampler2D dirt_normal : hint_normal, filter_nearest_mipmap, repeat_enable;
uniform float dirt_scale = 0.5;

group_uniforms blend;
uniform float mask_threshold : hint_range(0.0, 1.0) = 0.7;
uniform float mask_softness : hint_range(0.01, 1.0) = 0.3;
uniform float floor_slope : hint_range(0.0, 1.0) = 0.6;
uniform float edge_noise : hint_range(0.0, 1.0) = 0.3;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;
uniform float axis_sharpness = 4.0;
group_uniforms;

varying vec3 world_pos;
varying vec3 world_nrm;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec3 axis_weights(vec3 n) {
	vec3 w = pow(abs(n), vec3(axis_sharpness));
	return w / (w.x + w.y + w.z);
}

vec4 tri_sample(sampler2D tex, vec3 p, vec3 w) {
	return texture(tex, p.zy) * w.x
		 + texture(tex, p.xz) * w.y
		 + texture(tex, p.xy) * w.z;
}

vec3 unpack_normal(vec4 t) {
	vec2 xy = t.xy * 2.0 - 1.0;
	return vec3(xy, sqrt(max(0.0, 1.0 - dot(xy, xy))));
}

vec3 tri_normal(sampler2D tex, vec3 p, vec3 n, vec3 w) {
	vec3 tx = unpack_normal(texture(tex, p.zy));
	vec3 ty = unpack_normal(texture(tex, p.xz));
	vec3 tz = unpack_normal(texture(tex, p.xy));
	tx = vec3(tx.xy + n.zy, abs(tx.z) * n.x);
	ty = vec3(ty.xy + n.xz, abs(ty.z) * n.y);
	tz = vec3(tz.xy + n.xy, abs(tz.z) * n.z);
	return normalize(tx.zyx * w.x + ty.xzy * w.y + tz.xyz * w.z);
}

void fragment() {
	vec3 n = normalize(world_nrm);
	vec3 w = axis_weights(n);
	vec3 p_rock = world_pos * rock_scale;
	vec3 p_dirt = world_pos * dirt_scale;

	vec3 rock_col = tri_sample(rock_albedo, p_rock, w).rgb;
	vec3 dirt_col = tri_sample(dirt_albedo, p_dirt, w).rgb;
	float rock_rough = tri_sample(rock_roughness, p_rock, w).r;
	float dirt_rough = tri_sample(dirt_roughness, p_dirt, w).r;

	float dirt = 1.0 - COLOR.r;
	dirt += (rock_rough - 0.5) * edge_noise;
	dirt = smoothstep(mask_threshold - mask_softness * 0.5, mask_threshold + mask_softness * 0.5, dirt);
	dirt *= smoothstep(floor_slope - 0.15, floor_slope + 0.15, n.y);

	ALBEDO = mix(rock_col, dirt_col, dirt);
	ROUGHNESS = mix(rock_rough, dirt_rough, dirt);

	vec3 nrm = normalize(mix(tri_normal(rock_normal, p_rock, n, w),
	                         tri_normal(dirt_normal, p_dirt, n, w), dirt));
	nrm = normalize(mix(n, nrm, normal_strength));
	NORMAL = normalize((VIEW_MATRIX * vec4(nrm, 0.0)).xyz);
}

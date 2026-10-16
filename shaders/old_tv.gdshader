shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

group_uniforms noise;
uniform float grain : hint_range(0.0, 0.5) = 0.04;

group_uniforms lines;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.06;
uniform float scanline_count = 240.0;
uniform float wobble : hint_range(0.0, 0.01) = 0.0004;

group_uniforms band;
uniform float band_strength : hint_range(0.0, 1.0) = 0.06;
uniform float band_width : hint_range(0.01, 0.5) = 0.06;
uniform float band_speed = 0.05;
uniform float band_shift : hint_range(0.0, 0.05) = 0.002;

group_uniforms look;
uniform float desaturate : hint_range(0.0, 1.0) = 0.35;
uniform float vignette : hint_range(0.0, 1.0) = 0.3;

group_uniforms glitch;
uniform float glitch_strength : hint_range(0.0, 0.1) = 0.015;
uniform float glitch_interval = 9.0;
uniform float glitch_length = 0.15;
group_uniforms;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float frame = floor(TIME * 24.0);

	float band_pos = fract(TIME * band_speed);
	float dist = abs(uv.y - band_pos);
	dist = min(dist, 1.0 - dist);
	float band = smoothstep(band_width, 0.0, dist);

	uv.x += sin(uv.y * 120.0 + TIME * 3.0) * wobble;

	float row_noise = hash(vec2(floor(uv.y * 200.0), frame)) - 0.5;
	uv.x += band * band_shift * row_noise * 2.0;

	float slot = floor(TIME / glitch_interval);
	float start = hash(vec2(slot, 7.0)) * max(glitch_interval - glitch_length, 0.0);
	float t = TIME - slot * glitch_interval;
	float glitch = step(start, t) * step(t, start + glitch_length);
	uv.x += glitch * glitch_strength * (hash(vec2(floor(uv.y * 24.0), frame)) - 0.5) * 2.0;

	vec3 col = texture(screen_tex, uv).rgb;

	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(lum), desaturate);

	float sl = 0.5 + 0.5 * sin(SCREEN_UV.y * scanline_count * PI);
	col *= 1.0 - scanline_strength * sl;

	float n = hash(SCREEN_UV * vec2(1931.0, 1373.0) + mod(frame, 97.0) * 1.37);
	col += (n - 0.5) * grain;
	col += band * band_strength * n;

	vec2 c = SCREEN_UV - 0.5;
	col *= 1.0 - vignette * dot(c, c) * 2.0;

	COLOR = vec4(col, 1.0);
}

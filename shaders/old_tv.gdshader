shader_type canvas_item;

// Старый телевизор / VHS поверх всего экрана.
// Шейдер берёт готовую картинку с камеры (screen_tex) и портит её:
// дрожание строк, бегущая полоса, редкие рывки, выцветание, строки развёртки, шум, затемнение краёв.
// Стоит на ColorRect во всё окно в player.tscn (слой TVLayer, ниже текста).
// Любой эффект выключается нулём.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

group_uniforms noise;
uniform float grain : hint_range(0.0, 0.5) = 0.04;                // зерно («снег»)

group_uniforms lines;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.06;    // тёмные строки развёртки
uniform float scanline_count = 240.0;                              // сколько строк на высоту экрана
uniform float wobble : hint_range(0.0, 0.01) = 0.0004;            // волна по горизонтали

group_uniforms band;
uniform float band_strength : hint_range(0.0, 1.0) = 0.06;        // яркость бегущей полосы
uniform float band_width : hint_range(0.01, 0.5) = 0.06;          // толщина полосы (доля экрана)
uniform float band_speed = 0.05;                                   // скорость: экранов в секунду
uniform float band_shift : hint_range(0.0, 0.05) = 0.002;         // сдвиг картинки внутри полосы

group_uniforms look;
uniform float desaturate : hint_range(0.0, 1.0) = 0.35;           // 0 — цвет, 1 — чёрно-белое
uniform float vignette : hint_range(0.0, 1.0) = 0.3;              // затемнение по краям

group_uniforms glitch;
uniform float glitch_strength : hint_range(0.0, 0.1) = 0.015;     // сила рывка
uniform float glitch_interval = 9.0;                               // рывок примерно раз в столько секунд
uniform float glitch_length = 0.15;                                // сколько длится рывок, секунд
group_uniforms;


// Псевдослучайное число 0..1 из двух чисел. Одинаковый вход — одинаковый результат.
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}


void fragment() {
	vec2 uv = SCREEN_UV;                       // 0..1 по экрану, y = 0 вверху
	float frame = floor(TIME * 24.0);          // «кадр плёнки», 24 в секунду

	// Бегущая полоса: позиция ползёт сверху вниз и начинается заново.
	float band_pos = fract(TIME * band_speed);
	float dist = abs(uv.y - band_pos);
	dist = min(dist, 1.0 - dist);              // чтобы полоса плавно переходила снизу наверх
	float band = smoothstep(band_width, 0.0, dist);

	// Волна: строки чуть гуляют влево-вправо.
	uv.x += sin(uv.y * 120.0 + TIME * 3.0) * wobble;

	// Внутри полосы строки дёргаются вбок.
	float row_noise = hash(vec2(floor(uv.y * 200.0), frame)) - 0.5;
	uv.x += band * band_shift * row_noise * 2.0;

	// Редкий рывок: в каждом отрезке glitch_interval случайный момент, когда всё дёргается.
	float slot = floor(TIME / glitch_interval);
	float start = hash(vec2(slot, 7.0)) * max(glitch_interval - glitch_length, 0.0);
	float t = TIME - slot * glitch_interval;
	float glitch = step(start, t) * step(t, start + glitch_length);
	uv.x += glitch * glitch_strength * (hash(vec2(floor(uv.y * 24.0), frame)) - 0.5) * 2.0;

	vec3 col = texture(screen_tex, uv).rgb;

	// Выцветание: смешиваем с яркостью (чёрно-белой версией).
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(lum), desaturate);

	// Строки развёртки.
	float sl = 0.5 + 0.5 * sin(SCREEN_UV.y * scanline_count * PI);
	col *= 1.0 - scanline_strength * sl;

	// Шум и бегущая полоса.
	float n = hash(SCREEN_UV * vec2(1931.0, 1373.0) + mod(frame, 97.0) * 1.37);
	col += (n - 0.5) * grain;
	col += band * band_strength * n;

	// Затемнение краёв: в углах темнее.
	vec2 c = SCREEN_UV - 0.5;
	col *= 1.0 - vignette * dot(c, c) * 2.0;

	COLOR = vec4(col, 1.0);
}

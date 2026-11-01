shader_type spatial;
// Köy zemini: hücre renk dokusu (4 px/hücre) + gürültü dokusu + kilitli alan karartması + ızgara.
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D cells : filter_linear, repeat_disable;
uniform vec2 origin = vec2(-12.0, -12.0);
uniform vec2 extent = vec2(56.0, 46.0);
uniform vec2 grid_size = vec2(32.0, 22.0);
uniform vec4 open_rect = vec4(9.0, 6.0, 14.0, 10.0);
uniform float grid_alpha = 0.0;
uniform float drought = 0.0;
uniform int road_level = 1;
uniform float dim = 0.0;  // yangın riski haritası açıkken zemin solar, renkli çerçeveler öne çıkar

varying vec3 wpos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 w = wpos.xz;
	vec4 c = texture(cells, (w - origin) / extent);
	float n = vnoise(w * 1.3) * 0.55 + vnoise(w * 5.0) * 0.3 + vnoise(w * 17.0) * 0.15;
	vec3 col = c.rgb * (0.84 + 0.3 * n);
	// kuru ot lekeleri (kuraklıkla artar), yol dışında (alfa = yol maskesi)
	float dry = smoothstep(0.55 - drought * 0.3, 0.75 - drought * 0.3, vnoise(w * 0.6 + 7.0));
	col = mix(col, col * vec3(1.18, 1.02, 0.72), dry * (1.0 - c.a) * 0.7);
	// yol 2: arnavut kaldırımı derzleri; yol 1: tekerlek izleri
	if (road_level == 1) {
		col *= 1.0 - c.a * 0.12 * smoothstep(0.6, 0.9, vnoise(w * vec2(9.0, 9.0)));
	}
	if (road_level == 2 && c.a > 0.6) {
		vec2 g = fract(w * vec2(4.0, 4.0) + vec2(step(0.5, fract(w.y * 2.0)) * 0.5, 0.0));
		float joint = 1.0 - smoothstep(0.0, 0.08, min(min(g.x, 1.0 - g.x), min(g.y, 1.0 - g.y)));
		col *= 1.0 - joint * 0.35;
	}
	// kilitli alan: ızgara içinde ama açık alan dışında → karart, soldur
	vec2 lo = open_rect.xy;
	vec2 hi = open_rect.xy + open_rect.zw;
	float in_open = step(lo.x, w.x) * step(w.x, hi.x) * step(lo.y, w.y) * step(w.y, hi.y);
	float in_grid = step(0.0, w.x) * step(w.x, grid_size.x) * step(0.0, w.y) * step(w.y, grid_size.y);
	float locked = in_grid * (1.0 - in_open);
	float lum = dot(col, vec3(0.3, 0.59, 0.11));
	col = mix(col, vec3(lum) * vec3(0.55, 0.58, 0.52), locked * 0.4);
	// açık alan sınırı
	vec2 dlo = abs(w - lo);
	vec2 dhi = abs(w - hi);
	float edge = min(min(dlo.x, dhi.x), min(dlo.y, dhi.y));
	float border = (1.0 - smoothstep(0.03, 0.08, edge)) * step(lo.x - 0.1, w.x) * step(w.x, hi.x + 0.1) * step(lo.y - 0.1, w.y) * step(w.y, hi.y + 0.1);
	col = mix(col, vec3(1.0, 0.93, 0.7), border * 0.8);
	// inşa ızgarası
	if (grid_alpha > 0.0) {
		vec2 f = fract(w);
		float line = 1.0 - smoothstep(0.0, 0.04, min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)));
		col = mix(col, vec3(1.0, 1.0, 0.9), line * grid_alpha * in_open);
	}
	float grey = dot(col, vec3(0.3, 0.59, 0.11));
	col = mix(col, vec3(grey) * 0.6, dim);
	ALBEDO = col;
	ROUGHNESS = 1.0;
}

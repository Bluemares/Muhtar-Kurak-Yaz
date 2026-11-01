shader_type spatial;
// Bina altı seçim/üzerine gelme çerçevesi: yuvarlak köşeli parlayan kenar.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.85, 0.3, 1.0);
uniform vec2 size = vec2(1.0, 1.0);

void fragment() {
	vec2 p = (UV - 0.5) * size;
	vec2 h = size * 0.5 - 0.06;
	vec2 q = abs(p) - h + 0.12;
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - 0.12;
	float ring = 1.0 - smoothstep(0.0, 0.05, abs(d));
	float fill = (1.0 - step(0.0, d)) * 0.12;
	float pulse = 0.75 + 0.25 * sin(TIME * 5.0);
	ALBEDO = color.rgb;
	ALPHA = (ring * pulse + fill) * color.a;
}

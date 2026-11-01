shader_type spatial;
// Akdeniz: kıyıda turkuaz sığlık + köpük çizgisi, açıkta koyu lacivert, dünya konumuyla dalgacıklar.
render_mode blend_mix, depth_draw_opaque, specular_schlick_ggx;

uniform float shore_z = 38.0;

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
	float d = wpos.z - shore_z;
	float n = vnoise(wpos.xz * 0.6 + vec2(TIME * 0.15, TIME * 0.1)) * 0.6 + vnoise(wpos.xz * 2.2 - vec2(TIME * 0.3, 0.0)) * 0.4;
	vec3 shallow = vec3(0.25, 0.72, 0.74);
	vec3 deep = vec3(0.04, 0.22, 0.42);
	vec3 col = mix(shallow, deep, smoothstep(0.0, 14.0, d + n * 2.0));
	float foam = (1.0 - smoothstep(0.0, 0.7, d - 0.25 * sin(wpos.x * 0.8 + TIME * 1.5) - n * 0.4));
	col = mix(col, vec3(0.95, 0.97, 0.96), foam * 0.8);
	ALBEDO = col;
	ROUGHNESS = 0.08 + n * 0.12;
	SPECULAR = 0.7;
	ALPHA = mix(0.75, 0.97, smoothstep(0.0, 6.0, d));
}

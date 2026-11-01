shader_type spatial;
// Nehir suyu: akan dalgacıklar, kıyıda köpük, güneş parıltısı. UV.x = 0..1 kıyıdan kıyıya, UV.y = akış yönü.
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec3 deep = vec3(0.12, 0.42, 0.62);
uniform vec3 shallow = vec3(0.3, 0.68, 0.72);
uniform float murk = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float across = abs(UV.x - 0.5) * 2.0;
	vec2 p = vec2(UV.x * 3.0, UV.y - TIME * 0.6);
	float n = vnoise(p * vec2(2.0, 1.2)) * 0.6 + vnoise(p * vec2(6.0, 3.0) + 3.0) * 0.4;
	vec3 col = mix(deep, shallow, across * 0.8 + n * 0.25);
	col = mix(col, vec3(0.5, 0.5, 0.42), murk);
	float foam = smoothstep(0.82, 0.97, across + n * 0.12);
	col = mix(col, vec3(0.92, 0.96, 0.95), foam * 0.75);
	ALBEDO = col;
	ROUGHNESS = 0.12 + n * 0.1;
	SPECULAR = 0.6;
	ALPHA = mix(0.88, 0.55, across);
}
